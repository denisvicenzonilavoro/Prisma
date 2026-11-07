import Foundation

// Parcelle, dati fiscali e raccomandazioni (versione 26, «Orizzonte», giro 2) dentro `Prisma --prova-backup`: tornano
// uguali dal backup, e un archivio senza i campi nuovi si apre con le parcelle e le raccomandazioni vuote, i dati
// fiscali vuoti e tutto il resto uguale. Un campo illeggibile non fa scartare l'archivio.
// TUTTI I DATI SONO DI PROVA E FITTIZI (ProvaFatturaPA.swift): il regime è il regime di prova dichiarato, non una scelta.

extension ProvaBackup {
    /// I dati fiscali di prova del consulente (fittizi), con il regime di prova A e una numerazione di prova.
    static func fatturazioneDiProva() -> DatiFatturazione {
        var f = ProvaFatturaPA.consulenteDiProva(regime: ProvaFatturaPA.regimeDiProvaConIVA())
        f.numerazione.modello = "{anno}/{numero:3}"
        f.numerazione.primoNumeroPerAnno[2026] = 14
        f.numerazione.ultimoProgressivoInvio = 3
        f.giorniPagamento = 30
        return f
    }

    /// I dati di prova per la fattura di un cliente (fittizi).
    static func fiscaleClienteDiProva() -> DatiFiscaliCliente {
        ProvaFatturaPA.clienteDiProva().fiscale ?? DatiFiscaliCliente()
    }

    /// Tre parcelle di prova del cliente: una bozza, una emessa con le voci congelate e un file, una annullata.
    static func parcelleDiProva(clienteId: String) -> [Parcella] {
        let cal = Calendar(identifier: .gregorian)
        let f = fatturazioneDiProva()
        var bozza = Parcella(id: "parcella-prova-bozza", clienteId: clienteId, data: AiutiProva.data(2026, 11, 20),
                             descrizione: "Consulenza di prova", righe: [RigaParcella(id: "rb1", descrizione: "Analisi di prova", importo: 300)],
                             ricorrente: true, cal: cal)
        bozza.consulenzaId = "consulenza-prova"
        var emessa = Parcella(id: "parcella-prova-emessa", clienteId: clienteId, data: AiutiProva.data(2026, 10, 1),
                              descrizione: "Consulenza di prova", righe: [RigaParcella(id: "re1", descrizione: "Analisi di prova", importo: 1_000),
                                                                           RigaParcella(id: "re2", descrizione: "Relazione di prova", importo: 250.50)],
                              cal: cal)
        emessa.incontroId = "incontro-prova"
        emessa.scadenza = AiutiProva.data(2026, 10, 31)
        emessa = MotoreParcelle.emessa(emessa, tra: [], data: AiutiProva.data(2026, 10, 1), numerazione: f.numerazione,
                                       regime: f.regime, cal: cal)
        emessa.progressivoInvio = MotoreParcelle.progressivoInvio(3)
        emessa.documenti = [DocumentoParcella(id: "doc-prova-xml", formato: .xml, nomeFile: "IT01234567897_00003.xml",
                                              creatoIl: AiutiProva.data(2026, 10, 1))]
        var annullata = MotoreParcelle.emessa(
            Parcella(id: "parcella-prova-annullata", clienteId: clienteId, data: AiutiProva.data(2026, 9, 1),
                     righe: [RigaParcella(id: "ra1", descrizione: "Consulenza di prova", importo: 200)], cal: cal),
            tra: [emessa], data: AiutiProva.data(2026, 9, 1), numerazione: f.numerazione, regime: f.regime, cal: cal)
        annullata.stato = .annullata
        annullata.annullataIl = AiutiProva.data(2026, 9, 5)
        annullata.notaDiCredito = "NC 2026/001"
        return [bozza, emessa, annullata]
    }

    /// Una raccomandazione di prova registrata, con una scelta del cliente e una nota aggiunte.
    static func raccomandazioniDiProva(clienteId: String, posizioneId: String?) -> [Raccomandazione] {
        let cifre = CifreRaccomandazione(righe: [RigaRaccomandazione(etichetta: "Premio", valore: "450 € · mensile")],
                                         indicatori: ["premio": 450, "premioAnnuo": 5_400, "sri": 3])
        var r = Raccomandazione(id: "racc-prova", data: AiutiProva.data(2026, 3, 2), clienteId: clienteId, posizioneId: posizioneId,
                                canale: .indipendente, area: .risparmio, proposta: "Piano di prova da 450 € al mese",
                                motivazione: "Motivazione di prova", cifre: cifre,
                                alternativa: AlternativaRaccomandazione(tipo: .riferimento, descrizione: "Lo stesso capitale al ritmo dell'inflazione",
                                                                        serieRiferimento: SerieRiferimento.idInflazione, ricavata: true))
        r.registraScelta(.inAttesa, il: AiutiProva.data(2026, 3, 2))
        r.registraScelta(.accettata, il: AiutiProva.data(2026, 3, 20))
        r.aggiungiNota("Nota di prova", il: AiutiProva.data(2026, 4, 1))
        return [r]
    }

    /// Controlla parcelle, dati fiscali e raccomandazioni dopo il ripristino e la lettura di un archivio senza.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaParcelle(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.parcelle.count == 3, !originale.raccomandazioni.isEmpty,
              !originale.impostazioni.studio.fatturazione.vuoti, originale.clienti.contains(where: { $0.fiscale != nil }) else {
            return "l'archivio di prova non ha parcelle, raccomandazioni o dati fiscali"
        }
        guard estratto.parcelle == originale.parcelle, estratto.raccomandazioni == originale.raccomandazioni,
              estratto.impostazioni.studio.fatturazione == originale.impostazioni.studio.fatturazione,
              estratto.clienti.map(\.fiscale) == originale.clienti.map(\.fiscale),
              estratto.parcelle.first(where: { $0.id == "parcella-prova-emessa" })?.voci?.totaleDocumento == 1_586.63,
              estratto.parcelle.first(where: { $0.id == "parcella-prova-emessa" })?.numero == "2026/014",
              estratto.raccomandazioni.first?.scelta == .accettata, estratto.raccomandazioni.first?.note.count == 1,
              estratto.impostazioni.studio.fatturazione.regime.regimeFiscale == .rf01 else {
            return "parcelle, dati fiscali o raccomandazioni non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi nuovi del giro 2 si apre vuoto, con tutto il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "parcelle") != nil, radice.removeValue(forKey: "raccomandazioni") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              var studio = impostazioni["studio"] as? [String: Any], studio.removeValue(forKey: "fatturazione") != nil,
              let clienti = radice["clienti"] as? [[String: Any]] else {
            return "archivio di prova senza parcelle e raccomandazioni non preparato"
        }
        impostazioni["studio"] = studio
        radice["impostazioni"] = impostazioni
        radice["clienti"] = clienti.map { c -> [String: Any] in
            var senza = c
            senza.removeValue(forKey: "fiscale")
            return senza
        }
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        var atteso = try Archivio.decodifica(codificato)
        atteso.parcelle = []
        atteso.raccomandazioni = []
        atteso.impostazioni.studio.fatturazione = DatiFatturazione()
        for i in atteso.clienti.indices { atteso.clienti[i].fiscale = nil }
        guard letto.parcelle.isEmpty, letto.raccomandazioni.isEmpty, letto.impostazioni.studio.fatturazione.vuoti,
              letto.clienti.allSatisfy({ $0.fiscale == nil }), letto.impostazioni == atteso.impostazioni,
              letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni,
              letto.schedeAdeguatezza == atteso.schedeAdeguatezza else {
            return "archivio senza parcelle, raccomandazioni e dati fiscali non letto correttamente (attesi vuoti)"
        }
        // 3. Campi illeggibili: si scartano solo loro, l'archivio si apre
        studio["fatturazione"] = "non sono dati fiscali"
        impostazioni["studio"] = studio
        radice["impostazioni"] = impostazioni
        radice["parcelle"] = [["id": "senza-cliente"], 7, "non è una parcella"] as [Any]
        radice["raccomandazioni"] = "non è un registro"
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.parcelle.isEmpty, illeggibile.raccomandazioni.isEmpty,
              illeggibile.impostazioni.studio.fatturazione.vuoti,
              illeggibile.impostazioni.studio.aliquote == originale.impostazioni.studio.aliquote,
              illeggibile.clienti.count == originale.clienti.count else {
            return "parcelle, raccomandazioni o dati fiscali illeggibili: archivio non aperto con i valori vuoti"
        }
        return nil
    }
}
