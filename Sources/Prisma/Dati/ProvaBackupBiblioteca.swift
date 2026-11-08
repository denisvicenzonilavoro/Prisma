import Foundation

// Biblioteca · «Trova la pagina» («Luce» giro 6, §8.1.5.2 punto 7) dentro `Prisma --prova-backup`: un documento della
// Biblioteca (PDF, testo pagina per pagina e voce con genere, canale, pagine, prodotto) torna uguale dopo backup e
// ripristino; un indice di prima (solo «Il codice in tasca», senza i campi nuovi) si legge; con «Escludi la Biblioteca»
// il backup non porta la cartella e il ripristino tiene quella del Mac; la Biblioteca non va nell'istantanea di «Prisma
// ovunque». Le impostazioni del backup con l'interruttore tornano dall'archivio.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaBiblioteca(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("BibliotecaLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        let cartella = dati.appendingPathComponent("Biblioteca", isDirectory: true)
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        var archivio = DatiPrisma.demo()
        archivio.impostazioni.backup.escludiBiblioteca = true
        try Archivio.salva(archivio, in: dati)

        // Un documento con il suo PDF (qui pochi byte finti) e il testo accanto
        var d = DocumentoBiblioteca(titolo: "Piano rivalutabile · Condizioni di assicurazione", sigla: "", edizione: "fac-simile, ed. 01/2026",
                                    file: "abcd1234-piano.pdf")
        d.importatoIl = Date(timeIntervalSince1970: 1_790_000_000)
        d.genere = .condizioni
        d.canale = .alleanza
        d.confermato = true
        d.pagine = 2
        d.pagineOCR = 1
        d.dimensione = 12
        d.prodottoId = "prodotto-prova"
        d.testo = "\(d.id).txt"
        let pagine = ["Art. 9 – Riscatto\n\nTrascorso un anno il contraente può chiedere il riscatto.", "Seconda pagina del fac-simile."]
        let testo = pagine.joined(separator: LetturaDocumenti.separatorePagine)
        let pdf = Data("%PDF-finto".utf8)
        try pdf.write(to: cartella.appendingPathComponent(d.file))
        try Data(testo.utf8).write(to: cartella.appendingPathComponent(d.testo ?? ""))
        // Un testo di «Il codice in tasca» di prima, senza i campi nuovi
        let vecchio = #"{"id":"norma-vecchia","titolo":"Codice di prova","sigla":"D.Lgs. 1/2000","edizione":"prova","file":"codice.pdf","importatoIl":"2026-10-01T10:00:00Z","articoli":[{"id":"norma-vecchia-art-1","numero":"1","rubrica":"Oggetto","pagina":3,"testo":"Testo dell'articolo uno."}]}"#
        let codificatore = JSONEncoder()
        codificatore.dateEncodingStrategy = .iso8601
        let nuovo = String(data: try codificatore.encode(d), encoding: .utf8) ?? ""
        try Data("[\(nuovo),\(vecchio)]".utf8).write(to: cartella.appendingPathComponent("biblioteca.json"))

        // Backup con la Biblioteca e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let tornata = estratto.cartella.appendingPathComponent("Biblioteca", isDirectory: true)
        let decodificatore = JSONDecoder()
        decodificatore.dateDecodingStrategy = .iso8601
        let elenco = try? decodificatore.decode([DocumentoBiblioteca].self, from: Data(contentsOf: tornata.appendingPathComponent("biblioteca.json")))
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard let elenco, elenco.count == 2 else { return "biblioteca: l'indice non torna dal backup" }
        guard elenco[0] == d else { return "biblioteca: il documento non torna uguale (genere, canale, pagine, prodotto)" }
        guard elenco[1].genere == nil, elenco[1].genereVisto == .normativa, !elenco[1].daConfermare, elenco[1].numeroPagine == 3,
              elenco[1].articoli.first?.rubrica == "Oggetto" else {
            return "biblioteca: un testo di «Il codice in tasca» di prima non si legge come normativa"
        }
        guard estratto.dati.impostazioni.backup.escludiBiblioteca == true else { return "biblioteca: l'interruttore «Escludi la Biblioteca» non torna" }
        // Ripristino vero in una cartella di prova: PDF e testo uguali
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        guard (try? Data(contentsOf: ripristinata.appendingPathComponent("Biblioteca/\(d.file)"))) == pdf,
              (try? String(contentsOf: ripristinata.appendingPathComponent("Biblioteca/\(d.testo ?? "")"), encoding: .utf8)) == testo else {
            return "biblioteca: PDF e testo non tornano uguali dal ripristino"
        }

        // «Escludi la Biblioteca»: il backup non la porta…
        let senza = try GestoreBackup.crea(sorgente: dati, escludi: GestoreBackup.cartelleEscludibili, destinazione: backup, nota: "senza biblioteca")
        let estrattoSenza = try GestoreBackup.estrai(senza)
        let haBiblioteca = fm.fileExists(atPath: estrattoSenza.cartella.appendingPathComponent("Biblioteca").path)
        let haArchivio = estrattoSenza.dati.clienti.count == archivio.clienti.count
        guard !haBiblioteca, haArchivio else {
            GestoreBackup.pulisciEstrazione(estrattoSenza.cartella)
            return haBiblioteca ? "biblioteca: con «Escludi la Biblioteca» la cartella è nel backup" : "biblioteca: il backup senza Biblioteca ha perso l'archivio"
        }
        // …e il ripristino da quel backup tiene la Biblioteca del Mac (un archivio senza Biblioteca si legge)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: estrattoSenza.cartella)
        guard (try? Data(contentsOf: ripristinata.appendingPathComponent("Biblioteca/\(d.file)"))) == pdf else {
            return "biblioteca: il ripristino da un backup senza Biblioteca ha tolto quella del Mac"
        }
        // La copia senza la Biblioteca non resta nella cartella temporanea
        let avanzi = (try? fm.contentsOfDirectory(at: fm.temporaryDirectory, includingPropertiesForKeys: nil))?
            .filter { $0.lastPathComponent.hasPrefix("Prisma-copia-") } ?? []
        guard avanzi.isEmpty else { return "biblioteca: la copia senza la Biblioteca è rimasta nella cartella temporanea" }
        // L'istantanea di «Prisma ovunque» non porta la Biblioteca (sta fuori dall'archivio)
        let istantanea = try Archivio.codificatore.encode(SpazioOvunque.datiIstantanea(archivio))
        guard istantanea.range(of: Data("Piano rivalutabile".utf8)) == nil else { return "biblioteca: un documento nell'istantanea di Prisma ovunque" }
        return nil
    }
}
