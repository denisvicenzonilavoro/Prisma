import Foundation

// La prova dei sinistri e delle loro impostazioni nel backup («Luce» giro 15, §7.4) dentro `Prisma --prova-backup`: le
// impostazioni dei sinistri (soglia del sinistro fermo, indirizzi delle compagnie con «solo dal portale», documenti per
// tipo) e un sinistro completo tornano uguali da backup e ripristino; le impostazioni di un Prisma di prima (senza le
// chiavi) si aprono con i valori di base; un messaggio dell'aggiornamento del sinistro torna uguale e un Prisma che non
// conosce il tipo `.sinistro` lo salta senza perdere gli altri messaggi. Tutti dati di prova dichiarati, date al secondo.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaSinistri(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("Sinistri", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        var archivio = DatiPrisma.demo()
        guard let marco = archivio.clienti.first(where: { $0.id == "marco" }) else { return "sinistri: manca Marco nei dati di prova" }
        let t0 = Date(timeIntervalSinceReferenceDate: 815_113_291)
        func ora(_ giorni: Int) -> Date { t0.addingTimeInterval(TimeInterval(giorni) * 86_400) }

        // Le impostazioni dei sinistri
        archivio.impostazioni.pratiche.giorniSinistroFermo = 17
        archivio.impostazioni.pratiche.indirizziSinistri = [
            IndirizzoCompagnia(id: "compagnia-prova-1", compagnia: "Compagnia di prova", email: "sinistri@prova.invalid", soloPortale: false),
            IndirizzoCompagnia(id: "compagnia-prova-2", compagnia: "Altra compagnia di prova", email: "", soloPortale: true),
        ]
        archivio.impostazioni.pratiche.documentiPerSinistro = [
            DocumentiSinistro(id: "tipo-prova-1", tipo: "Furto (prova)", documenti: ["Copia della denuncia", "Fattura d'acquisto"]),
        ]

        // Un sinistro completo, con tutti i campi
        var s = Sinistro(id: "sinistro-prova-backup", clienteId: "marco", posizioneId: SinistriDiProva.polizzaMarco,
                         titolo: "Sinistro di prova del backup", descrizione: "Descrizione breve di prova", accadutoIl: ora(1),
                         apertoIl: ora(2))
        s.numeroSinistro = "SIN-PROVA-8823"
        s.fase = .pagato
        s.eventi = [EventoSinistro(id: "ev-backup-1", data: ora(2), testo: "Denuncia di prova", fase: .denuncia),
                    EventoSinistro(id: "ev-backup-2", data: ora(19), testo: "Pagati di prova", fase: .pagato),
                    EventoSinistro(id: "ev-backup-3", data: ora(23), testo: "Fatto senza fase", fase: nil)]
        s.documenti = [DocumentoSinistro(id: "doc-backup-1", titolo: "Denuncia firmata", ricevutoIl: ora(3), documentoId: "doc-prova-backup"),
                       DocumentoSinistro(id: "doc-backup-2", titolo: "Documento mancante", ricevutoIl: nil, documentoId: nil)]
        s.stimaMinima = 1_137
        s.stimaMassima = 1_793
        s.pagato = 1_481
        s.chiusoIl = ora(19)
        s.mostraAlCliente = true
        s.importoAlCliente = true
        s.ultimoAggiornamentoCliente = ora(20)
        archivio.sinistri.removeAll { $0.id == s.id }
        archivio.sinistri.append(s)

        // Un messaggio dell'aggiornamento del sinistro
        let o = MotoreSinistri.occasione(s, cliente: marco, consulente: "Consulente di prova", oggi: ora(20))
        var m = MessaggioCliente(clienteId: "marco", occasioneId: o.id, origine: o.origine, canaleLavoro: o.canale, tono: .cordiale,
                                 canale: .messaggi, oggetto: nil, testo: "Testo di prova", cifre: o.cifre,
                                 autore: .modelloFisso, modello: nil, creatoIl: ora(20))
        m.stato = .apertoInMessaggi
        m.apertoIl = ora(20)
        archivio.messaggi.append(m)
        try Archivio.salva(archivio, in: dati)

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard d.impostazioni.pratiche == archivio.impostazioni.pratiche, d.impostazioni.pratiche.sogliaSinistroFermo == 17,
              d.impostazioni.pratiche.indirizziSinistri?.count == 2, d.impostazioni.pratiche.documentiPerSinistro?.count == 1 else {
            return "sinistri: le impostazioni dei sinistri non tornano uguali dal backup"
        }
        guard d.sinistri.first(where: { $0.id == s.id }) == s else { return "sinistri: un sinistro completo non torna uguale dal backup" }
        guard d.sinistri.map(\.id) == archivio.sinistri.map(\.id) else { return "sinistri: l'elenco dei sinistri non torna uguale dal backup" }
        guard d.messaggi.first(where: { $0.id == m.id }) == m else {
            return "sinistri: il messaggio dell'aggiornamento del sinistro non torna uguale dal backup"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        let r = Archivio.carica(in: ripristinata).dati
        guard r.sinistri.first(where: { $0.id == s.id }) == s, r.impostazioni.pratiche == archivio.impostazioni.pratiche else {
            return "sinistri: il sinistro o le impostazioni dei sinistri non tornano dal ripristino"
        }

        // Impostazioni di un Prisma di prima: senza le chiavi dei sinistri, valori di base
        var imp = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio.impostazioni.pratiche)) as? [String: Any] ?? [:]
        guard imp.removeValue(forKey: "giorniSinistroFermo") != nil, imp.removeValue(forKey: "indirizziSinistri") != nil,
              imp.removeValue(forKey: "documentiPerSinistro") != nil else {
            return "sinistri: le impostazioni dei sinistri non si scrivono nell'archivio"
        }
        let vecchie = try Archivio.decodificatore.decode(ImpostazioniPratiche.self, from: JSONSerialization.data(withJSONObject: imp))
        guard vecchie.giorniSinistroFermo == nil, vecchie.sogliaSinistroFermo == ImpostazioniPratiche.giorniSinistroFermoPredefiniti,
              vecchie.indirizziSinistri == nil, vecchie.documentiPerSinistro == nil,
              vecchie.giorniFerma == archivio.impostazioni.pratiche.giorniFerma else {
            return "sinistri: le impostazioni di un Prisma di prima non si aprono con i valori di base"
        }

        // Un Prisma che non conosce il tipo `.sinistro` salta quel messaggio e tiene gli altri
        let altro = MessaggioCliente(clienteId: "marco", occasioneId: "compleanno-marco-prova",
                                     origine: OrigineMessaggio(tipo: .compleanno, riferimento: "prova"), canaleLavoro: nil,
                                     tono: .cordiale, canale: .mail, oggetto: "Auguri", testo: "Testo di prova", cifre: [],
                                     autore: .modelloFisso, modello: nil, creatoIl: ora(4))
        var sconosciuto = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(m)) as? [String: Any] ?? [:]
        if var origine = sconosciuto["origine"] as? [String: Any] {
            origine["tipo"] = "tipoDelFuturo"
            sconosciuto["origine"] = origine
        }
        let buono = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(altro))
        let letti = try Archivio.decodificatore.decode(ElencoTollerante<MessaggioCliente>.self,
                                                       from: JSONSerialization.data(withJSONObject: [sconosciuto, buono] as [Any])).elementi
        guard letti.map(\.id) == [altro.id] else {
            return "sinistri: un messaggio di tipo sconosciuto non si salta (o fa perdere gli altri)"
        }
        return nil
    }
}
