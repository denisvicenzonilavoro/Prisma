import Foundation

/// Prova automatica di backup, rotazione e ripristino (`Prisma --prova-backup`).
/// La esegue il workflow di build in cartelle temporanee: l'archivio vero non viene toccato.
/// Gira uguale sul Mac (zip con ditto) e nel simulatore iOS (zip con ScrittoreZip e LettoreZip).
enum ProvaBackup {
    static func esegui() -> Int32 {
        let fm = FileManager.default
        let radice = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-\(UUID().uuidString)", isDirectory: true)
        let dati = radice.appendingPathComponent("Prisma", isDirectory: true)
        let backup = radice.appendingPathComponent("Backup", isDirectory: true)
        let destinazione = radice.appendingPathComponent("Ripristino", isDirectory: true)
        defer { try? fm.removeItem(at: radice) }
        do {
            try fm.createDirectory(at: dati.appendingPathComponent("Documenti"), withIntermediateDirectories: true)
            var originale = DatiPrisma.demo()
            // Anche un'Analisi 360 salvata deve tornare identica
            var analisi = Analisi360(cliente: originale.clienti.first, posizioni: originale.posizioni)
            analisi.confermate = [.protezione]
            analisi.aggiornataIl = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
            originale.analisi[originale.clienti.first?.id ?? ""] = analisi
            // E una conversazione con Vera, con le sue impostazioni
            originale.conversazioni[originale.clienti.first?.id ?? ""] = [
                MessaggioVera(autore: .utente, testo: "Fammi un riepilogo del cliente"),
                MessaggioVera(autore: .vera, testo: "Il quadro…", titolo: "Il quadro", motore: "Sintesi dai dati"),
            ]
            // E il commento del consulente in un report
            originale.commenti = [CommentoReport(id: "checkUp·giulia", clienteId: "giulia", testo: "Gentile Giulia, …", bozzaDi: "Sintesi dai dati",
                                                 aggiornatoIl: Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down)))]
            // E uno spazio di lavoro salvato
            originale.spazi = [SpazioLavoro(nome: "Revisione annuale", finestre: [.sinistra(.posizioni), .destra(.vera)])]
            // «Luce» (versione 27): uno spazio con le quattro app nuove (ProvaBackupLuce.swift)
            originale.spazi.append(spazioLuceDiProva())
            // E una ricerca salvata del pannello ⌘K (nelle impostazioni)
            var salvata = RicercaSalvata(nome: "Scadenze Alleanza 2027", testo: "scade:2027 canale:alleanza")
            salvata.creataIl = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
            originale.impostazioni.ricercheSalvate = [salvata]
            // Completezza dei dati (versione 21): un dato segnato come non pertinente
            originale.clienti[0].datiNonPertinenti = ["lavoro": Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))]
            // Seguito delle proposte (versione 21): un seguito con tutti i campi, una proposta rimandata, i giorni scelti
            if let i = originale.posizioni.firstIndex(where: { $0.id == "pos-giulia-piano-previdenziale-integrativo" }) {
                let adesso = Date()
                var s = SeguitoProposta()
                s.presentataIl = ValoriDaDocumento.mezzogiorno(adesso.addingTimeInterval(-30 * 86_400))
                s.esitoIl = ValoriDaDocumento.mezzogiorno(adesso.addingTimeInterval(-10 * 86_400))
                s.riprendereIl = ValoriDaDocumento.mezzogiorno(adesso.addingTimeInterval(60 * 86_400))
                s.motivo = .tempi
                s.nota = "prova"
                s.attivitaId = "task-dati"
                s.appuntamentoEsitoId = "event-giulia-previdenza"
                originale.posizioni[i].seguito = s
            }
            if let i = originale.posizioni.firstIndex(where: { $0.id == "pos-andrea-piano-di-risparmio-rivalutabile" }) {
                originale.posizioni[i].esito = .rimandata
            }
            originale.impostazioni.giorniSeguitoProposte = 30
            // Giro 7: l'introduzione «Come funziona Prisma» vista (campo letto con tolleranza, senza alzare la versione)
            originale.impostazioni.introduzioneVista = true
            // «L'acqua della scrivania» spenta (acceso di base): deve tornare spenta dal backup
            originale.impostazioni.acquaDellaScrivania = false
            // «Riduci movimento» di Prisma acceso (spento di base): deve tornare acceso dal backup
            originale.impostazioni.riduciMovimento = true
            // E gli orari di lavoro dell'agenda (nelle impostazioni)
            originale.impostazioni.orari.giorni = [2, 3, 4]
            originale.impostazioni.orari.margineMinuti = 30
            originale.impostazioni.orari.pomeriggioAttivo = false
            // Giro 4 (versione 22). Scheda di adeguatezza della PIP di Giulia, firmata, e l'elenco dei documenti cambiato
            let secondo = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
            var schedaPIP = SchedaAdeguatezza(posizioneId: "pos-giulia-piano-previdenziale-integrativo", clienteId: "giulia", creataIl: secondo)
            schedaPIP.areaBisogno = .pensione
            schedaPIP.fonte = .nuoviRisparmi
            schedaPIP.motivazione = "Avvio della previdenza integrativa con versamenti mensili dal reddito."
            schedaPIP.consegne = [ConsegnaDocumento(voceId: "all-allegato3", consegnatoIl: secondo),
                                  ConsegnaDocumento(voceId: "all-pip-chiave", consegnatoIl: secondo)]
            schedaPIP.nonPertinenti = ["all-condizioni"]
            schedaPIP.aggiornataIl = secondo
            schedaPIP.firmataIl = secondo
            schedaPIP.esitiAllaFirma = [EsitoRegistrato(controllo: "rischio", semaforo: "verde", esito: "SRI 2 su 7."),
                                        EsitoRegistrato(controllo: "bisogno", semaforo: "verde", esito: "Risponde all'area «Pensione».")]
            originale.schedeAdeguatezza = [schedaPIP]
            originale.impostazioni.consegna.voci.append(VoceDocumento(id: "voce-prova", canale: .indipendente, titolo: "Documento di prova",
                                                                      perTipo: .previdenza, soloSostituzione: true))
            if let k = originale.impostazioni.consegna.voci.firstIndex(where: { $0.id == "all-kid" }) {
                originale.impostazioni.consegna.voci[k].attiva = false
            }
            // Scadenze di conformità: regole cambiate (la chiave non sintetizzata di Impostazioni è provata dal confronto)
            originale.impostazioni.conformita.mesiVerificaAlto = 6
            originale.impostazioni.conformita.informativaAggiornataIl = AiutiProva.data(2026, 6, 1)
            // Calendario delle occasioni: impostazioni e promemoria cambiati
            originale.impostazioni.occasioni.anticipoGiorni = 60
            originale.impostazioni.occasioni.tipiSpenti = [.ricorrenzaGestione]
            originale.impostazioni.occasioni.etaLimiteLTC = 75
            originale.impostazioni.promemoria.occasioni = false
            // Giro 5 (versione 23). Documenti: categoria scelta per la polizza di Marco
            if let i = originale.documenti.firstIndex(where: { $0.id == "doc-marco-polizza" }) {
                originale.documenti[i].categoria = .contratto
                // Documento contro dossier: una voce lasciata come in Prisma (per la coppia di valori)
                originale.documenti[i].vociTenute = ["scadenza|2026-12-01|2026-12-13"]
            }
            // Storico dei dati portati dai documenti, nella posizione multiramo di Marco e nella scheda multiramo
            // (la data a secondi interi, come le altre)
            let quando = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
            var variazione = VariazioneDossier(voce: "sri", prima: "3 su 7", dopo: "4 su 7", valorePrima: ValoreVoce(numero: 3), valoreDopo: ValoreVoce(numero: 4),
                                               documentoId: "doc-marco-polizza", titoloDocumento: "Prova", tipoDocumento: "kid", il: quando,
                                               fontePrecedente: "Fonte di prima")
            variazione.id = "var-prova"
            if let i = originale.posizioni.firstIndex(where: { $0.id == "pos-marco-polizza-multiramo" }) { originale.posizioni[i].variazioni = [variazione] }
            if let i = originale.prodotti.firstIndex(where: { $0.id == "prodotto-multiramo" }) { originale.prodotti[i].variazioni = [variazione] }
            // Metri di confronto dei rendimenti e confronto «TFR in azienda o nel fondo» (versione 24)
            originale.impostazioni.riferimenti.valori = [ValoreRiferimento(serie: SerieRiferimento.idInflazione, anno: 2024, valore: 1.0)]
            originale.impostazioni.riferimenti.indici = [IndiceRiferimento(id: "indice-prova", nome: "Azionario globale", fonte: "prova")]
            originale.impostazioni.riferimenti.perMercato = "indice-prova"
            if let i = originale.posizioni.firstIndex(where: { $0.id == "pos-giulia-etf-azionario-globale" }) { originale.posizioni[i].riferimento = "indice-prova" }
            var tfr = IpotesiTFR()
            tfr.contributoLavoratore = 1.2
            tfr.contributoDatore = 1.6
            tfr.nomeFondo = "Fondo di prova"
            originale.confrontiTFR["marco"] = tfr
            // Fotografie dei riesami (versione 24)
            originale.fotografie = ProvaBackup.fotografieDiProva()
            // Orizzonte (versione 26): impostazioni di Studio (valori di prova della prova) e novità viste
            originale.impostazioni.studio = ProvaBackup.studioDiProva()
            originale.impostazioni.novitaViste = NovitaLuce.versione
            // Orizzonte, giro 2: parcelle, dati fiscali del consulente e del cliente, raccomandazioni (dati di prova fittizi)
            originale.impostazioni.studio.fatturazione = ProvaBackup.fatturazioneDiProva()
            if let i = originale.clienti.indices.first {
                originale.clienti[i].fiscale = ProvaBackup.fiscaleClienteDiProva()
                let cid = originale.clienti[i].id
                originale.parcelle = ProvaBackup.parcelleDiProva(clienteId: cid)
                originale.raccomandazioni = ProvaBackup.raccomandazioniDiProva(
                    clienteId: cid, posizioneId: originale.posizioni.first { $0.clienteId == cid }?.id)
            }
            // Orizzonte, giro 3: messaggi preparati per i clienti e impostazioni dei messaggi (ProvaBackupMessaggi.swift)
            if let cid = originale.clienti.first?.id {
                originale.messaggi = ProvaBackup.messaggiDiProva(clienteId: cid)
            }
            originale.impostazioni.messaggi = ProvaBackup.impostazioniMessaggiDiProva()
            // Orizzonte, giro 4: eventi della linea della vita e risparmio libero del profilo (ProvaBackupLineaVita.swift)
            if let i = originale.clienti.indices.first {
                originale.clienti[i].profilo.risparmioAnnuo = 6_000
                originale.eventiVita = ProvaBackup.eventiVitaDiProva(clienteId: originale.clienti[i].id)
            }
            // Orizzonte, giro 5: consenso all'ascolto e sessioni del copilota (ProvaBackupCopilota.swift)
            if let i = originale.clienti.indices.first {
                originale.clienti[i].consensoCopilota = ProvaBackup.consensoCopilotaDiProva()
                originale.sessioniCopilota = ProvaBackup.sessioniCopilotaDiProva(clienteId: originale.clienti[i].id)
            }
            // Orizzonte, giro 8: impostazioni e dati di Prisma ovunque, mai la passphrase (ProvaBackupOvunque.swift)
            ProvaBackup.aggiungiOvunqueDiProva(&originale)
            // Orizzonte, giro 7: Mercato (serie, quote per ISIN, avvisi, impostazioni) e ISIN, quote e cedola di una
            // posizione (ProvaBackupMercato.swift)
            if let i = originale.posizioni.indices.first {
                originale.posizioni[i].isin = ProvaBackup.isinDiProvaMercato
                originale.posizioni[i].numeroQuote = 1_000
                originale.posizioni[i].cedola = CedolaTitolo(tassoAnnuo: 3.5, volteAllAnno: 2, prossima: AiutiProva.data(2026, 11, 14))
                originale.mercato = ProvaBackup.mercatoDiProva(clienteId: originale.posizioni[i].clienteId, posizioneId: originale.posizioni[i].id)
            }
            originale.impostazioni.mercato = ProvaBackup.impostazioniMercatoDiProva()
            // Orizzonte, giro 6: tabelle delle famiglie caricate e allenamento OCF (ProvaBackupFamiglieOCF.swift)
            originale.famiglie = ProvaBackup.famiglieDiProva()
            originale.ocf = ProvaBackup.ocfDiProva()
            // «Luce», giro 2: portafogli modello, tolleranza, modello dei clienti, bozze di riequilibrio (ProvaBackupRadar.swift)
            ProvaBackup.aggiungiRadarDiProva(&originale)
            // «Luce», giro 3: pratiche dopo la firma e soglia delle pratiche ferme (ProvaBackupPratiche.swift)
            ProvaBackup.aggiungiPraticheDiProva(&originale)
            // «Luce», giro 4: giornata della pensione e partite del gioco del rischio (ProvaBackupSala.swift)
            ProvaBackup.aggiungiSalaDiProva(&originale)
            // «Luce», giro 5: storie della settimana e dell'anno, traguardi, obiettivo raggiunto (ProvaBackupRelazione.swift)
            ProvaBackup.aggiungiRelazioneDiProva(&originale)
            // Il versamento mensile previsto dell'obiettivo (cursore del dettaglio nel tema Apple)
            if !originale.obiettivi.isEmpty { originale.obiettivi[0].versamentoMensile = 350 }
            guard !originale.simulazioni.isEmpty, !originale.incontri.isEmpty, !originale.prodotti.isEmpty, !originale.obiettivi.isEmpty, !originale.documenti.isEmpty, !originale.valutazioni.isEmpty, originale.clienti.contains(where: { !$0.bisogni.eventi.isEmpty }) else {
                print("ERRORE: i dati di prova non hanno scenari del simulatore")
                return 1
            }
            try Archivio.codificatore.encode(originale).write(to: dati.appendingPathComponent("archivio.json"))
            try Data("documento di prova".utf8).write(to: dati.appendingPathComponent("Documenti/prova.txt"))

            // Rotazione: dopo 10 backup ne restano 8
            for i in 0..<10 {
                try GestoreBackup.crea(sorgente: dati, destinazione: backup, nota: "prova \(i)")
            }
            let elenco = GestoreBackup.elenca(backup)
            guard elenco.count == GestoreBackup.massimo else {
                print("ERRORE: rotazione, attesi \(GestoreBackup.massimo) backup, trovati \(elenco.count)")
                return 1
            }

            // Le copie automatiche hanno la loro rotazione: non le consumano i backup fatti a mano
            // (una sola copia: due backup nello stesso secondo hanno lo stesso nome)
            try GestoreBackup.crea(sorgente: dati, destinazione: backup, nota: GestoreBackup.notaAutomatico)
            let conAutomatici = GestoreBackup.elenca(backup)
            guard conAutomatici.filter(GestoreBackup.automatico).count == 1, conAutomatici.count == GestoreBackup.massimo + 1 else {
                print("ERRORE: rotazione separata dei backup automatici (\(conAutomatici.count) copie)")
                return 1
            }
            // Una cartella scelta dall'utente che non c'è (disco scollegato) non si ricrea sul Mac
            let scollegata = radice.appendingPathComponent("DiscoEsterno/Backup", isDirectory: true)
            do {
                try GestoreBackup.crea(sorgente: dati, destinazione: scollegata, creaCartella: false)
                print("ERRORE: backup creato in una cartella che non esisteva")
                return 1
            } catch ErroreBackup.cartellaNonRaggiungibile {
                guard !fm.fileExists(atPath: scollegata.path) else {
                    print("ERRORE: la cartella scollegata è stata ricreata")
                    return 1
                }
            }
            // Un numero non finito non blocca il salvataggio
            var conNaN = originale
            if !conNaN.posizioni.isEmpty { conNaN.posizioni[0].costoAnnuo = .nan }
            guard (try? Archivio.decodifica(Archivio.codificatore.encode(conNaN))) != nil else {
                print("ERRORE: un numero non finito blocca il salvataggio")
                return 1
            }

            // Ripristino: i dati e i documenti tornano identici
            let estratto = try GestoreBackup.estrai(elenco[0].url)
            guard estratto.dati == originale else {
                print("ERRORE: i dati estratti non coincidono con l'originale")
                return 1
            }
            guard estratto.dati.impostazioni.riferimenti.valori.count == 1, estratto.dati.impostazioni.riferimenti.indici.first?.id == "indice-prova",
                  estratto.dati.impostazioni.riferimenti.perMercato == "indice-prova",
                  estratto.dati.posizioni.first(where: { $0.id == "pos-giulia-etf-azionario-globale" })?.riferimento == "indice-prova",
                  estratto.dati.confrontiTFR["marco"]?.contributoDatore == 1.6 else {
                print("ERRORE: riferimenti e confronto del TFR non tornano uguali dal backup")
                return 1
            }
            // Il versamento previsto dell'obiettivo torna dal backup; un obiettivo di prima (senza il campo) parte da 0
            let obiettivoVecchio = """
            {"id":"obiettivo-prova","clienteId":"a","titolo":"Casa","area":"casa","importo":40000,
             "scadenza":"2030-06-30T00:00:00Z","accantonato":1000,"posizioniCollegate":[],"rendimento":2}
            """
            guard estratto.dati.obiettivi.first?.versamentoMensile == 350,
                  let obiettivoLetto = try? Archivio.decodificatore.decode(Obiettivo.self, from: Data(obiettivoVecchio.utf8)),
                  obiettivoLetto.versamentoMensile == 0, obiettivoLetto.accantonato == 1000 else {
                print("ERRORE: il versamento previsto dell'obiettivo non torna uguale dal backup")
                return 1
            }
            if let e = try verificaFotografie(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Impostazioni di Studio e novità viste (versione 26), e un archivio della versione 25 senza (ProvaBackupStudio.swift)
            if let e = try verificaStudio(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Parcelle, dati fiscali e raccomandazioni (versione 26, giro 2), e un archivio senza (ProvaBackupParcelle.swift)
            if let e = try verificaParcelle(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Messaggi ai clienti e impostazioni dei messaggi (versione 26, giro 3), e un archivio senza (ProvaBackupMessaggi.swift)
            if let e = try verificaMessaggi(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Il radar del portafoglio (versione 27, «Luce» giro 2), e un archivio senza (ProvaBackupRadar.swift)
            if let e = try verificaRadar(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Le pratiche dopo la firma (versione 27, «Luce» giro 3), e un archivio senza (ProvaBackupPratiche.swift)
            if let e = try verificaPratiche(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // La giornata della pensione e le partite del gioco del rischio (versione 27, «Luce» giro 4) (ProvaBackupSala.swift)
            if let e = try verificaSala(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Le storie e i traguardi festeggiati (versione 27, «Luce» giro 5), e un archivio senza (ProvaBackupRelazione.swift)
            if let e = try verificaRelazione(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Eventi della linea della vita e risparmio libero (versione 26, giro 4), e un archivio senza (ProvaBackupLineaVita.swift)
            if let e = try verificaEventiVita(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Consenso all'ascolto e sessioni del copilota (versione 26, giro 5), e un archivio senza (ProvaBackupCopilota.swift)
            if let e = try verificaCopilota(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Prisma ovunque (versione 26, giro 8), e un archivio senza (ProvaBackupOvunque.swift)
            if let e = try verificaOvunque(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Tabelle delle famiglie e allenamento OCF (versione 26, giro 6), e un archivio senza (ProvaBackupFamiglieOCF.swift)
            if let e = try verificaFamiglieOCF(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // «Luce», giro 1 (versione 27): spazi con le app nuove e un'app sconosciuta letta con tolleranza (ProvaBackupLuce.swift)
            if let e = try verificaLuce(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Mercato (versione 26, giro 7), e un archivio senza (ProvaBackupMercato.swift)
            if let e = try verificaMercato(originale: originale, estratto: estratto.dati) {
                print("ERRORE: \(e)")
                return 1
            }
            // Multiramo a due parti (versione 20): i campi nuovi della posizione, della scheda prodotto (che ha le
            // CodingKeys scritte a mano: un campo che manca lì non si salverebbe) e delle parti delle condizioni
            guard let m = estratto.dati.posizioni.first(where: { $0.id == "pos-marco-polizza-multiramo" }),
                  m.rendimentoGestione == 3.0, m.costoParteFondi == 2.3, m.sriFondi == 4, m.volatilitaFondi == 14,
                  m.quotaAzionariaFondi == 58, m.multiramoDivisa else {
                print("ERRORE: la multiramo a due parti non torna uguale dal backup")
                return 1
            }
            // Versione 25: i fondi uno per uno, con quota e rendimento, e la loro media ponderata (5,5%)
            guard let fondi = m.fondi, fondi.count == 2, fondi.map(\.id) == ["fondo-marco-azionario", "fondo-marco-flessibile"],
                  fondi.map(\.quota) == [30, 30], fondi.map(\.rendimento) == [6.5, 4.5], fondi[0].nome == "Azionario globale",
                  abs(m.lordoFondi() - 5.5) < 1e-9 else {
                print("ERRORE: i fondi della multiramo non tornano uguali dal backup")
                return 1
            }
            guard let scheda = estratto.dati.prodotti.first(where: { $0.id == "prodotto-multiramo" }),
                  scheda.quotaGestioneMinima == 30, scheda.quotaGestioneMassima == 70, scheda.titoliStatoFondi == 10,
                  scheda.ribilanciamento == false, scheda.consolidamento == true, scheda.sriFondi == 4 else {
                print("ERRORE: la scheda multiramo a due parti non torna uguale dal backup")
                return 1
            }
            let orizzonte = estratto.dati.prodotti.first(where: { $0.id == "prodotto-orizzonte-valore" })
            let fondoInterno = orizzonte?.condizioni?.componenti.first(where: { $0.tipo == .fondoInterno })
            guard fondoInterno?.volatilita == 12, fondoInterno?.quotaAzionaria == 75 else {
                print("ERRORE: i dati di rischio del Fondo Interno non tornano uguali dal backup")
                return 1
            }
            // Giro 3 (versione 21). Completezza: i dati non pertinenti
            guard estratto.dati.clienti.first?.datiNonPertinenti?["lavoro"] != nil else {
                print("ERRORE: i dati non pertinenti della completezza non tornano dal backup")
                return 1
            }
            // Seguito delle proposte: il seguito pieno, i giorni scelti e la proposta rimandata
            let pipGiulia = "pos-giulia-piano-previdenziale-integrativo", pianoAndrea = "pos-andrea-piano-di-risparmio-rivalutabile"
            guard let seguitoEstratto = estratto.dati.posizioni.first(where: { $0.id == pipGiulia })?.seguito,
                  seguitoEstratto == originale.posizioni.first(where: { $0.id == pipGiulia })?.seguito,
                  seguitoEstratto.motivo == .tempi, seguitoEstratto.appuntamentoEsitoId == "event-giulia-previdenza",
                  estratto.dati.impostazioni.giorniSeguitoProposte == 30,
                  estratto.dati.posizioni.first(where: { $0.id == pianoAndrea })?.esito == .rimandata else {
                print("ERRORE: il seguito delle proposte non torna uguale dal backup")
                return 1
            }
            // Orari di lavoro dell'agenda
            guard estratto.dati.impostazioni.orari == originale.impostazioni.orari, estratto.dati.impostazioni.orari.giorni == [2, 3, 4],
                  estratto.dati.impostazioni.orari.margineMinuti == 30, !estratto.dati.impostazioni.orari.pomeriggioAttivo else {
                print("ERRORE: gli orari di lavoro dell'agenda non tornano uguali dal backup")
                return 1
            }
            // «L'acqua della scrivania» spenta torna spenta
            guard !estratto.dati.impostazioni.acquaDellaScrivania else {
                print("ERRORE: «L'acqua della scrivania» spenta non torna spenta dal backup")
                return 1
            }
            // «Riduci movimento» acceso torna acceso
            guard estratto.dati.impostazioni.riduciMovimento else {
                print("ERRORE: «Riduci movimento» acceso non torna acceso dal backup")
                return 1
            }
            // Esperienza per tipo di prodotto (versione 21): griglia e capacità di Giulia identiche dal backup
            guard let g = estratto.dati.clienti.first(where: { $0.id == "giulia" })?.profilo.esperienzaProdotti,
                  g == originale.clienti.first(where: { $0.id == "giulia" })?.profilo.esperienzaProdotti,
                  g.voci.count == 7, g.capacitaPerdite == .limitata, g.voce(.previdenza).conosce == false else {
                print("ERRORE: l'esperienza per tipo di prodotto non torna uguale dal backup")
                return 1
            }
            // Giro 4 (versione 22). Scheda di adeguatezza ed elenco dei documenti da consegnare
            guard let s = estratto.dati.schedeAdeguatezza.first, s.consegne.count == 2, s.firmataIl != nil,
                  s.esitiAllaFirma?.count == 2, s.areaBisogno == .pensione,
                  estratto.dati.impostazioni.consegna.voci.contains(where: { $0.id == "voce-prova" && $0.soloSostituzione }),
                  estratto.dati.impostazioni.consegna.voci.first(where: { $0.id == "all-kid" })?.attiva == false else {
                print("ERRORE: la scheda di adeguatezza o l'elenco dei documenti non tornano uguali dal backup")
                return 1
            }
            // Scadenze di conformità di Giulia e regole
            guard let gc = estratto.dati.clienti.first(where: { $0.id == "giulia" }),
                  gc.conformita?.questionarioAlleanza?.compilatoIl != nil, gc.conformita?.documento?.numero == "CA12345AB",
                  gc.conformita?.verificaIndipendente?.rischio == .basso, gc.consensi.dataMarketing != nil,
                  estratto.dati.impostazioni.conformita.mesiVerificaAlto == 6 else {
                print("ERRORE: le scadenze di conformità non tornano uguali dal backup")
                return 1
            }
            // Calendario delle occasioni
            guard estratto.dati.impostazioni.occasioni == originale.impostazioni.occasioni,
                  estratto.dati.impostazioni.occasioni.tipiSpenti == [.ricorrenzaGestione],
                  !estratto.dati.impostazioni.promemoria.occasioni else {
                print("ERRORE: le impostazioni delle occasioni non tornano uguali dal backup")
                return 1
            }
            // Giro 5 (versione 23). Categoria dei documenti, voci tenute e storico dei dati portati dai documenti
            guard let polizza = estratto.dati.documenti.first(where: { $0.id == "doc-marco-polizza" }), polizza.categoria == .contratto,
                  polizza.vociTenute == ["scadenza|2026-12-01|2026-12-13"],
                  estratto.dati.posizioni.first(where: { $0.id == "pos-marco-polizza-multiramo" })?.variazioni?.first?.valoreDopo?.numero == 4,
                  estratto.dati.posizioni.first(where: { $0.id == "pos-marco-polizza-multiramo" })?.variazioni?.first?.id == "var-prova",
                  estratto.dati.prodotti.first(where: { $0.id == "prodotto-multiramo" })?.variazioni?.first?.fontePrecedente == "Fonte di prima" else {
                print("ERRORE: i dati nuovi dei documenti non tornano uguali dal backup")
                return 1
            }
            try GestoreBackup.sostituisci(cartellaDati: destinazione, con: estratto.cartella)
            let documento = try String(contentsOf: destinazione.appendingPathComponent("Documenti/prova.txt"), encoding: .utf8)
            guard documento == "documento di prova",
                  fm.fileExists(atPath: destinazione.appendingPathComponent("archivio.json").path) else {
                print("ERRORE: dopo il ripristino mancano dei file")
                return 1
            }

            // Un archivio della versione 1 (senza anagrafica estesa, con appuntamenti e attività
            // senza i campi della versione 4) si legge ancora
            let vecchio = """
            {"versione":1,"clienteAttivoId":"a",
             "appuntamenti":[{"id":"e","clienteId":"a","titolo":"Incontro","inizio":"2026-01-02T09:00:00Z",
                              "durataMinuti":45,"luogo":"In studio","note":"","stato":"pianificato"}],
             "attivita":[{"id":"t","clienteId":"a","titolo":"Telefonare","scadenza":"2026-01-03T00:00:00Z",
                          "priorita":"alta","completata":false}],
             "impostazioni":{"nomeUtente":"Dennis","inizialiUtente":"DV","backup":{"automatico":true}},
             "clienti":[{"id":"a","nome":"Cliente Vecchio","iniziali":"CV","tinta":"blu","tema":"","email":"",
                         "telefono":"","preferito":false,"nota":"","creatoIl":"2026-01-01T00:00:00Z"}]}
            """
            let letto = try Archivio.decodifica(Data(vecchio.utf8))
            guard letto.clienti.first?.famiglia.isEmpty == true, letto.clienti.first?.canali.isEmpty == true,
                  letto.appuntamenti.first?.tipo == .altro, letto.appuntamenti.first?.canale == nil,
                  letto.attivita.first?.note == "", letto.attivita.first?.appuntamentoId == nil,
                  letto.simulazioni.isEmpty, letto.analisi.isEmpty, letto.conversazioni.isEmpty,
                  letto.clienti.first?.bisogni == ProfiloBisogni(), letto.incontri.isEmpty, letto.prodotti.isEmpty, letto.obiettivi.isEmpty, letto.documenti.isEmpty, letto.valutazioni.isEmpty, letto.commenti.isEmpty, letto.spazi.isEmpty, letto.note.isEmpty,
                  letto.impostazioni.vera == ImpostazioniVera(), letto.impostazioni.nomeUtente == "Denis",
                  letto.impostazioni.aspetto == .automatico, letto.impostazioni.sfondoAnimato,
                  letto.impostazioni.pioggia == .leggera, letto.impostazioni.ricercheSalvate.isEmpty,
                  letto.impostazioni.orari == OrariLavoro(), letto.impostazioni.giorniSeguitoProposte == Impostazioni.giorniSeguitoPredefiniti,
                  letto.clienti.first?.datiNonPertinenti == nil, letto.clienti.first?.profilo.esperienzaProdotti == nil,
                  letto.schedeAdeguatezza.isEmpty, letto.impostazioni.consegna == ImpostazioniConsegna(),
                  letto.clienti.first?.conformita == nil, letto.clienti.first?.consensi.dataMarketing == nil,
                  letto.impostazioni.conformita == RegoleConformita(), letto.impostazioni.occasioni == ImpostazioniOccasioni(),
                  letto.impostazioni.promemoria.occasioni,
                  letto.impostazioni.riferimenti == RiferimentiRendimento(), letto.confrontiTFR.isEmpty,
                  letto.impostazioni.studio == ImpostazioniStudio(), letto.impostazioni.novitaViste == nil,
                  letto.messaggi.isEmpty, letto.impostazioni.messaggi == ImpostazioniMessaggi(),
                  letto.impostazioni.acquaDellaScrivania, !letto.impostazioni.riduciMovimento else {
                print("ERRORE: archivio della versione 1 non letto correttamente")
                return 1
            }
            // Un archivio (o un backup) della versione di oggi salvato prima di «L'acqua della scrivania»: senza il campo
            // si apre lo stesso, con l'acqua accesa, e tutto il resto uguale
            guard let senzaAcqua = try ProvaBackup.senzaCampo("acquaDellaScrivania", in: Archivio.codificatore.encode(originale)) else {
                print("ERRORE: archivio di prova senza «L'acqua della scrivania» non preparato")
                return 1
            }
            let lettoSenzaAcqua = try Archivio.decodifica(senzaAcqua)
            // Atteso: lo stesso archivio passato per codifica e lettura (date al secondo come nel JSON), con l'acqua accesa
            var attesoSenzaAcqua = try Archivio.decodifica(Archivio.codificatore.encode(originale))
            attesoSenzaAcqua.impostazioni.acquaDellaScrivania = true
            guard lettoSenzaAcqua.impostazioni.acquaDellaScrivania, lettoSenzaAcqua.impostazioni == attesoSenzaAcqua.impostazioni,
                  lettoSenzaAcqua.clienti.count == originale.clienti.count, lettoSenzaAcqua.versione == originale.versione else {
                print("ERRORE: archivio senza «L'acqua della scrivania» non letto correttamente (atteso: acqua accesa)")
                return 1
            }
            // Lo stesso per «Riduci movimento»: un archivio (o un backup) di prima, senza il campo, si apre con il movimento
            // normale e tutto il resto uguale
            guard let senzaCalma = try ProvaBackup.senzaCampo("riduciMovimento", in: Archivio.codificatore.encode(originale)) else {
                print("ERRORE: archivio di prova senza «Riduci movimento» non preparato")
                return 1
            }
            let lettoSenzaCalma = try Archivio.decodifica(senzaCalma)
            var attesoSenzaCalma = try Archivio.decodifica(Archivio.codificatore.encode(originale))
            attesoSenzaCalma.impostazioni.riduciMovimento = false
            guard !lettoSenzaCalma.impostazioni.riduciMovimento, lettoSenzaCalma.impostazioni == attesoSenzaCalma.impostazioni,
                  lettoSenzaCalma.clienti.count == originale.clienti.count, lettoSenzaCalma.versione == originale.versione else {
                print("ERRORE: archivio senza «Riduci movimento» non letto correttamente (atteso: movimento normale)")
                return 1
            }

            // Un ripristino interrotto (Mac spento tra i due spostamenti) si recupera all'avvio
            let interrotto = radice.appendingPathComponent("Interrotto/Prisma", isDirectory: true)
            let (_, precedente) = GestoreBackup.cartelleRipristino(interrotto)
            try fm.createDirectory(at: precedente, withIntermediateDirectories: true)
            try Archivio.codificatore.encode(originale).write(to: precedente.appendingPathComponent("archivio.json"))
            guard GestoreBackup.recuperaRipristino(interrotto),
                  fm.fileExists(atPath: interrotto.appendingPathComponent("archivio.json").path),
                  !fm.fileExists(atPath: precedente.path) else {
                print("ERRORE: ripristino interrotto non recuperato")
                return 1
            }
            // Un backup di una versione più recente non si ripristina
            let recente = radice.appendingPathComponent("Recente/Prisma", isDirectory: true)
            try fm.createDirectory(at: recente, withIntermediateDirectories: true)
            var datiRecenti = originale
            datiRecenti.versione = DatiPrisma.versioneAttuale + 1
            try Archivio.codificatore.encode(datiRecenti).write(to: recente.appendingPathComponent("archivio.json"))
            let zipRecente = try GestoreBackup.crea(sorgente: recente, destinazione: radice.appendingPathComponent("BackupRecenti"))
            do {
                _ = try GestoreBackup.estrai(zipRecente)
                print("ERRORE: ripristinato un backup di una versione più recente")
                return 1
            } catch ErroreBackup.versionePiuRecente {}

            // Un archivio di una versione più recente si apre in sola lettura (salvarlo perderebbe dati)
            var futuro = originale
            futuro.versione = DatiPrisma.versioneAttuale + 1
            let rilettoFuturo = try Archivio.decodifica(Archivio.codificatore.encode(futuro))
            guard Archivio.diVersionePiuRecente(rilettoFuturo), !Archivio.diVersionePiuRecente(originale) else {
                print("ERRORE: archivio di una versione più recente non riconosciuto")
                return 1
            }

            // Togliere i clienti di prova lascia i clienti veri con i loro dati
            let stato = StatoShell(persistente: false)
            var vero = Cliente.nuovo(tinta: .blu)
            vero.nome = "Cliente Vero"
            stato.dati.clienti.append(vero)
            stato.dati.posizioni.append(Posizione(clienteId: vero.id, canale: .indipendente, stato: .inEssere, area: .liquidita, nome: "Conto"))
            stato.salvaCommento(.checkUp(report: true), testo: "Gentile Giulia, prova.")
            stato.rimuoviDatiDiProva()
            guard stato.dati.clienti.map(\.id) == [vero.id], stato.dati.posizioni.allSatisfy({ $0.clienteId == vero.id }), stato.dati.posizioni.count == 1,
                  stato.dati.commenti.isEmpty, stato.dati.conversazioni.isEmpty, stato.dati.documenti.isEmpty, stato.dati.obiettivi.isEmpty,
                  stato.dati.prodotti.isEmpty, stato.dati.clienteAttivoId == vero.id, !stato.haDatiDiProva else {
                print("ERRORE: togliendo i clienti di prova sono rimasti dati di prova o è sparito il cliente vero")
                return 1
            }

            // Un file che non è un backup di Prisma viene rifiutato
            let estraneo = radice.appendingPathComponent("estraneo.zip")
            try Data("non sono uno zip".utf8).write(to: estraneo)
            if (try? GestoreBackup.estrai(estraneo)) != nil {
                print("ERRORE: un file non valido è stato accettato come backup")
                return 1
            }

            // Backup protetti da password (la prova non usa mai il Portachiavi: la password si passa qui)
            if let errore = try provaProtetti(radice: radice, dati: dati, originale: originale) {
                print("ERRORE: \(errore)")
                return 1
            }
            // Salvataggio in background: una modifica in coda e un ripristino subito dopo
            if let errore = try provaSalvataggio(radice: radice, originale: originale) {
                print("ERRORE: \(errore)")
                return 1
            }
            // Lettore e scrittore zip (iPhone e iPad), sul Mac anche contro ditto (ProvaBackupZip.swift)
            if let errore = try provaZip(radice: radice) {
                print("ERRORE: \(errore)")
                return 1
            }
            // Archivio e backup di prima del cambio di nome (Eve → Vera) si aprono interi (ProvaBackupNomeVecchio.swift)
            if let errore = try provaNomeVecchio(radice: radice) {
                print("ERRORE: \(errore)")
                return 1
            }
            print("OK: backup, rotazione (\(elenco.count) copie), ripristino, backup protetti da password, salvataggio in background, lettore zip e archivi col vecchio nome di Vera verificati")
            return 0
        } catch {
            print("ERRORE: \(error.localizedDescription)")
            return 1
        }
    }

    /// Backup protetti: cifrati (niente in chiaro, nemmeno i nomi dei file), chiusi senza la password
    /// giusta, rifiutati se alterati, troncati o riordinati, a più segmenti; rotazione insieme ai .zip
    /// in chiaro, che si ripristinano come prima. Restituisce il motivo dell'errore (nil = tutto bene).
    private static func provaProtetti(radice: URL, dati: URL, originale: DatiPrisma) throws -> String? {
        let fm = FileManager.default
        let password = "prova-segreta-àè"
        // Un documento più grande di due segmenti (byte pseudocasuali: lo zip non li comprime)
        var grande = [UInt8](repeating: 0, count: CifraturaBackup.dimensioneSegmento * 5 / 2)
        var x: UInt64 = 0x9E37_79B9_7F4A_7C15
        for i in grande.indices {
            x ^= x << 13
            x ^= x >> 7
            x ^= x << 17
            grande[i] = UInt8(truncatingIfNeeded: x)
        }
        let fileGrande = dati.appendingPathComponent("Documenti/grande.bin")
        try Data(grande).write(to: fileGrande)
        defer { try? fm.removeItem(at: fileGrande) }

        // Con le iterazioni dell'app: cifrato, nessun file in chiaro lasciato in giro
        let protetti = radice.appendingPathComponent("BackupProtetti", isDirectory: true)
        try fm.createDirectory(at: protetti, withIntermediateDirectories: true)
        // Una copia parziale rimasta da un backup protetto interrotto si cancella
        try Data("resto".utf8).write(to: protetti.appendingPathComponent(GestoreBackup.prefisso + "interrotto.zip.cifrato.parziale"))
        let primaTemporanei = temporaneiInChiaro()
        let cifrato = try GestoreBackup.crea(sorgente: dati, destinazione: protetti, password: password)
        let contenuto = try Data(contentsOf: cifrato)
        let nomi = (try? fm.contentsOfDirectory(atPath: protetti.path)) ?? []
        guard cifrato.lastPathComponent.hasSuffix(".zip." + GestoreBackup.estensioneCifrata), CifraturaBackup.cifrato(cifrato),
              CifraturaBackup.iterazioni(in: cifrato) == CifraturaBackup.iterazioniPredefinite,
              contenuto.range(of: Data("archivio.json".utf8)) == nil, contenuto.range(of: Data("prova.txt".utf8)) == nil,
              nomi == [cifrato.lastPathComponent], temporaneiInChiaro() == primaTemporanei else {
            return "il backup protetto non è cifrato o ha lasciato file in chiaro (\(nomi))"
        }
        let voci = GestoreBackup.elenca(protetti)
        guard voci.count == 1, voci[0].cifrato, !voci[0].nome.hasSuffix(".zip"), !voci[0].nome.hasSuffix(".cifrato") else {
            return "elenco dei backup protetti (\(voci.map(\.nome)))"
        }
        // Senza password e con la password sbagliata non si apre
        do {
            _ = try GestoreBackup.estrai(cifrato)
            return "un backup protetto si è aperto senza password"
        } catch ErroreBackup.serveLaPassword {}
        do {
            _ = try GestoreBackup.estrai(cifrato, password: "sbagliata")
            return "un backup protetto si è aperto con la password sbagliata"
        } catch ErroreBackup.passwordErrata {}
        // Con la password giusta torna identico, documenti compresi
        let aperto = try GestoreBackup.estrai(cifrato, password: password)
        defer { GestoreBackup.pulisciEstrazione(aperto.cartella) }
        let grandeRiletto = try Data(contentsOf: aperto.cartella.appendingPathComponent("Documenti/grande.bin"))
        let documento = try String(contentsOf: aperto.cartella.appendingPathComponent("Documenti/prova.txt"), encoding: .utf8)
        guard aperto.dati == originale, grandeRiletto == Data(grande), documento == "documento di prova",
              temporaneiInChiaro() == primaTemporanei else {
            return "il backup protetto non torna identico o lascia lo zip decifrato nella cartella temporanea"
        }
        // Riconosciuto dal contenuto, non dall'estensione: rinominato in .zip chiede ancora la password
        let rinominato = radice.appendingPathComponent("rinominato.zip")
        try fm.copyItem(at: cifrato, to: rinominato)
        do {
            _ = try GestoreBackup.estrai(rinominato)
            return "un backup protetto rinominato in .zip si è aperto senza password"
        } catch ErroreBackup.serveLaPassword {}
        // Una password vuota non protegge niente: niente backup
        do {
            try GestoreBackup.crea(sorgente: dati, destinazione: radice.appendingPathComponent("PasswordVuota"), password: "")
            return "backup creato con una password vuota"
        } catch ErroreBackup.passwordNonDisponibile {}

        // Le prove sui file rovinati con poche iterazioni (solo qui, per la durata)
        let veloci = radice.appendingPathComponent("BackupProtettiVeloci", isDirectory: true)
        let veloce = try GestoreBackup.crea(sorgente: dati, destinazione: veloci, password: password, iterazioni: 1_000)
        // La stessa password scritta con gli accenti scomposti apre lo stesso backup
        let scomposta = try GestoreBackup.estrai(veloce, password: password.decomposedStringWithCanonicalMapping)
        GestoreBackup.pulisciEstrazione(scomposta.cartella)
        let intero = try [UInt8](Data(contentsOf: veloce))
        let pezzi = segmenti(intero)
        guard pezzi.count >= 3, pezzi.last?.upperBound == intero.count else {
            return "attesi almeno 3 segmenti, trovati \(pezzi.count)"
        }
        let rovinati = radice.appendingPathComponent("Rovinati", isDirectory: true)
        try fm.createDirectory(at: rovinati, withIntermediateDirectories: true)
        let intestazione = Array(intero[0..<CifraturaBackup.lunghezzaIntestazione])
        var alterato = intero
        alterato[pezzi[1].lowerBound + 100] ^= 0xFF
        let troncatoAlConfine = Array(intero[0..<pezzi[pezzi.count - 1].lowerBound])
        let troncato = Array(intero.dropLast(100))
        var riordinato = intestazione
        riordinato.append(contentsOf: intero[pezzi[1]])
        riordinato.append(contentsOf: intero[pezzi[0]])
        riordinato.append(contentsOf: intero[pezzi[1].upperBound...])
        var allungato = intero
        allungato.append(contentsOf: intero[pezzi[pezzi.count - 1]])
        let casi: [(String, [UInt8])] = [("un byte alterato", alterato), ("troncato tra due segmenti", troncatoAlConfine),
                                         ("troncato a metà", troncato), ("con i segmenti riordinati", riordinato),
                                         ("con un segmento in più", allungato)]
        for (i, caso) in casi.enumerated() {
            guard rifiutato(Data(caso.1), rovinati.appendingPathComponent("rovinato \(i).zip.cifrato"), password: password,
                            atteso: { errore in
                                if case .backupDanneggiato = errore { return true }
                                return false
                            }) else {
                return "accettato un backup protetto \(caso.0)"
            }
        }
        // Un'intestazione toccata (il sale) non apre più niente
        var saleToccato = intero
        saleToccato[20] ^= 0x01
        guard rifiutato(Data(saleToccato), rovinati.appendingPathComponent("sale.zip.cifrato"), password: password, atteso: { _ in true }) else {
            return "accettato un backup protetto con l'intestazione alterata"
        }
        guard temporaneiInChiaro() == primaTemporanei else { return "i backup rovinati lasciano zip decifrati nella cartella temporanea" }

        // Rotazione: .zip e .zip.cifrato si contano insieme; l'automatico protetto si riconosce
        let misti = radice.appendingPathComponent("BackupMisti", isDirectory: true)
        for i in 0..<10 {
            try GestoreBackup.crea(sorgente: dati, destinazione: misti, nota: "misto \(i)",
                                   password: i.isMultiple(of: 2) ? password : nil, iterazioni: 1_000)
        }
        try GestoreBackup.crea(sorgente: dati, destinazione: misti, nota: GestoreBackup.notaAutomatico, password: password, iterazioni: 1_000)
        let elencoMisto = GestoreBackup.elenca(misti)
        let automatici = elencoMisto.filter(GestoreBackup.automatico)
        let fileMisti = (try? fm.contentsOfDirectory(atPath: misti.path)) ?? []
        let vecchi = elencoMisto.filter { $0.nome.hasSuffix("(misto 0)") || $0.nome.hasSuffix("(misto 1)") }
        guard elencoMisto.count == GestoreBackup.massimo + 1, fileMisti.count == elencoMisto.count,
              automatici.count == 1, automatici.first?.cifrato == true,
              elencoMisto.contains(where: { $0.cifrato }), elencoMisto.contains(where: { !$0.cifrato }), vecchi.isEmpty else {
            return "rotazione mista di backup in chiaro e protetti (\(fileMisti.sorted()))"
        }
        // Un vecchio .zip in chiaro si ripristina come prima, anche se c'è una password
        guard let inChiaro = elencoMisto.first(where: { !$0.cifrato }) else { return "manca il backup in chiaro" }
        let daChiaro = try GestoreBackup.estrai(inChiaro.url, password: password)
        GestoreBackup.pulisciEstrazione(daChiaro.cartella)
        guard daChiaro.dati == originale else { return "un backup in chiaro non torna identico" }

        // L'impostazione «protetto» si legge con tolleranza: gli archivi di prima non l'hanno
        let senzaCampo = try Archivio.decodificatore.decode(ImpostazioniBackup.self, from: Data(#"{"automatico":true}"#.utf8))
        let conCampo = try Archivio.decodificatore.decode(ImpostazioniBackup.self, from: Data(#"{"automatico":true,"protetto":true}"#.utf8))
        let riletta = try Archivio.decodificatore.decode(ImpostazioniBackup.self, from: Archivio.codificatore.encode(conCampo))
        guard !senzaCampo.cifrato, conCampo.cifrato, riletta == conCampo else {
            return "impostazione della protezione dei backup non letta o non salvata"
        }
        return nil
    }

    /// Salvataggio in background (SalvataggioArchivio, come in StatoShell): la scrittura accodata arriva sul
    /// disco prima che il backup o il ripristino lo leggano (`attendi`, come `salvaOra`); una generazione già
    /// scritta (il salvataggio ritardato che arriva dopo il ripristino) non sovrascrive l'archivio ripristinato.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    private static func provaSalvataggio(radice: URL, originale: DatiPrisma) throws -> String? {
        let cartella = radice.appendingPathComponent("Salvataggio/Prisma", isDirectory: true)
        let file = cartella.appendingPathComponent("archivio.json")
        let salvataggio = SalvataggioArchivio(file: file, coda: DispatchQueue(label: "prisma.prova-salvataggio", qos: .utility))
        func letto() -> DatiPrisma? { (try? Data(contentsOf: file)).flatMap { try? Archivio.decodifica($0) } }

        // Generazione 1: i dati di partenza, scritti in background
        guard salvataggio.accoda(originale, generazione: 1, fallito: { _ in }) else { return "salvataggio: la prima scrittura non è partita" }
        salvataggio.attendi()
        guard letto() == originale else { return "salvataggio: dopo l'attesa l'archivio sul disco non è quello salvato" }
        // La stessa generazione non si riscrive
        guard !salvataggio.accoda(originale, generazione: 1, fallito: { _ in }) else { return "salvataggio: dati non cambiati scritti di nuovo" }
        let zip = try GestoreBackup.crea(sorgente: cartella, destinazione: radice.appendingPathComponent("BackupSalvataggio"))

        // Generazione 2: una modifica in coda, poi il ripristino del backup di prima
        var modificato = originale
        modificato.impostazioni.nomeUtente = "Modificato in coda"
        salvataggio.accoda(modificato, generazione: 2, fallito: { _ in })
        // Il ripristino (e il backup) aspettano la coda: la modifica è sul disco e non arriverà dopo
        salvataggio.attendi()
        guard letto() == modificato else { return "salvataggio: la modifica in coda non era sul disco prima del ripristino" }
        let estratto = try GestoreBackup.estrai(zip)
        try GestoreBackup.sostituisci(cartellaDati: cartella, con: estratto.cartella)
        // Il salvataggio ritardato della stessa modifica arriva dopo il ripristino: non scrive nulla
        guard !salvataggio.accoda(modificato, generazione: 2, fallito: { _ in }) else {
            return "salvataggio: una modifica già salvata riscritta sopra il ripristino"
        }
        salvataggio.attendi()
        guard letto() == originale else { return "salvataggio: l'archivio ripristinato è stato sovrascritto" }
        return nil
    }

    /// I file dello zip in chiaro o decifrato che Prisma crea nella cartella temporanea.
    private static func temporaneiInChiaro() -> Set<String> {
        let fm = FileManager.default
        let nomi = (try? fm.contentsOfDirectory(atPath: fm.temporaryDirectory.path)) ?? []
        return Set(nomi.filter { $0.hasPrefix("Prisma-chiaro-") || $0.hasPrefix("Prisma-decifrato-") })
    }

    /// Dove stanno i segmenti (lunghezza compresa) di un backup protetto.
    private static func segmenti(_ file: [UInt8]) -> [Range<Int>] {
        var inizio = CifraturaBackup.lunghezzaIntestazione
        var pezzi: [Range<Int>] = []
        while inizio + 4 <= file.count {
            let lunghezza = Int(CifraturaBackup.numero(file[inizio..<inizio + 4]))
            let fine = inizio + 4 + lunghezza
            guard fine <= file.count else { break }
            pezzi.append(inizio..<fine)
            inizio = fine
        }
        return pezzi
    }

    /// true se il backup protetto `contenuto` viene rifiutato con l'errore atteso.
    private static func rifiutato(_ contenuto: Data, _ url: URL, password: String, atteso: (ErroreBackup) -> Bool) -> Bool {
        do {
            try contenuto.write(to: url)
            let aperto = try GestoreBackup.estrai(url, password: password)
            GestoreBackup.pulisciEstrazione(aperto.cartella)
            return false
        } catch let errore as ErroreBackup {
            return atteso(errore)
        } catch {
            return false
        }
    }
}
