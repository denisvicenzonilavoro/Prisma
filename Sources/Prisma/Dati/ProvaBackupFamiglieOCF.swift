import Foundation

// Le tabelle delle famiglie caricate e l'allenamento OCF (versione 26, «Orizzonte», giro 6) dentro
// `Prisma --prova-backup`: tornano uguali dal backup (le tavole a una dimensione della Banca d'Italia, versione 2 del
// formato); un archivio senza i campi nuovi si apre con le tavole incluse e l'allenamento vuoto, e il resto uguale; tabelle illeggibili non bloccano l'archivio; una domanda o una risposta
// illeggibile si scarta da sola.

extension ProvaBackup {
    /// Le tabelle caricate di prova: le tavole della Banca d'Italia incluse nell'app (versione 2, con i gruppi e le
    /// voci per chiave), come se il consulente le avesse caricate da un file.
    static func famiglieDiProva() -> FamiglieCaricate? {
        TabelleFamiglie.tabellePredefinite.map {
            FamiglieCaricate(tabelle: $0, nomeFile: "famiglie-prova.json", caricateIl: Date(timeIntervalSinceReferenceDate: 815_000_000))
        }
    }

    /// Un allenamento OCF di prova: due materie, due domande (una con il caso), tre risposte e la data dell'esame.
    static func ocfDiProva() -> ArchivioOCF {
        var a = ArchivioOCF()
        a.materie = [MateriaOCF(id: "materia-prova", nome: "Materia di prova", caso: .gestioneSeparata),
                     MateriaOCF(id: "altra-prova", nome: "Altra materia di prova")]
        a.domande = [
            DomandaOCF(id: "ocf-prova-1", materia: "materia-prova", testo: "Domanda di prova?", risposte: ["uno", "due", "tre", "quattro"],
                       corretta: 2, spiegazione: "Spiegazione di prova.", fonte: "Appunti di prova", origine: .importata,
                       caso: .kid, aggiuntaIl: Date(timeIntervalSinceReferenceDate: 815_000_000)),
            DomandaOCF(id: "ocf-prova-2", materia: "altra-prova", testo: "Seconda domanda di prova?", risposte: ["a", "b", "c", "d"],
                       corretta: 0, origine: .esempio),
        ]
        a.risposte = [
            RispostaOCF(id: "risposta-prova-1", domandaId: "ocf-prova-1", data: Date(timeIntervalSinceReferenceDate: 815_000_060), giusta: false, scelta: 1),
            RispostaOCF(id: "risposta-prova-2", domandaId: "ocf-prova-1", data: Date(timeIntervalSinceReferenceDate: 815_086_460), giusta: true, scelta: 2),
            RispostaOCF(id: "risposta-prova-3", domandaId: "ocf-prova-2", data: Date(timeIntervalSinceReferenceDate: 815_000_120), giusta: true),
        ]
        a.dataEsame = Date(timeIntervalSinceReferenceDate: 825_000_000)
        a.nuovePerGiorno = 15
        return a
    }

    /// Controlla tabelle e allenamento dopo il ripristino e la lettura di un archivio senza.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaFamiglieOCF(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard let famiglie = originale.famiglie, originale.ocf.domande.count == 2 else {
            return "l'archivio di prova non ha tabelle delle famiglie caricate né allenamento OCF (tavole della Banca d'Italia incluse mancanti?)"
        }
        guard estratto.famiglie == famiglie, estratto.famiglie?.tabelle.versione == 2,
              estratto.famiglie?.tabelle.gruppi.count == famiglie.tabelle.gruppi.count,
              estratto.famiglie?.tabelle.gruppo(.eta)?.classi.first?.valore(.tassoRisparmio)
                == famiglie.tabelle.gruppo(.eta)?.classi.first?.valore(.tassoRisparmio),
              estratto.famiglie?.nomeFile == "famiglie-prova.json", estratto.famiglie?.tabelle.diProva == false else {
            return "le tabelle delle famiglie caricate non tornano uguali dal backup"
        }
        guard estratto.ocf == originale.ocf, estratto.ocf.domanda("ocf-prova-1")?.caso == .kid,
              estratto.ocf.domanda("ocf-prova-2")?.origine == .esempio, estratto.ocf.materia("materia-prova")?.caso == .gestioneSeparata,
              estratto.ocf.risposte.map(\.id) == ["risposta-prova-1", "risposta-prova-2", "risposta-prova-3"],
              estratto.ocf.dataEsame == originale.ocf.dataEsame, estratto.ocf.nuovePerGiorno == 15 else {
            return "l'allenamento OCF non torna uguale dal backup"
        }
        // 2. Un archivio senza i campi nuovi del giro 6 si apre con le tavole incluse, l'allenamento vuoto e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "famiglie") != nil, radice.removeValue(forKey: "ocf") != nil else {
            return "archivio di prova senza famiglie e OCF non preparato"
        }
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.famiglie == nil, letto.ocf == ArchivioOCF(), letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni,
              letto.sessioniCopilota == atteso.sessioniCopilota, letto.impostazioni == atteso.impostazioni else {
            return "archivio senza famiglie e OCF non letto correttamente (attese le tavole incluse e l'allenamento vuoto)"
        }
        // 3. Tabelle illeggibili: l'archivio si apre con le tavole incluse; domande e risposte illeggibili si scartano
        guard let ocfGrezzo = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.ocf)) as? [String: Any],
              var domande = ocfGrezzo["domande"] as? [[String: Any]], let prima = domande.first else {
            return "allenamento OCF di prova non codificato"
        }
        var senzaRisposte = prima
        senzaRisposte["id"] = "ocf-rotta"
        senzaRisposte["risposte"] = ["una sola"]
        domande.append(senzaRisposte)
        var domandeStrane: [Any] = domande
        domandeStrane.append(["id": "senza-testo"])
        var risposteStrane: [Any] = (ocfGrezzo["risposte"] as? [Any]) ?? []
        risposteStrane.append("non è una risposta")
        risposteStrane.append(7)
        var ocf = ocfGrezzo
        ocf["domande"] = domandeStrane
        ocf["risposte"] = risposteStrane
        radice["ocf"] = ocf
        radice["famiglie"] = ["tabelle": "non sono tabelle", "nomeFile": 3] as [String: Any]
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.famiglie == nil, illeggibile.ocf.domande.map(\.id) == ["ocf-prova-1", "ocf-prova-2"],
              illeggibile.ocf.risposte.count == 3, illeggibile.clienti.count == originale.clienti.count else {
            return "famiglie o allenamento OCF illeggibili: archivio non aperto tenendo solo i dati buoni"
        }
        // 4. La versione dell'archivio resta la 26
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "famiglie e OCF chiedono almeno la versione 26 dell'archivio"
        }
        return nil
    }
}
