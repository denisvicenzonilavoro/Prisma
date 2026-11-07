import Foundation

// Mercato (versione 26, «Orizzonte», giro 7) dentro `Prisma --prova-backup`: impostazioni (interruttore, serie attive,
// soglie, riferimenti), serie scaricate e importate, quote per ISIN con la fonte, avvisi con lo stato, e ISIN, numero di
// quote e cedola di una posizione tornano uguali dal backup; un archivio senza Mercato si apre con Mercato vuoto e
// spento e tutto il resto uguale; un punto senza data, un ISIN sbagliato o un avviso illeggibile si scartano da soli.
// Valori, ISIN («ZZ…», non esistono) e fonti sono DI PROVA.

extension ProvaBackup {
    static let isinDiProvaMercato = "ZZ0000000016"

    /// Un archivio di Mercato di prova: una serie della BCE, una importata da CSV, le quote di un ISIN e due avvisi.
    static func mercatoDiProva(clienteId: String, posizioneId: String?) -> ArchivioMercato {
        let d = AiutiProva.data
        var m = ArchivioMercato()
        m.serie = [
            SerieMercato(id: "bce-depositi", codice: "FM.D.U2.EUR.4F.KR.DFR.LEV", nome: "Tasso BCE sui depositi", origine: .bce, fonte: "BCE",
                         unita: .percentuale, tipo: .tassoUfficiale, frequenza: .giornaliera,
                         punti: [PuntoMercato(data: d(2025, 4, 23), valore: 2.25), PuntoMercato(data: d(2025, 6, 11), valore: 2)],
                         aggiornataIl: d(2026, 11, 3)),
            SerieMercato(id: "serie-prova-indice", nome: "Indice di prova", origine: .csv, fonte: "File di prova", datoDiTerzi: "Terzi di prova",
                         unita: .punti, tipo: .indiceAzionario, frequenza: .mensile,
                         punti: [PuntoMercato(data: d(2026, 9, 1), valore: 1_000), PuntoMercato(data: d(2026, 10, 1), valore: 980.5)],
                         aggiornataIl: d(2026, 11, 2)),
        ]
        m.quote = [QuotaISIN(isin: isinDiProvaMercato, nome: "Fondo di prova", punti: [
            PuntoMercato(data: d(2026, 10, 30), valore: 18.42, fonte: "Estratto di prova"),
            PuntoMercato(data: d(2026, 10, 31), valore: 18.5, fonte: "Inserito a mano"),
        ], fonte: "Estratto di prova", origine: .csv, importataIl: d(2026, 11, 1))]
        var visto = AvvisoMercato(id: "caloDalMassimo-\(clienteId)-\(isinDiProvaMercato)", tipo: .caloDalMassimo, clienteId: clienteId,
                                  posizioni: posizioneId.map { [$0] } ?? [], isin: isinDiProvaMercato, canale: .indipendente,
                                  titolo: "«Fondo di prova» è sceso del 6,0% dal massimo dell'ultimo anno", dettaglio: "Dettaglio di prova",
                                  valore: 6, soglia: 5, dataDato: d(2026, 10, 31), fonte: "Fonte: Estratto di prova (file importato)",
                                  creatoIl: d(2026, 11, 1))
        visto.stato = .visto
        visto.vistoIl = d(2026, 11, 2)
        let nuovo = AvvisoMercato(id: "variazioneSerie-\(clienteId)-serie-prova-indice-20261001", tipo: .variazioneSerie, clienteId: clienteId,
                                  serieId: "serie-prova-indice", titolo: "«Indice di prova» è sceso del 2,0% a ottobre 2026",
                                  dettaglio: "Dettaglio di prova", valore: -1.95, soglia: 1.5, dataDato: d(2026, 10, 1),
                                  fonte: "Fonte: File di prova (file importato)", creatoIl: d(2026, 11, 3))
        m.avvisi = [visto, nuovo]
        m.ultimoAggiornamento = d(2026, 11, 3)
        m.ultimoErrore = "euribor-3m: errore di prova"
        return m
    }

    /// Impostazioni di Mercato di prova: acceso, due serie attive, tutte le soglie e un riferimento.
    static func impostazioniMercatoDiProva() -> ImpostazioniMercato {
        var i = ImpostazioniMercato()
        i.attivo = true
        i.serieAttive = ["bce-depositi", "inflazione-it"]
        i.caloDalMassimo = 5
        i.distanzaDalRiferimento = 3
        i.giorniCedola = 15
        i.variazioneIndici = 1.5
        i.variazioneTassi = 0.1
        i.riferimenti = [isinDiProvaMercato: "serie-prova-indice"]
        return i
    }

    /// Controlla Mercato dopo il ripristino e la lettura di un archivio senza. Restituisce il motivo dell'errore (nil =
    /// tutto bene).
    static func verificaMercato(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup torna tutto uguale
        guard originale.mercato.serie.count == 2, originale.mercato.quote.count == 1, originale.mercato.avvisi.count == 2,
              originale.impostazioni.mercato.attivo else {
            return "l'archivio di prova non ha i dati di Mercato"
        }
        guard estratto.mercato == originale.mercato, estratto.impostazioni.mercato == originale.impostazioni.mercato,
              estratto.mercato.quota(isinDiProvaMercato)?.punti.map(\.fonte) == ["Estratto di prova", "Inserito a mano"],
              estratto.mercato.avvisi.first(where: { $0.tipo == .caloDalMassimo })?.stato == .visto,
              estratto.mercato.avvisi.first(where: { $0.tipo == .variazioneSerie })?.stato == .nuovo,
              estratto.mercato.serie("serie-prova-indice")?.datoDiTerzi == "Terzi di prova",
              estratto.impostazioni.mercato.giorniCedola == 15, estratto.impostazioni.mercato.riferimenti[isinDiProvaMercato] == "serie-prova-indice" else {
            return "serie, quote, avvisi o impostazioni di Mercato non tornano uguali dal backup"
        }
        guard let p = estratto.posizioni.first(where: { $0.isin == isinDiProvaMercato }), p.numeroQuote == 1_000,
              p.cedola?.volteAllAnno == 2, p.cedola?.tassoAnnuo == 3.5,
              originale.posizioni.first(where: { $0.id == p.id }) == p else {
            return "ISIN, numero di quote o cedola della posizione non tornano uguali dal backup"
        }
        // 2. Un archivio senza Mercato si apre con Mercato vuoto e spento, e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "mercato") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "mercato") != nil else {
            return "archivio di prova senza Mercato non preparato"
        }
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        var atteso = try Archivio.decodifica(codificato)
        atteso.mercato = ArchivioMercato()
        atteso.impostazioni.mercato = ImpostazioniMercato()
        guard letto.mercato == ArchivioMercato(), letto.mercato.vuoto, !letto.impostazioni.mercato.attivo,
              letto.impostazioni.mercato.senzaSoglie, letto.impostazioni == atteso.impostazioni,
              letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni, letto.messaggi == atteso.messaggi else {
            return "archivio senza Mercato non letto correttamente (atteso vuoto e spento)"
        }
        // 3. Elementi illeggibili: si scartano e gli altri restano; soglie non positive restano spente
        guard var sezione = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.mercato))) as? [String: Any],
              var serie = sezione["serie"] as? [[String: Any]], var prima = serie.first,
              var punti = prima["punti"] as? [[String: Any]], let avvisi = sezione["avvisi"] as? [[String: Any]],
              let quote = sezione["quote"] as? [[String: Any]], let quota = quote.first else {
            return "sezione di Mercato di prova non codificata"
        }
        punti.append(["valore": 4])                       // senza data: si scarta
        prima["punti"] = punti
        serie[0] = prima
        serie.append(["codice": "senza id né nome"])       // illeggibile: si scarta
        sezione["serie"] = serie
        var sbagliata = quota
        sbagliata["isin"] = "LU0000000000"                 // cifra di controllo sbagliata: si scarta
        sezione["quote"] = [quota, sbagliata]
        var strano = avvisi[0]
        strano["stato"] = "dimenticato"                    // stato sconosciuto: torna «nuovo»
        sezione["avvisi"] = [strano, ["id": "senza-tipo"], 7] as [Any]
        radice["mercato"] = sezione
        impostazioni["mercato"] = ["attivo": true, "caloDalMassimo": -5, "giorniCedola": 0, "variazioneTassi": "molta"] as [String: Any]
        radice["impostazioni"] = impostazioni
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let mi = illeggibile.mercato
        guard mi.serie.count == 2, mi.serie.first?.punti.count == originale.mercato.serie.first?.punti.count,
              mi.quote.count == 1, mi.quote.first?.isin == isinDiProvaMercato,
              mi.avvisi.count == 1, mi.avvisi.first?.stato == .nuovo, mi.avvisi.first?.id == originale.mercato.avvisi.first?.id,
              illeggibile.impostazioni.mercato.attivo, illeggibile.impostazioni.mercato.senzaSoglie,
              illeggibile.clienti.count == originale.clienti.count else {
            return "Mercato con elementi illeggibili: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. La versione dell'archivio resta la 26
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "Mercato chiede almeno la versione 26 dell'archivio"
        }
        return nil
    }
}
