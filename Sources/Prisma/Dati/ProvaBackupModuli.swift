import Foundation

// «Compila da solo» («Luce» giro 10, §7.2.5 punto 7) dentro `Prisma --prova-backup`: la cartella Moduli/ (i PDF dei
// modelli e moduli.json) torna uguale da backup e ripristino; luogo di nascita e IBAN del cliente, il modulo compilato
// nei Documenti (CompilazioneModulo) e l'interruttore «Conserva l'IBAN» tornano dall'archivio; un elenco con un modello
// rovinato o un dato sconosciuto si legge senza perdere il resto; un archivio di prima, senza i campi nuovi, si apre con
// tutto vuoto e l'interruttore spento; un IBAN non valido salvato a mano si scarta alla lettura.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaModuli(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("ModuliLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        // L'archivio con i campi nuovi
        var archivio = DatiPrisma.demo()
        let iban = "IT60X0542811101000000123456"
        archivio.impostazioni.pratiche.conservaIban = true
        guard let i = archivio.clienti.firstIndex(where: { $0.id == "giulia" }) else { return "moduli: manca Giulia nei dati di prova" }
        archivio.clienti[i].iban = iban
        archivio.clienti[i].luogoNascita = "Bologna (BO)"
        var doc = Documento(clienteId: "giulia", titolo: "Modulo · Proposta di polizza", tipo: .modulo)
        doc.id = "doc-modulo-backup"
        doc.importatoIl = Date(timeIntervalSinceReferenceDate: 800_000_000)
        doc.modulo = CompilazioneModulo(modelloId: "modulo-backup", titoloModello: "Proposta di polizza",
                                        compilatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000), mancanti: [.iban, .cap],
                                        firme: 2, firmeRaccolte: false, correzioni: 1)
        archivio.documenti.append(doc)
        try Archivio.salva(archivio, in: dati)

        // La cartella Moduli/: il fac-simile di Prisma e un modello con due campi
        guard let pdf = FacSimileModulo.pdf(FacSimileModulo.proposta) else { return "moduli: il fac-simile non si genera" }
        let campi = [ModelloModulo.Campo(id: "c1", pagina: 0, riquadro: CGRect(x: 46, y: 600, width: 240, height: 24), nomeAcroForm: "cognome",
                                         etichetta: "Cognome", dato: .cognome, tipo: .testo, origine: .acroForm),
                     ModelloModulo.Campo(id: "c2", pagina: 0, riquadro: CGRect(x: 46, y: 300, width: 240, height: 44), etichetta: "Firma",
                                         tipo: .firma, origine: .mano)]
        let m = ModelloModulo(id: "modulo-backup", titolo: "Proposta di polizza", tipo: .propostaPolizza, file: "modulo-backup.pdf",
                              pagine: 1, campi: campi, caricatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000),
                              versione: "fac-simile, ed. di prova", mappaConfermata: true, diProva: true)
        try ArchivioModuli.scrivi([m], in: dati)
        try pdf.write(to: ArchivioModuli.pdf(m, in: dati))

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let modelli = ArchivioModuli.leggi(in: estratto.cartella)
        let pdfTornato = try? Data(contentsOf: ArchivioModuli.pdf(m, in: estratto.cartella))
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard modelli == [m] else { return "moduli: l'elenco dei modelli non torna uguale dal backup" }
        guard pdfTornato == pdf else { return "moduli: il PDF del modello non torna uguale dal backup" }
        guard let g = d.clienti.first(where: { $0.id == "giulia" }), g.iban == iban, g.luogoNascita == "Bologna (BO)" else {
            return "moduli: luogo di nascita o IBAN del cliente non tornano dal backup"
        }
        guard d.documenti.first(where: { $0.id == doc.id }) == doc, d.documenti.first(where: { $0.id == doc.id })?.tipo == .modulo else {
            return "moduli: il modulo compilato nei Documenti non torna uguale dal backup"
        }
        guard d.impostazioni.pratiche.ibanConservato, d.impostazioni.pratiche == archivio.impostazioni.pratiche else {
            return "moduli: l'interruttore «Conserva l'IBAN» non torna dal backup"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        guard ArchivioModuli.leggi(in: ripristinata) == [m], (try? Data(contentsOf: ArchivioModuli.pdf(m, in: ripristinata))) == pdf else {
            return "moduli: la cartella Moduli/ non torna dal ripristino"
        }

        // Lettura tollerante: un modello rovinato si scarta, un dato sconosciuto diventa «da lasciare vuoto»
        let codificatore = ArchivioModuli.codificatore()
        let buono = String(decoding: try codificatore.encode(m), as: UTF8.self)
        let futuro = buono.replacingOccurrences(of: "\"dato\":\"cognome\"", with: "\"dato\":\"datoDelFuturo\"")
        let elenco = "[\(futuro),{\"id\":\"rovinato\"}]"
        let cartella = ArchivioModuli.cartella(in: ripristinata)
        try Data(elenco.utf8).write(to: cartella.appendingPathComponent(ArchivioModuli.nomeElenco))
        let tollerati = ArchivioModuli.leggi(in: ripristinata)
        guard tollerati.count == 1, tollerati[0].campi.count == 2, tollerati[0].campi[0].dato == nil, tollerati[0].campi[0].etichetta == "Cognome" else {
            return "moduli: un elenco con un modello rovinato o un dato sconosciuto non si legge con tolleranza"
        }

        // Un archivio di prima, senza i campi nuovi: tutto vuoto, interruttore spento; un IBAN non valido si scarta
        var cliente = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio.clienti[i])) as? [String: Any] ?? [:]
        cliente["luogoNascita"] = nil
        cliente["iban"] = "IT00X0000000000000000000000"
        let letto = try Archivio.decodificatore.decode(Cliente.self, from: JSONSerialization.data(withJSONObject: cliente))
        guard letto.iban == nil, letto.luogoNascita == nil else { return "moduli: un IBAN non valido nell'archivio non si scarta" }
        var documento = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(doc)) as? [String: Any] ?? [:]
        documento["modulo"] = nil
        documento["tipo"] = "tipoDelFuturo"
        let docLetto = try Archivio.decodificatore.decode(Documento.self, from: JSONSerialization.data(withJSONObject: documento))
        guard docLetto.modulo == nil, docLetto.tipo == .altro else { return "moduli: un documento di prima o di un tipo sconosciuto non si legge" }
        let impostazioni = try Archivio.decodificatore.decode(ImpostazioniPratiche.self, from: Data("{\"giorniFerma\":10}".utf8))
        guard !impostazioni.ibanConservato, impostazioni.giorniFerma == 10 else { return "moduli: impostazioni delle pratiche di prima lette male" }
        return nil
    }
}
