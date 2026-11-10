import Foundation
import PDFKit

/// Prova di carico (`Prisma --prova-carico`), eseguita dal workflow: Prisma con molti clienti
/// (i clienti di prova copiati più volte) deve restare veloce e leggero, pensando al MacBook Pro M1
/// da 8 GB. Misura il salvataggio e la lettura dell'archivio, Vera e i motori su ogni cliente, i PDF
/// e la memoria occupata.
@MainActor
enum ProvaCarico {
    /// Copie dei clienti di prova: 40 copie dei 5 clienti = 200 clienti.
    nonisolated static let copie = 40
    #if os(macOS)
    /// Sul Mac i limiti di tempo valgono come sono scritti.
    nonisolated static let fattoreTempo = 1.0
    #elseif os(iOS)
    /// Nel simulatore di iPhone e iPad sul server di build (x86_64 su un Mac Intel) tutto è molto più lento:
    /// i limiti di tempo si allargano dieci volte. La memoria resta com'è.
    nonisolated static let fattoreTempo = 10.0
    #endif
    // Limiti oltre i quali la prova fallisce (larghi: il server di build è più lento del Mac)
    static let limiteArchivio = 3.0 * fattoreTempo
    /// Tempo medio per cliente, e tetto per il cliente più lento (il server ha picchi isolati).
    static let limitePerCliente = 0.1 * fattoreTempo
    static let limiteClientePiuLento = 2.0 * fattoreTempo
    static let limitePDF = 8.0 * fattoreTempo
    static let limiteRicerca = 1.0 * fattoreTempo
    /// 150 ms sul runner (prima 100): con Vera (fasi 4-5) e Luce (giri 11-16) le notifiche sono passate da 18 a 25 e il
    /// ricalcolo con le cache piene sta fra 78 ms (runner normale) e 130 ms (runner lento); sul Mac M1 dell'utente è circa
    /// tre volte più veloce. Il limite resta una guardia contro i disastri, non la misura della fluidità.
    static let limiteNotifiche = 0.15 * fattoreTempo
    static let limiteNotifichePrimaVolta = 1.0 * fattoreTempo
    static let limiteMemoriaMB = 1_200.0
    /// Il fascicolo e il portafoglio calcolati la prima volta, e poi ripresi dalla cache (DerivatiDati).
    static let limiteFascicolo = 8.0 * fattoreTempo
    static let limitePortafoglio = 8.0 * fattoreTempo
    static let limiteCache = 0.05 * fattoreTempo

    static func esegui() -> Int32 {
        var errori = 0
        func controlla(_ ok: Bool, _ descrizione: String) {
            print("\(ok ? "OK   " : "ERRORE") \(descrizione)")
            if !ok { errori += 1 }
        }
        func tempo(_ blocco: () throws -> Void) rethrows -> Double {
            let inizio = Date()
            try blocco()
            return Date().timeIntervalSince(inizio)
        }

        let base = DatiPrisma.demo()
        guard let dati = try? moltiplica(base, copie: copie) else {
            controlla(false, "Archivio con \(copie) copie dei clienti di prova")
            return 1
        }
        print("INFO \(dati.clienti.count) clienti, \(dati.posizioni.count) posizioni, \(dati.appuntamenti.count) appuntamenti, \(dati.attivita.count) attività, \(dati.documenti.count) documenti")

        // Archivio: salvataggio e lettura
        var json = Data()
        let scrittura = (try? tempo { json = try Archivio.codificatore.encode(dati) }) ?? .infinity
        var letto: DatiPrisma?
        let lettura = (try? tempo { letto = try Archivio.decodifica(json) }) ?? .infinity
        print("INFO Archivio: \(json.count / 1024) KB, scrittura \(secondi(scrittura)), lettura \(secondi(lettura))")
        controlla(letto?.clienti.count == dati.clienti.count && letto?.posizioni.count == dati.posizioni.count, "Archivio riletto completo")
        controlla(scrittura + lettura < limiteArchivio, "Archivio salvato e riletto in \(secondi(scrittura + lettura)) (limite \(secondi(limiteArchivio)))")

        // Archivio sul disco (giro 0, tappa 3): il file unico di prima contro la cartella a pezzi
        do {
            let m = try misuraDisco(dati)
            print("INFO Disco, prima (archivio.json): \(m.kbVecchio) KB, scrittura \(secondi(m.scritturaVecchia)), avvio fino alla scrivania (lettura intera) \(secondi(m.letturaVecchia)), salvataggio di una nota \(secondi(m.notaVecchia))")
            print("INFO Disco, dopo (a pezzi): \(m.file) file, \(m.kbPezzi) KB, scrittura intera \(secondi(m.scritturaPezzi)), indice \(secondi(m.letturaIndice)) (\(m.kbIndice) KB), lettura intera \(secondi(m.letturaPezzi)), salvataggio di una nota \(secondi(m.notaPezzi)) (\(m.scrittiNota) file, \(m.kbNota) KB)")
            controlla(m.identico, "Cartella a pezzi riletta identica al file unico")
            controlla(m.scrittiNota == 1, "Una nota cambiata riscrive un solo file (\(m.scrittiNota))")
            controlla(m.letturaPezzi < limiteArchivio, "Cartella a pezzi letta in \(secondi(m.letturaPezzi)) (limite \(secondi(limiteArchivio)))")
            controlla(m.notaPezzi < limiteNota, "Nota salvata in \(secondi(m.notaPezzi)) (limite \(secondi(limiteNota)))")
        } catch {
            controlla(false, "Archivio sul disco: \(error.localizedDescription)")
        }

        // Vera e motori su ogni cliente
        let stato = StatoShell(persistente: false)
        stato.dati.carica(dati)
        stato.rispostePreparate = true
        let spunti: [SpuntoVera] = [.riepilogo, .checkUp, .proposte, .pensione, .resoconto]
        var peggiore = (nome: "", tempo: 0.0)
        // Un giro di riscaldamento: formattatori ed espressioni regolari si preparano la prima volta
        if let primo = stato.clienti.first, let f = stato.fonteVera(primo.id) {
            for s in spunti { _ = MotoriVera.sintesi.componi(RichiestaVera(domanda: s.domanda, spunto: s, fonte: f, storia: [])) }
        }
        let totale = tempo {
            for c in stato.clienti {
                let t = tempo {
                    guard let f = stato.fonteVera(c.id) else { return }
                    _ = ContestoVera.scheda(f)
                    for s in spunti { _ = MotoriVera.sintesi.componi(RichiestaVera(domanda: s.domanda, spunto: s, fonte: f, storia: [])) }
                }
                if t > peggiore.tempo { peggiore = (c.nome, t) }
            }
        }
        let medio = totale / Double(max(1, stato.clienti.count))
        print("INFO Vera e motori: \(secondi(totale)) per \(stato.clienti.count) clienti, \(secondi(medio)) in media, il più lento \(peggiore.nome) (\(secondi(peggiore.tempo)))")
        controlla(medio < limitePerCliente, "In media sotto \(secondi(limitePerCliente)) per cliente (scheda e \(spunti.count) spunti di Vera)")
        controlla(peggiore.tempo < limiteClientePiuLento, "Nessun cliente oltre \(secondi(limiteClientePiuLento))")

        // «Cerca ovunque» su tutto l'archivio, anche nel testo dei documenti
        var trovati = 0
        _ = MotoreRicerca.cerca("rossi", in: stato)
        let cerca = tempo {
            for q in ["rossi", "polizza", "pensione integrativa", "zzz introvabile"] {
                trovati += MotoreRicerca.cerca(q, in: stato).reduce(0) { $0 + $1.totale }
            }
        }
        print("INFO Ricerca: 4 ricerche, \(trovati) risultati, in \(secondi(cerca))")
        controlla(trovati > 0 && cerca < limiteRicerca, "Ricerca su tutto l'archivio in \(secondi(cerca)) (limite \(secondi(limiteRicerca)))")

        // Ricerca per criterio (⌘K): parser dei filtri e filtri su tutto l'archivio
        let erroriFiltri = FiltriRicerca.verifica()
        for e in erroriFiltri { controlla(false, "Filtri della ricerca: \(e)") }
        controlla(erroriFiltri.isEmpty, "Filtri della ricerca (scade:, sri>, canale:, costo>, beneficiari:, senza:, riesame:, stato:, area:) letti e applicati")
        var filtrati = 0
        let cercaFiltri = tempo {
            for q in ["scade:2027 canale:alleanza", "sri>=4 stato:inessere", "senza:previdenza", "riesame:dovuto rossi", "costo>1%"] {
                filtrati += MotoreRicerca.cercaCompleta(q, in: stato).sezioni.reduce(0) { $0 + $1.totale }
            }
        }
        print("INFO Ricerca per criterio: 5 ricerche, \(filtrati) risultati, in \(secondi(cercaFiltri))")
        controlla(cercaFiltri < limiteRicerca, "Ricerca per criterio su tutto l'archivio in \(secondi(cercaFiltri)) (limite \(secondi(limiteRicerca)))")

        // Centro notifiche su tutto l'archivio (si ricalcola a ogni disegno della barra)
        // La prima volta calcola anche occasioni, conformità e schede (poi tenute da parte fino al prossimo cambio dei
        // dati); i disegni successivi della barra devono restare sotto il limite stretto
        var quante = 0
        let primaVolta = tempo { quante = MotoreNotifiche.calcola(stato).count }
        let avvisi = tempo { quante = MotoreNotifiche.calcola(stato).count }
        print("INFO Notifiche: \(quante), la prima volta in \(secondi(primaVolta)), poi in \(secondi(avvisi))")
        controlla(primaVolta < limiteNotifichePrimaVolta, "Notifiche calcolate la prima volta in \(secondi(primaVolta)) (limite \(secondi(limiteNotifichePrimaVolta)))")
        controlla(avvisi < limiteNotifiche, "Notifiche ricalcolate in \(secondi(avvisi)) (limite \(secondi(limiteNotifiche)))")

        // PDF di un report con tutto l'archivio caricato
        stato.clienteAttivoId = stato.clienti.first?.id ?? ""
        var pagine = 0
        let pdf = tempo {
            for scelta in [SceltaProspetto.resoconto(report: true), .checkUp(report: true), .previdenza(report: false)] {
                if let d = stato.documentoProspetto(scelta), let file = StampaCarta.pdf(d) { pagine += PDFDocument(data: file)?.pageCount ?? 0 }
            }
        }
        print("INFO Tre documenti, \(pagine) pagine, in \(secondi(pdf))")
        controlla(pagine > 0 && pdf < limitePDF, "PDF impaginati in \(secondi(pdf)) (limite \(secondi(limitePDF)))")

        // Calcoli delle viste con tutto l'archivio: la prima volta si calcolano, poi vengono dalla cache
        var fascicolo: DocumentoStampabile?
        let fascicoloPrimo = tempo { fascicolo = stato.documentoProspettoInCache(.fascicolo) }
        let fascicoloSecondo = tempo { _ = stato.documentoProspettoInCache(.fascicolo) }
        print("INFO Fascicolo: \(fascicolo?.pagine.count ?? 0) pagine in \(secondi(fascicoloPrimo)), dalla cache in \(secondi(fascicoloSecondo))")
        controlla(fascicolo != nil && fascicoloPrimo < limiteFascicolo, "Fascicolo impaginato in \(secondi(fascicoloPrimo)) (limite \(secondi(limiteFascicolo)))")
        controlla(fascicoloSecondo < limiteCache, "Fascicolo dalla cache in \(secondi(fascicoloSecondo)) (limite \(secondi(limiteCache)))")
        var clientiPortafoglio = 0
        let portafoglioPrimo = tempo {
            clientiPortafoglio = stato.riepilogoPortafoglio(canale: nil, area: nil).clienti.count
            _ = stato.portafoglioComune()
        }
        let portafoglioSecondo = tempo {
            _ = stato.riepilogoPortafoglio(canale: nil, area: nil)
            _ = stato.portafoglioComune()
        }
        print("INFO Portafoglio: \(clientiPortafoglio) clienti in \(secondi(portafoglioPrimo)), dalla cache in \(secondi(portafoglioSecondo))")
        controlla(clientiPortafoglio > 0 && portafoglioPrimo < limitePortafoglio, "Portafoglio calcolato in \(secondi(portafoglioPrimo)) (limite \(secondi(limitePortafoglio)))")
        controlla(portafoglioSecondo < limiteCache, "Portafoglio dalla cache in \(secondi(portafoglioSecondo)) (limite \(secondi(limiteCache)))")
        // La cache segue i dati: per ogni cliente gli stessi risultati del calcolo diretto, e una modifica si vede subito
        let coerenti = stato.clienti.allSatisfy { c in
            stato.cliente(c.id)?.id == c.id
                && stato.posizioniCliente(c.id).map(\.id) == stato.dati.posizioni.filter { $0.clienteId == c.id }.map(\.id)
        }
        controlla(coerenti, "Clienti e posizioni per id uguali alla ricerca diretta")
        if let primo = stato.clienti.first, let i = stato.dati.clienti.firstIndex(where: { $0.id == primo.id }) {
            let nome = stato.dati.clienti[i].nome
            stato.dati.clienti[i].nome = nome + " (prova)"
            controlla(stato.cliente(primo.id)?.nome == nome + " (prova)", "Cache dei clienti aggiornata dopo una modifica")
            stato.dati.clienti[i].nome = nome
        }
        // Una nota del taccuino non ricalcola il portafoglio (le cache seguono solo i dati dei calcoli),
        // ma il fascicolo, che legge le note, si impagina di nuovo
        if let i = stato.dati.note.indices.first {
            _ = stato.riepilogoPortafoglio(canale: nil, area: nil)
            _ = stato.portafoglioComune()
            _ = stato.documentoProspettoInCache(.fascicolo)
            let calcoli = stato.versioneCalcoli
            let generazione = stato.generazioneDocumento
            stato.dati.note[i].testo += "·"
            let dopoNota = tempo {
                _ = stato.riepilogoPortafoglio(canale: nil, area: nil)
                _ = stato.portafoglioComune()
            }
            controlla(stato.versioneCalcoli == calcoli && dopoNota < limiteCache,
                      "Una nota non ricalcola il portafoglio (\(secondi(dopoNota)), limite \(secondi(limiteCache)))")
            _ = stato.documentoProspettoInCache(.fascicolo)
            controlla(stato.generazioneDocumento != generazione, "Una nota impagina di nuovo il fascicolo, che legge le note")
            stato.dati.note[i].testo.removeLast()
        }

        // Agenda: il mese raggruppato in un passaggio dà gli stessi giorni del calcolo giorno per giorno
        let giorniMese = CalendarioAgenda.settimane(meseDi: stato.appuntamenti.first?.inizio ?? Date()).flatMap { $0 }
        var indice = GiorniAgenda()
        let agenda = tempo { indice = stato.giorniAgenda(giorniMese) }
        let uguali = giorniMese.allSatisfy { g in
            indice.appuntamenti(g).map(\.id) == stato.appuntamentiDelGiorno(g).map(\.id)
                && Set(indice.scadenze(g).map(\.id)) == Set(stato.scadenzeDelGiorno(g).map(\.id))
        }
        print("INFO Agenda: mese raggruppato in \(secondi(agenda))")
        controlla(uguali, "Agenda: mese raggruppato uguale al calcolo giorno per giorno")

        // Promemoria del Mac: date e testi (calcolo puro, senza il Centro notifiche di macOS)
        for (ok, descrizione) in ProvaPromemoria.verifiche() { controlla(ok, descrizione) }
        // Seguito delle proposte: esito, proposte ferme, notifiche e cache (il prefisso «Seguito: » è già dentro)
        for (ok, descrizione) in ProvaSeguito.verifiche() { controlla(ok, descrizione) }
        // Riesami in Agenda: striscia del mese, «Pianifica» e spazio libero (prefisso «Riesami in Agenda: » già dentro)
        for (ok, descrizione) in ProvaRiesamiAgenda.verifiche() { controlla(ok, descrizione) }
        // Scheda di adeguatezza: scheda di Sofia e di Andrea, PDF, firma, notifiche, elenco dei documenti, tempi
        for (ok, d) in ProvaAdeguatezza.verifiche() { controlla(ok, "Adeguatezza: " + d) }
        // Riesame con memoria: fotografie, variazioni, agganci e cache (prefisso «Memoria del riesame: » già dentro)
        for (ok, descrizione) in ProvaMemoriaRiesame.verifiche() { controlla(ok, descrizione) }
        var riesamiMese: RiesamiDelMese?
        let riesamiTempo = tempo { riesamiMese = stato.riesamiDelMese(Date()) }
        print("INFO Riesami del mese: \(riesamiMese?.daFissare.count ?? 0) da fissare in \(secondi(riesamiTempo))")
        controlla(riesamiTempo < 0.5 * fattoreTempo, "Riesami del mese con \(stato.dati.clienti.count) clienti sotto 0,5 s")

        // Il radar del portafoglio («Luce» giro 2): tutti i clienti con un modello, in un passaggio
        var radar: RadarPortafoglio?
        let tempoRadar = tempo { radar = MotoreRadar.calcola(stato.dati.istantanea) }
        print("INFO Radar: \(radar?.voci.count ?? 0) clienti sul radar, \(radar?.fuori.count ?? 0) fuori tolleranza, in \(secondi(tempoRadar))")
        controlla((radar?.voci.count ?? 0) >= stato.dati.clienti.count / 2, "Radar: i clienti con un modello sono sul radar")
        controlla(tempoRadar < 0.5 * fattoreTempo, "Radar con \(stato.dati.clienti.count) clienti sotto 0,5 s")

        // Memoria
        let mb = memoriaMB()
        print("INFO Memoria occupata: \(Int(mb)) MB")
        controlla(mb < limiteMemoriaMB, "Memoria sotto \(Int(limiteMemoriaMB)) MB")

        if errori == 0 {
            print("OK: carico verificato")
            return 0
        }
        print("ERRORE: \(errori) verifiche di carico non riuscite")
        return 1
    }

    /// I clienti di prova copiati più volte, con tutti i loro dati: in ogni copia l'identificativo
    /// del cliente prende un suffisso ("giulia" → "giulia-7"), e con lui posizioni, agenda e documenti.
    nonisolated static func moltiplica(_ base: DatiPrisma, copie: Int) throws -> DatiPrisma {
        var dati = base
        let testo = String(decoding: try Archivio.codificatore.encode(base), as: UTF8.self)
        for k in 1..<max(1, copie) {
            var copia = testo
            for c in base.clienti {
                let re = try NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: c.id))\\b")
                copia = re.stringByReplacingMatches(in: copia, range: NSRange(copia.startIndex..., in: copia), withTemplate: "\(c.id)-\(k)")
            }
            let d = try Archivio.decodifica(Data(copia.utf8))
            dati.clienti += d.clienti
            dati.posizioni += d.posizioni
            dati.appuntamenti += d.appuntamenti
            dati.attivita += d.attivita
            dati.incontri += d.incontri
            dati.obiettivi += d.obiettivi
            dati.documenti += d.documenti
            dati.simulazioni += d.simulazioni
        }
        return dati
    }

    /// Il salvataggio di una nota nella cartella a pezzi (un file piccolo).
    static let limiteNota = 0.25 * fattoreTempo

    struct MisuraDisco {
        var kbVecchio = 0, scritturaVecchia = 0.0, letturaVecchia = 0.0, notaVecchia = 0.0
        var file = 0, kbPezzi = 0, kbIndice = 0, scritturaPezzi = 0.0, letturaIndice = 0.0, letturaPezzi = 0.0
        var notaPezzi = 0.0, scrittiNota = 0, kbNota = 0
        var identico = false
    }

    /// Prima e dopo sul disco, in una cartella temporanea: archivio.json (scrittura, lettura intera = ciò che l'avvio
    /// aspettava, salvataggio di una nota = tutto riscritto) e la cartella a pezzi (scrittura intera, indice = ciò che
    /// serve alla schermata di benvenuto, lettura intera in parallelo, salvataggio di una nota = il file del cliente).
    nonisolated static func misuraDisco(_ dati: DatiPrisma) throws -> MisuraDisco {
        let fm = FileManager.default
        let radice = fm.temporaryDirectory.appendingPathComponent("Prisma-carico-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: radice) }
        let prima = radice.appendingPathComponent("Prima", isDirectory: true)
        let dopo = radice.appendingPathComponent("Dopo", isDirectory: true)
        try fm.createDirectory(at: prima, withIntermediateDirectories: true)
        try fm.createDirectory(at: dopo, withIntermediateDirectories: true)
        func tempo(_ blocco: () throws -> Void) rethrows -> Double {
            let inizio = Date()
            try blocco()
            return Date().timeIntervalSince(inizio)
        }
        var m = MisuraDisco()
        let d = try Archivio.decodifica(Archivio.codificatore.encode(dati))
        var conNota = d
        guard let i = conNota.note.indices.first else { return m }
        conNota.note[i].testo += " (un tasto)"

        // Prima: un file solo, scritto e letto per intero
        let file = prima.appendingPathComponent(Archivio.nomeFileVecchio)
        m.scritturaVecchia = try tempo { try Archivio.nuovoCodificatore().encode(d).write(to: file, options: .atomic) }
        m.kbVecchio = ((try? fm.attributesOfItem(atPath: file.path))?[.size] as? Int ?? 0) / 1024
        var vecchio: DatiPrisma?
        m.letturaVecchia = try tempo { vecchio = try Archivio.decodifica(Data(contentsOf: file)) }
        m.notaVecchia = try tempo { try Archivio.nuovoCodificatore().encode(conNota).write(to: file, options: .atomic) }

        // Dopo: la cartella a pezzi
        let scrittore = ScrittorePezzi(cartella: dopo)
        m.scritturaPezzi = try tempo { try scrittore.scrivi(d) }
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dopo)
        let elenco = (fm.enumerator(at: pezzi, includingPropertiesForKeys: [.fileSizeKey])?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "json" }
        m.file = elenco.count
        m.kbPezzi = elenco.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) } / 1024
        m.kbIndice = ((try? fm.attributesOfItem(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice).path))?[.size] as? Int ?? 0) / 1024
        m.letturaIndice = try tempo { _ = try ArchivioPezzi.leggiIndice(pezzi) }
        var letto: (lettura: LetturaArchivio, problemi: [ProblemaPezzo], scartati: [URL])?
        m.letturaPezzi = try tempo { letto = try ArchivioPezzi.leggi(pezzi) }
        m.identico = letto?.lettura.dati == vecchio && letto?.problemi.isEmpty == true && vecchio == d
        if let l = letto?.lettura { scrittore.riparti(da: l) }
        m.notaPezzi = try tempo { try scrittore.scrivi(conNota) }
        m.scrittiNota = scrittore.ultimiScritti.count
        if let f = scrittore.ultimiScritti.first {
            m.kbNota = ((try? fm.attributesOfItem(atPath: pezzi.appendingPathComponent(f).path))?[.size] as? Int ?? 0) / 1024
        }
        return m
    }

    private static func secondi(_ s: Double) -> String {
        s < 1 ? "\(Int((s * 1000).rounded())) ms" : String(format: "%.2f s", s)
    }

    /// Memoria residente del processo, in MB (la usa anche la prova della fluidità).
    static func memoriaMB() -> Double {
        var info = mach_task_basic_info()
        var conta = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let esito = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(conta)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &conta)
            }
        }
        return esito == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : 0
    }
}
