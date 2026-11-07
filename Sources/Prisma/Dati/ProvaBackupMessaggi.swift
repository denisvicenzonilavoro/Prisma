import Foundation

// I messaggi ai clienti e le impostazioni dei messaggi (versione 26, «Orizzonte», giro 3) dentro `Prisma --prova-backup`:
// tornano uguali dal backup, un archivio senza i campi nuovi si apre con i messaggi vuoti e le impostazioni predefinite
// e tutto il resto uguale, un messaggio illeggibile si scarta da solo. I testi e le firme sono DI PROVA.

extension ProvaBackup {
    /// Due messaggi di prova: uno scritto da Ruby e aperto in Mail, uno del modello fisso salvato nel dossier.
    static func messaggiDiProva(clienteId: String) -> [MessaggioCliente] {
        let creato = AiutiProva.data(2026, 11, 4)
        var mail = MessaggioCliente(clienteId: clienteId, occasioneId: "riepilogoIncontro-\(clienteId)-incontro-prova",
                                    origine: OrigineMessaggio(tipo: .riepilogoIncontro, riferimento: "incontro-prova"),
                                    canaleLavoro: .indipendente, tono: .cordiale, canale: .mail, oggetto: "Il riepilogo del nostro incontro",
                                    testo: "Ciao, grazie per l'incontro del 4 novembre 2026.\n\nUn saluto,\nFirma di prova",
                                    cifre: [CifraMessaggio(.dataIncontro, "4 novembre 2026"), CifraMessaggio(.oraIncontro, "09:30")],
                                    autore: .ruby, modello: "qwen3.5:4b", creatoIl: creato)
        mail.id = "messaggio-prova-mail"
        mail.stato = .apertoInMail
        mail.apertoIl = AiutiProva.data(2026, 11, 5)
        var sms = MessaggioCliente(clienteId: clienteId, occasioneId: "scadenzaPosizione-\(clienteId)-pos-prova-20261219",
                                   origine: OrigineMessaggio(tipo: .scadenzaPosizione, riferimento: "pos-prova-20261219"),
                                   canaleLavoro: .alleanza, tono: .breve, canale: .messaggi, oggetto: nil,
                                   testo: "Ciao, «Polizza di prova» scade il 19 dicembre 2026: ci vediamo per guardarla insieme?",
                                   cifre: [CifraMessaggio(.posizione, "Polizza di prova"), CifraMessaggio(.scadenza, "19 dicembre 2026"),
                                           CifraMessaggio(.giorniAllaScadenza, "45")],
                                   autore: .modelloFisso, modello: nil, creatoIl: creato)
        sms.id = "messaggio-prova-sms"
        sms.stato = .salvato
        return [mail, sms]
    }

    /// Impostazioni dei messaggi di prova (firme di prova, anticipo cambiato).
    static func impostazioniMessaggiDiProva() -> ImpostazioniMessaggi {
        var m = ImpostazioniMessaggi()
        m.firmaAlleanza = "Firma di prova Alleanza"
        m.firmaIndipendente = "Firma di prova indipendente"
        m.giorniScadenza = 30
        return m
    }

    /// Controlla messaggi e impostazioni dei messaggi dopo il ripristino e la lettura di un archivio senza.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaMessaggi(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.messaggi.count == 2, originale.impostazioni.messaggi != ImpostazioniMessaggi() else {
            return "l'archivio di prova non ha messaggi ai clienti né impostazioni dei messaggi"
        }
        guard estratto.messaggi == originale.messaggi, estratto.impostazioni.messaggi == originale.impostazioni.messaggi,
              estratto.messaggi.first(where: { $0.id == "messaggio-prova-mail" })?.stato == .apertoInMail,
              estratto.messaggi.first(where: { $0.id == "messaggio-prova-mail" })?.modello == "qwen3.5:4b",
              estratto.messaggi.first(where: { $0.id == "messaggio-prova-sms" })?.oggetto == nil,
              estratto.messaggi.first(where: { $0.id == "messaggio-prova-sms" })?.cifre.count == 3,
              estratto.impostazioni.messaggi.giorniScadenza == 30 else {
            return "i messaggi ai clienti o le impostazioni dei messaggi non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi nuovi del giro 3 si apre con i messaggi vuoti e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "messaggi") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "messaggi") != nil else {
            return "archivio di prova senza messaggi non preparato"
        }
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        var atteso = try Archivio.decodifica(codificato)
        atteso.messaggi = []
        atteso.impostazioni.messaggi = ImpostazioniMessaggi()
        guard letto.messaggi.isEmpty, letto.impostazioni.messaggi == ImpostazioniMessaggi(),
              letto.impostazioni == atteso.impostazioni, letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni,
              letto.parcelle == atteso.parcelle, letto.note == atteso.note else {
            return "archivio senza messaggi non letto correttamente (attesi vuoti)"
        }
        // 3. Un messaggio illeggibile si scarta, gli altri restano; tono e stato sconosciuti tornano al predefinito
        guard let primo = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.messaggi)) as? [[String: Any]])?.first else {
            return "messaggio di prova non codificato"
        }
        var strano = primo
        strano["tono"] = "scherzoso"
        strano["stato"] = "spedito da solo"
        radice["messaggi"] = [["id": "senza-testo", "clienteId": "x"], 7, "non è un messaggio", strano] as [Any]
        impostazioni["messaggi"] = "non sono impostazioni"
        radice["impostazioni"] = impostazioni
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.messaggi.count == 1, illeggibile.messaggi.first?.tono == .cordiale,
              illeggibile.messaggi.first?.stato == .salvato, illeggibile.messaggi.first?.testo == originale.messaggi.first?.testo,
              illeggibile.impostazioni.messaggi == ImpostazioniMessaggi(), illeggibile.clienti.count == originale.clienti.count else {
            return "messaggi illeggibili: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. La versione dell'archivio resta la 26
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "i messaggi ai clienti chiedono almeno la versione 26 dell'archivio"
        }
        return nil
    }
}
