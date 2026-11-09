import Foundation

// Le cose date al cliente («Luce» giro 15) dentro `Prisma --prova-backup`: capsule del tempo, sinistri, traccia delle
// uscite, stato del Prisma del cliente, consenso a WhatsApp e impostazioni nuove della Sala vanno e tornano da backup e
// ripristino; capsule e uscite stanno nel file del cliente, i sinistri in `pratiche.json`, niente nell'indice; un archivio
// di prima, senza le chiavi, si apre con gli elenchi vuoti; un elemento rovinato si scarta e gli altri restano; un cliente
// tolto porta via i suoi. Tutti dati di prova dichiarati, date al secondo (come le scrive l'archivio).

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaGiro15(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("CoseDateAlCliente", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        // Il posto di ogni chiave nuova
        guard ArchivioPezzi.pezzo(.capsule) == .cliente, ArchivioPezzi.pezzo(.uscite) == .cliente,
              ArchivioPezzi.pezzo(.sinistri) == .sezione("pratiche") else {
            return "giro 15: capsule e uscite non stanno nel file del cliente o i sinistri non stanno nelle pratiche"
        }

        // L'archivio con i campi nuovi (dati di prova dichiarati)
        var archivio = DatiPrisma.demo()
        guard let i = archivio.clienti.firstIndex(where: { $0.id == "giulia" }) else { return "giro 15: manca Giulia nei dati di prova" }
        let t0 = Date(timeIntervalSinceReferenceDate: 815_003_417)
        func ora(_ giorni: Int) -> Date { t0.addingTimeInterval(TimeInterval(giorni) * 86_400) }
        archivio.clienti[i].prismaCliente = StatoPrismaCliente(ultimoFile: ora(1), validoFinoAl: ora(366), contenuti: ["lettera", "obiettivi"],
                                                               aggiunteDopoUltimoFile: ["film"], filmImpronta: "impronta-prova-7c1e",
                                                               filmEsportatoIl: ora(2))
        archivio.clienti[i].consensi.whatsapp = true
        archivio.clienti[i].consensi.dataWhatsapp = ora(3)
        archivio.impostazioni.sala.avvertenzaFile = "Avvertenza del file di prova"
        archivio.impostazioni.sala.avvertenzaFilm = "Avvertenza del film di prova"
        archivio.impostazioni.sala.htmlSperimentale = true
        let capsule = [
            CapsulaTempo(id: "capsula-prova-g15a", clienteId: "giulia", apertura: .data(ora(800)), sigillataIl: ora(4),
                         sigillo: Data([0x51, 0x07, 0xA3, 0x2C, 0x90]), chiaveId: "chiave-prova-1"),
            CapsulaTempo(id: "capsula-prova-g15b", clienteId: "giulia", apertura: .obiettivo(id: "obiettivo-prova-g15"),
                         titoloObiettivo: "Anticipo casa", sigillataIl: ora(5), sigillo: Data([0x0E, 0x61]), chiaveId: "chiave-prova-1",
                         stato: .aperta, apertaIl: ora(6), diProva: true),
        ]
        let uscite = [
            UscitaCliente(id: "uscita-prova-g15a", clienteId: "giulia", genere: .prismaCliente, quando: ora(7),
                          descrizione: "PDF protetto · obiettivi, lettera", via: "Messaggi", documentoId: "doc-prova-g15", protetto: true),
            UscitaCliente(id: "uscita-prova-g15b", clienteId: "giulia", genere: .biglietto, quando: ora(8),
                          descrizione: "Biglietto", via: nil, documentoId: nil, protetto: false),
        ]
        var sinistro = Sinistro(id: "sinistro-prova-g15", clienteId: "giulia", titolo: "Furto di prova", apertoIl: ora(9))
        sinistro.descrizione = "Descrizione breve di prova"
        sinistro.accadutoIl = ora(8)
        sinistro.numeroSinistro = "SIN-PROVA-g15"
        sinistro.fase = .perizia
        sinistro.eventi = [EventoSinistro(id: "ev-g15-1", data: ora(9), testo: "Denuncia fatta", fase: .denuncia),
                           EventoSinistro(id: "ev-g15-2", data: ora(12), testo: "Perito incaricato", fase: .perizia)]
        sinistro.documenti = [DocumentoSinistro(id: "doc-g15-1", titolo: "Denuncia", ricevutoIl: ora(10), documentoId: nil),
                              DocumentoSinistro(id: "doc-g15-2", titolo: "Fattura della bicicletta", ricevutoIl: nil, documentoId: nil)]
        sinistro.stimaMinima = 1_137
        sinistro.stimaMassima = 1_793
        sinistro.mostraAlCliente = true
        sinistro.ultimoAggiornamentoCliente = ora(13)
        archivio.capsule = capsule
        archivio.uscite = uscite
        archivio.sinistri = [sinistro]
        try Archivio.salva(archivio, in: dati)

        // Il posto su disco: capsule e uscite nel file di Giulia, i sinistri in pratiche.json, niente nell'indice
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        func leggi(_ url: URL) -> String { (try? String(contentsOf: url, encoding: .utf8)) ?? "" }
        let fileGiulia = leggi(pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)
            .appendingPathComponent(ArchivioPezzi.nomeFile(cliente: "giulia")))
        let pratiche = leggi(pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione("pratiche")))
        let indice = leggi(pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice))
        guard fileGiulia.contains("capsula-prova-g15a"), fileGiulia.contains("uscita-prova-g15a"), pratiche.contains("sinistro-prova-g15"),
              !indice.contains("capsula-prova-g15a"), !indice.contains("uscita-prova-g15a"), !indice.contains("sinistro-prova-g15") else {
            return "giro 15: capsule, uscite o sinistri non stanno al loro posto nella cartella a pezzi"
        }

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard d.capsule == capsule else { return "giro 15: le capsule del tempo non tornano uguali dal backup" }
        guard d.uscite == uscite else { return "giro 15: le uscite non tornano uguali dal backup" }
        guard d.sinistri == [sinistro] else { return "giro 15: i sinistri non tornano uguali dal backup" }
        guard d.clienti.first(where: { $0.id == "giulia" })?.prismaCliente == archivio.clienti[i].prismaCliente else {
            return "giro 15: lo stato del Prisma del cliente non torna dal backup"
        }
        guard d.clienti.first(where: { $0.id == "giulia" })?.consensi == archivio.clienti[i].consensi else {
            return "giro 15: il consenso a WhatsApp non torna dal backup"
        }
        guard d.impostazioni.sala == archivio.impostazioni.sala, d.impostazioni.sala.fileHtmlAcceso else {
            return "giro 15: le avvertenze del file e del film o l'interruttore dell'HTML non tornano dal backup"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        let r = Archivio.carica(in: ripristinata).dati
        guard r.capsule == capsule, r.uscite == uscite, r.sinistri == [sinistro], r.impostazioni.sala == archivio.impostazioni.sala else {
            return "giro 15: capsule, uscite, sinistri o impostazioni della Sala non tornano dal ripristino"
        }

        // Un archivio di prima, senza le chiavi nuove: elenchi vuoti, stato del Prisma del cliente nil, interruttore spento
        var vecchio = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio)) as? [String: Any] ?? [:]
        vecchio["capsule"] = nil
        vecchio["sinistri"] = nil
        vecchio["uscite"] = nil
        if var clienti = vecchio["clienti"] as? [[String: Any]] {
            for k in clienti.indices {
                clienti[k]["prismaCliente"] = nil
                if var consensi = clienti[k]["consensi"] as? [String: Any] {
                    consensi["whatsapp"] = nil
                    consensi["dataWhatsapp"] = nil
                    clienti[k]["consensi"] = consensi
                }
            }
            vecchio["clienti"] = clienti
        }
        if var imp = vecchio["impostazioni"] as? [String: Any], var sala = imp["sala"] as? [String: Any] {
            sala["avvertenzaFile"] = nil
            sala["avvertenzaFilm"] = nil
            sala["htmlSperimentale"] = nil
            imp["sala"] = sala
            vecchio["impostazioni"] = imp
        }
        let letto = try Archivio.decodificatore.decode(DatiPrisma.self, from: JSONSerialization.data(withJSONObject: vecchio))
        guard letto.capsule.isEmpty, letto.sinistri.isEmpty, letto.uscite.isEmpty,
              letto.clienti.allSatisfy({ $0.prismaCliente == nil && $0.consensi.whatsapp == nil }),
              letto.impostazioni.sala.avvertenzaFile == nil, !letto.impostazioni.sala.fileHtmlAcceso else {
            return "giro 15: un archivio di prima non si apre con gli elenchi vuoti e i campi nuovi assenti"
        }

        // Lettura tollerante: una capsula senza sigillo, un'uscita di genere sconosciuto e un sinistro senza data si
        // scartano; uno stato di capsula sconosciuto torna «sigillata», una fase sconosciuta «Denuncia», un fatto rovinato
        // si scarta
        var capsulaStrana = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(capsule[0])) as? [String: Any] ?? [:]
        capsulaStrana["stato"] = "statoDelFuturo"
        var senzaSigillo = capsulaStrana
        senzaSigillo["sigillo"] = nil
        let capsuleLette = try Archivio.decodificatore.decode(ElencoTollerante<CapsulaTempo>.self,
                                                              from: JSONSerialization.data(withJSONObject: [capsulaStrana, senzaSigillo])).elementi
        guard capsuleLette.count == 1, capsuleLette[0].stato == .sigillata, capsuleLette[0].id == capsule[0].id else {
            return "giro 15: le capsule non si leggono con tolleranza"
        }
        var uscitaStrana = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(uscite[1])) as? [String: Any] ?? [:]
        uscitaStrana["genere"] = "genereDelFuturo"
        let usciteLette = try Archivio.decodificatore.decode(
            ElencoTollerante<UscitaCliente>.self,
            from: JSONSerialization.data(withJSONObject: [uscitaStrana, try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(uscite[0]))])).elementi
        guard usciteLette == [uscite[0]] else { return "giro 15: le uscite non si leggono con tolleranza" }
        var sinistroStrano = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(sinistro)) as? [String: Any] ?? [:]
        sinistroStrano["fase"] = "faseDelFuturo"
        if var eventi = sinistroStrano["eventi"] as? [[String: Any]], !eventi.isEmpty {
            eventi[0]["data"] = nil
            sinistroStrano["eventi"] = eventi
        }
        var senzaData = sinistroStrano
        senzaData["apertoIl"] = nil
        let sinistriLetti = try Archivio.decodificatore.decode(ElencoTollerante<Sinistro>.self,
                                                               from: JSONSerialization.data(withJSONObject: [sinistroStrano, senzaData])).elementi
        guard sinistriLetti.count == 1, sinistriLetti[0].fase == .denuncia, sinistriLetti[0].eventi.map(\.id) == ["ev-g15-2"] else {
            return "giro 15: i sinistri non si leggono con tolleranza"
        }

        // Un cliente tolto porta via capsule, sinistri e uscite; quelli degli altri restano
        let s = StatoShell(persistente: false)
        var altra = uscite[1]
        altra.id = "uscita-prova-g15-marco"
        altra.clienteId = "marco"
        s.dati.capsule = capsule
        s.dati.uscite = uscite + [altra]
        s.dati.sinistri = [sinistro]
        s.eliminaCliente("giulia")
        guard s.dati.capsule.isEmpty, s.dati.sinistri.isEmpty, s.dati.uscite == [altra] else {
            return "giro 15: un cliente tolto non porta via capsule, sinistri e uscite (o porta via quelli degli altri)"
        }
        // La traccia nel dossier e l'avviso della prima volta
        guard s.primaUscita(clienteId: "laura") else { return "giro 15: la prima uscita di un cliente non risulta tale" }
        let nuova = s.registraUscita(clienteId: "laura", genere: .film, descrizione: "Video", via: "  ", documentoId: nil, protetto: false)
        guard !s.primaUscita(clienteId: "laura"), s.usciteCliente("laura") == [nuova], nuova.via == nil else {
            return "giro 15: la traccia delle uscite non si registra come atteso"
        }
        return nil
    }
}
