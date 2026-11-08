import Foundation

// Chilometri, spese e scadenze (versione 27, «Luce» giro 9) dentro `Prisma --prova-backup`:
// - spese (con scontrino, IVA, canale, cliente, da controllare), scadenze (ricorrente, fatta, con importo), corsi (con
//   attestato), impostazioni (partenza, km per cliente, correzioni, ore per anno, ente, giorno di cambio, nomi nel
//   pacchetto, valore per km) e il luogo degli appuntamenti (`presso`) tornano uguali dal backup;
// - un archivio senza i campi nuovi si apre con le spese vuote, le impostazioni di base e `presso` non indicato;
// - una spesa senza id, una scadenza senza data, un corso illeggibile si scartano, gli altri restano; valori illeggibili
//   (categoria sconosciuta, km negativi, giorno di cambio fuori scala) diventano quelli di base;
// - i file degli scontrini e degli attestati (`Studio/Scontrini`, `Studio/Attestati` accanto all'archivio) vanno nel
//   backup e tornano con il ripristino.
// VALORI DI PROVA scritti qui per l'andata e il ritorno, mai nell'archivio reale.

extension ProvaBackup {
    static func speseDiProvaBackup() -> ArchivioSpese {
        let d = { (m: Int, g: Int) in AiutiProva.data(2026, m, g) }
        return ArchivioSpese(
            spese: [
                SpesaStudio(id: "spesa-backup-1", data: d(10, 8), descrizione: "Pranzo di lavoro (prova)", esercente: "Trattoria di prova",
                            importo: 48, iva: 4.36, categoria: .pasti, pagamento: "Carta", canale: .indipendente, clienteId: "giulia",
                            scontrino: "abcd1234-scontrino.jpg", letta: true, daControllare: true, nota: "fac-simile"),
                SpesaStudio(id: "spesa-backup-2", data: d(10, 2), descrizione: "Carburante", importo: 92.40, categoria: .carburante),
            ],
            scadenze: [
                ScadenzaStudio(id: "scadenza-backup-1", titolo: "Scadenza mensile di prova", data: d(11, 16), ricorrenza: .mensile,
                               tipo: .fiscale, importo: 120, nota: "come impostato con il commercialista"),
                ScadenzaStudio(id: "scadenza-backup-2", titolo: "Polizza di prova", data: d(12, 31), tipo: .polizza, fattaIl: d(11, 1)),
            ],
            corsi: [
                CorsoAggiornamento(id: "corso-backup-1", titolo: "Corso di prova", ente: "Ente di prova", data: d(3, 12), ore: 14,
                                   attestato: "efgh5678-attestato.pdf", canale: .alleanza),
                CorsoAggiornamento(id: "corso-backup-2", titolo: "Seminario di prova", data: d(6, 20), ore: 8.5),
            ])
    }

    static func impostazioniSpeseDiProvaBackup() -> ImpostazioniSpese {
        var i = ImpostazioniSpese()
        i.partenza = "Studio di prova"
        i.kmAndataRitornoPerCliente = ["giulia": 14, "marco": 41.5]
        i.kmCorretti = ["2026-10-03": 47]
        i.contaVisiteSenzaCliente = true
        i.oreAggiornamentoAnno = [2026: 30, 2027: 32]
        i.enteAggiornamento = "Ente di prova"
        i.giornoCambioMese = 7
        i.nomiNelPacchetto = true
        i.euroPerKm = 0.25
        return i
    }

    static func aggiungiSpeseDiProva(_ d: inout DatiPrisma) {
        d.speseStudio = speseDiProvaBackup()
        d.impostazioni.studio.spese = impostazioniSpeseDiProvaBackup()
        if let i = d.appuntamenti.indices.first { d.appuntamenti[i].presso = .cliente }
        if d.appuntamenti.count > 1 { d.appuntamenti[1].presso = .altro }
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaSpese(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.speseStudio.spese.count == 2, originale.speseStudio.scadenze.count == 2, originale.speseStudio.corsi.count == 2,
              originale.impostazioni.studio.spese.nomiNelPacchetto, originale.appuntamenti.first?.presso == .cliente else {
            return "l'archivio di prova non ha spese, scadenze, corsi, impostazioni delle spese e luogo degli appuntamenti"
        }
        guard estratto.speseStudio == originale.speseStudio else { return "spese, scadenze o corsi non tornano uguali dal backup" }
        guard estratto.impostazioni.studio.spese == originale.impostazioni.studio.spese,
              estratto.impostazioni.studio.spese.oreAggiornamentoAnno[2026] == 30,
              estratto.impostazioni.studio.spese.kmAndataRitornoPerCliente["marco"] == 41.5 else {
            return "le impostazioni dei chilometri e delle spese non tornano uguali dal backup"
        }
        guard estratto.appuntamenti.map(\.presso) == originale.appuntamenti.map(\.presso) else {
            return "il luogo degli appuntamenti (dal cliente, in studio, altrove) non torna uguale dal backup"
        }
        // 2. Un archivio senza i campi nuovi si apre con le spese vuote e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "speseStudio") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              var studio = impostazioni["studio"] as? [String: Any],
              studio.removeValue(forKey: "spese") != nil,
              var appuntamenti = radice["appuntamenti"] as? [[String: Any]] else {
            return "archivio di prova senza le spese non preparato"
        }
        let originaliRadice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] ?? [:]
        impostazioni["studio"] = studio
        radice["impostazioni"] = impostazioni
        for i in appuntamenti.indices { appuntamenti[i].removeValue(forKey: "presso") }
        radice["appuntamenti"] = appuntamenti
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.speseStudio == ArchivioSpese(), letto.impostazioni.studio.spese == ImpostazioniSpese(),
              letto.appuntamenti.allSatisfy({ $0.presso == nil }), letto.appuntamenti.count == atteso.appuntamenti.count,
              letto.impostazioni.studio.aliquote == atteso.impostazioni.studio.aliquote,
              letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni else {
            return "archivio senza le spese non letto correttamente (attese spese vuote, impostazioni di base, il resto uguale)"
        }
        guard ImpostazioniSpese().giornoCambioMese == 10, !ImpostazioniSpese().nomiNelPacchetto, ImpostazioniSpese().euroPerKm == nil,
              ImpostazioniSpese().oreAggiornamentoAnno.isEmpty else {
            return "le impostazioni di base delle spese inventano valori (giorno 10, nomi spenti, nessun €/km, nessuna ora)"
        }
        // 3. Elementi illeggibili si scartano, valori illeggibili tornano quelli di base
        guard var spese = originaliRadice["speseStudio"] as? [String: Any],
              var elencoSpese = spese["spese"] as? [[String: Any]], let prima = elencoSpese.first,
              var scadenze = spese["scadenze"] as? [Any], var corsi = spese["corsi"] as? [Any] else {
            return "spese di prova non codificate"
        }
        var strana = prima
        strana["categoria"] = "categoria di un Prisma più nuovo"
        strana["iva"] = -3
        elencoSpese.append(["descrizione": "Senza id"])
        elencoSpese[0] = strana
        spese["spese"] = elencoSpese
        scadenze.append(["id": "senza-data", "titolo": "Senza data"])
        spese["scadenze"] = scadenze
        corsi.append(7)
        spese["corsi"] = corsi
        var radiceStrana = originaliRadice
        radiceStrana["speseStudio"] = spese
        if var imp = radiceStrana["impostazioni"] as? [String: Any], var st = imp["studio"] as? [String: Any],
           var sp = st["spese"] as? [String: Any] {
            sp["giornoCambioMese"] = 45
            sp["kmAndataRitornoPerCliente"] = ["giulia": -5, "marco": 41.5]
            sp["oreAggiornamentoAnno"] = ["anno": 3, "2026": 30]
            st["spese"] = sp
            imp["studio"] = st
            radiceStrana["impostazioni"] = imp
        }
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radiceStrana))
        guard illeggibile.speseStudio.spese.count == 2, illeggibile.speseStudio.scadenze.count == 2, illeggibile.speseStudio.corsi.count == 2,
              illeggibile.speseStudio.spese.first?.categoria == .altro, illeggibile.speseStudio.spese.first?.iva == nil,
              illeggibile.speseStudio.spese.first?.importo == 48, illeggibile.speseStudio.spese.first?.scontrino == "abcd1234-scontrino.jpg" else {
            return "spese illeggibili: elementi non scartati o campi leggibili persi"
        }
        let sp = illeggibile.impostazioni.studio.spese
        guard sp.giornoCambioMese == 10, sp.kmAndataRitornoPerCliente == ["marco": 41.5], sp.oreAggiornamentoAnno == [2026: 30],
              sp.partenza == "Studio di prova" else {
            return "impostazioni delle spese illeggibili: valori non tornati quelli di base o valori leggibili persi"
        }
        // 4. La versione dell'archivio di Luce
        guard DatiPrisma.versioneAttuale >= 27 else { return "le spese chiedono almeno la versione 27 dell'archivio" }
        return nil
    }

    /// I file degli scontrini e degli attestati vanno nel backup e tornano con il ripristino.
    static func provaFileSpese(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("SpeseLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        var archivio = DatiPrisma.demo()
        archivio.speseStudio = speseDiProvaBackup()
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)
        try Archivio.salva(archivio, in: dati)
        let scontrini = Archivio.cartellaScontrini(in: dati)
        let attestati = Archivio.cartellaAttestati(in: dati)
        let jpg = Data("scontrino finto".utf8)
        let pdf = Data("%PDF-attestato-finto".utf8)
        // Copiati come fa Prisma (nome nuovo che non si ripete)
        let sorgente = base.appendingPathComponent("da-copiare.jpg")
        try jpg.write(to: sorgente)
        let copiato = try Archivio.copiaFileStudio(sorgente, in: scontrini)
        guard copiato.hasSuffix("-da-copiare.jpg"), (try? Data(contentsOf: scontrini.appendingPathComponent(copiato))) == jpg else {
            return "spese: lo scontrino non si copia nella cartella Studio/Scontrini"
        }
        try fm.createDirectory(at: attestati, withIntermediateDirectories: true)
        try jpg.write(to: scontrini.appendingPathComponent("abcd1234-scontrino.jpg"))
        try pdf.write(to: attestati.appendingPathComponent("efgh5678-attestato.pdf"))

        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        guard estratto.dati.speseStudio == archivio.speseStudio else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "spese: le spese non tornano dal backup con i file"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: estratto.cartella)
        guard (try? Data(contentsOf: Archivio.cartellaScontrini(in: ripristinata).appendingPathComponent("abcd1234-scontrino.jpg"))) == jpg,
              (try? Data(contentsOf: Archivio.cartellaScontrini(in: ripristinata).appendingPathComponent(copiato))) == jpg,
              (try? Data(contentsOf: Archivio.cartellaAttestati(in: ripristinata).appendingPathComponent("efgh5678-attestato.pdf"))) == pdf else {
            return "spese: i file degli scontrini e degli attestati non tornano dal backup"
        }
        return nil
    }
}
