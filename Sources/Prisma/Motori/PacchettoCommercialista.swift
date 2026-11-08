import Foundation

// Il pacchetto per il commercialista (Design/template-luce-specifica.md §6.3.5 punto 6, «Luce» giro 9; decisione 14).
// Uno zip con i chilometri e le spese del mese in CSV (separatore «;», decimali con la virgola, UTF-8 con BOM per Excel),
// il riepilogo in PDF su carta bianca e la cartella `scontrini/` con i file. Si crea fuori dal thread principale, nel posto
// scelto dall'utente con il pannello del Mac: Prisma non lo invia a nessuno.
// - Nessun nome di cliente con `nomiNelPacchetto` spento (di base): dei giri solo data, km e numero di visite; delle spese
//   il cliente legato non compare (descrizione e nota sono parole dell'utente).
// - Solo fatti: niente deducibilità, niente IVA detraibile; il valore per km solo se l'utente l'ha scritto.

enum PacchettoCommercialista {
    /// Il contenuto del pacchetto, preparato sul thread principale (testi e PDF), scritto poi altrove.
    struct Contenuto {
        /// «Ottobre-2026»: il nome della cartella nello zip e dello zip.
        let nome: String
        /// «2026-10».
        let suffisso: String
        let csvChilometri: String
        let csvSpese: String
        let pdf: Data?
        /// I file degli scontrini: (url sul Mac, nome nello zip).
        let scontrini: [(url: URL, nome: String)]
    }

    enum Errore: LocalizedError {
        case scrittura(String)
        var errorDescription: String? {
            switch self {
            case .scrittura(let m): return m
            }
        }
    }

    // MARK: Nomi

    private static let formatoMese = Formati.formato("MMMM")

    /// «Ottobre-2026».
    static func nome(mese: Date, calendario cal: Calendar = .current) -> String {
        let m = formatoMese.string(from: mese)
        return m.prefix(1).uppercased() + m.dropFirst() + "-" + String(cal.component(.year, from: mese))
    }

    /// «2026-10».
    static func suffisso(mese: Date, calendario cal: Calendar = .current) -> String {
        let c = cal.dateComponents([.year, .month], from: mese)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    // MARK: CSV

    /// Il BOM che fa aprire a Excel il file in UTF-8.
    static let bom = "\u{FEFF}"
    private static let formatoData = Formati.formato("dd/MM/yyyy")

    /// Un campo CSV: tra virgolette se contiene «;», virgolette o un a capo. Un testo che comincia con «=», «+», «-», «@»
    /// o un tabulatore (per esempio un esercente letto male dallo scontrino) prende davanti un apostrofo: Excel non lo
    /// esegue come formula. I numeri del pacchetto restano come sono.
    static func campo(_ s: String) -> String {
        var t = s
        if let primo = t.unicodeScalars.first, "=+-@\t\r".unicodeScalars.contains(primo),
           t.range(of: #"^-?\d+(,\d+)?$"#, options: .regularExpression) == nil {
            t = "'" + t
        }
        guard t.contains(";") || t.contains("\"") || t.contains("\n") || t.contains("\r") else { return t }
        return "\"" + t.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Un numero con la virgola dei decimali e senza separatore delle migliaia: «28», «92,40».
    static func numero(_ v: Double, decimali: Int) -> String {
        String(format: "%.\(decimali)f", v).replacingOccurrences(of: ".", with: ",")
    }

    private static func riga(_ campi: [String]) -> String { campi.map(campo).joined(separator: ";") }

    /// I chilometri del mese: un giro per riga. I nomi dei clienti solo con `nomi` acceso.
    static func csvChilometri(_ giri: [MotoreChilometri.Giro], nomi: [String: String]?, euroPerKm: Double?) -> String {
        var intestazione = ["Data", "Visite", "Km", "Origine dei km"]
        if euroPerKm != nil { intestazione.append("Valore per km scritto da te (€)") }
        if nomi != nil { intestazione.append("Clienti") }
        var righe = [riga(intestazione)]
        for g in giri {
            // Un giro da completare porta i km noti (come il PDF, che li somma con «almeno»), vuoto se non ne ha
            let km: Double? = g.km ?? (g.kmNoti > 0 ? g.kmNoti : nil)
            var campi = [formatoData.string(from: g.giorno), String(g.visite.count),
                         km.map { numero($0, decimali: 1) } ?? "",
                         g.corretto ? "corretto a mano"
                             : (g.km == nil ? (km == nil ? "da completare" : "da completare: solo i km noti")
                                            : "km andata e ritorno per cliente")]
            if let e = euroPerKm { campi.append(km.map { numero(MotoreChilometri.euro($0, perKm: e), decimali: 2) } ?? "") }
            if let nomi {
                campi.append(g.visite.map { nomi[$0.clienteId] ?? "" }.filter { !$0.isEmpty }.joined(separator: " · "))
            }
            righe.append(riga(campi))
        }
        return bom + righe.joined(separator: "\r\n") + "\r\n"
    }

    /// Le spese del mese: una per riga, con il nome del file dello scontrino nella cartella `scontrini/`.
    static func csvSpese(_ spese: [SpesaStudio], scontrini: [String: String], nomi: [String: String]?) -> String {
        var intestazione = ["Data", "Descrizione", "Esercente", "Categoria", "Canale", "Importo (€)", "IVA indicata (€)",
                            "Pagamento", "Scontrino", "Nota"]
        if nomi != nil { intestazione.append("Cliente") }
        var righe = [riga(intestazione)]
        for s in spese {
            var campi = [formatoData.string(from: s.data), s.descrizione, s.esercente ?? "", s.categoria.nome,
                         s.canale?.nomeBreve ?? "", numero(s.importo, decimali: 2), s.iva.map { numero($0, decimali: 2) } ?? "",
                         s.pagamento ?? "", scontrini[s.id] ?? "", s.nota]
            if let nomi { campi.append(s.clienteId.flatMap { nomi[$0] } ?? "") }
            righe.append(riga(campi))
        }
        return bom + righe.joined(separator: "\r\n") + "\r\n"
    }

    /// I file degli scontrini delle spese che esistono sul Mac, con il nome nello zip «2026-10-02 Carburante.jpg» (senza
    /// nomi di clienti; un numero se due si chiamerebbero uguali). Restituisce anche spesa → nome per il CSV.
    static func scontrini(_ spese: [SpesaStudio], cartella: URL) -> (file: [(url: URL, nome: String)], perSpesa: [String: String]) {
        let fm = FileManager.default
        let formato = Formati.formato("yyyy-MM-dd")
        var file: [(url: URL, nome: String)] = []
        var perSpesa: [String: String] = [:]
        var usati: Set<String> = []
        for s in spese {
            guard let n = s.scontrino else { continue }
            let url = cartella.appendingPathComponent(n)
            guard fm.fileExists(atPath: url.path) else { continue }
            let est = url.pathExtension.isEmpty ? "" : "." + url.pathExtension.lowercased()
            let base = "\(formato.string(from: s.data)) \(s.categoria.nome)"
                .replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
            var nome = base + est
            var i = 2
            while usati.contains(nome) {
                nome = "\(base) \(i)\(est)"
                i += 1
            }
            usati.insert(nome)
            file.append((url, nome))
            perSpesa[s.id] = nome
        }
        return (file, perSpesa)
    }

    // MARK: Scrittura

    /// Scrive lo zip in `destinazione` (fuori dal thread principale): i file uno per volta in una cartella temporanea
    /// (`avanzamento(fatti, totale)` dopo ognuno), poi lo zip, poi lo spostamento al posto scelto. Niente a metà: un errore
    /// toglie i file temporanei e lascia com'era la destinazione.
    static func scrivi(_ c: Contenuto, in destinazione: URL, avanzamento: (Int, Int) -> Void) throws {
        let fm = FileManager.default
        let lavoro = fm.temporaryDirectory.appendingPathComponent("Prisma-pacchetto-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: lavoro) }
        let cartella = lavoro.appendingPathComponent(c.nome, isDirectory: true)
        let totale = 2 + (c.pdf == nil ? 0 : 1) + c.scontrini.count + 1
        var fatti = 0
        func passo() {
            fatti += 1
            avanzamento(fatti, totale)
        }
        do {
            try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
            try Data(c.csvChilometri.utf8).write(to: cartella.appendingPathComponent("chilometri-\(c.suffisso).csv"))
            passo()
            try Data(c.csvSpese.utf8).write(to: cartella.appendingPathComponent("spese-\(c.suffisso).csv"))
            passo()
            if let pdf = c.pdf {
                try pdf.write(to: cartella.appendingPathComponent("riepilogo-\(c.suffisso).pdf"))
                passo()
            }
            if !c.scontrini.isEmpty {
                let s = cartella.appendingPathComponent("scontrini", isDirectory: true)
                try fm.createDirectory(at: s, withIntermediateDirectories: true)
                for f in c.scontrini {
                    try fm.copyItem(at: f.url, to: s.appendingPathComponent(f.nome))
                    passo()
                }
            }
            let zip = lavoro.appendingPathComponent(c.nome + ".zip")
            try ScrittoreZip.crea(da: cartella, a: zip)
            if fm.fileExists(atPath: destinazione.path) {
                _ = try fm.replaceItemAt(destinazione, withItemAt: zip)
            } else {
                try fm.moveItem(at: zip, to: destinazione)
            }
            passo()
        } catch {
            throw Errore.scrittura(error.localizedDescription)
        }
    }

    /// «chilometri, spese e 6 scontrini, in CSV e PDF».
    static func descrizione(scontrini: Int, pdf: Bool) -> String {
        let s = scontrini == 0 ? "chilometri e spese" : scontrini == 1 ? "chilometri, spese e 1 scontrino"
            : "chilometri, spese e \(scontrini) scontrini"
        return s + (pdf ? ", in CSV e PDF" : ", in CSV")
    }
}
