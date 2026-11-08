import Foundation

// Proprietario: G3 (calcoli nei body).

/// Dati ricavati dall'archivio e tenuti da parte finché non cambiano i dati dei calcoli (`versioneCalcoli`: una
/// nota, Vera, l'aspetto o il cliente attivo non contano), il giorno o la modalità cliente: una classe, così si
/// aggiorna dai getter senza pubblicare StatoShell. Ogni voce si calcola alla prima richiesta dopo un
/// cambiamento, non tutte insieme. Si usa solo dal thread principale.
final class DerivatiDati {
    /// Il radar del portafoglio (Posizioni › Radar): con Observation la vista lo chiede a ogni rivalutazione.
    var radar: RadarPortafoglio?
    /// La copia dell'archivio per i motori che vogliono tutto `DatiPrisma` (StatoShell.datiDeiCalcoli).
    var datiCalcoli: DatiPrisma?
    /// I conteggi per area della colonna di Posizioni, per vista (cliente o portafoglio), canale e stato.
    var contiAree: [String: ContiAree] = [:]

    struct ContiAree {
        let totale: Int
        let perArea: [AreaPosizione: Int]
    }
    /// Ciò da cui dipende tutto il resto: con una chiave nuova si riparte da zero.
    struct Chiave: Equatable {
        let versione: Int
        let giorno: Date
        let modo: String?
    }

    /// Il riesame dipende anche dal confronto aperto in Prospetti e dall'orizzonte della sostituzione (fonte di Vera).
    struct ChiaveRiesame: Equatable {
        let prospetto: SceltaProspetto?
        let orizzonte: Int?
        let ora: Int
    }

    struct ChiavePortafoglio: Equatable {
        let canale: Canale?
        let area: AreaPosizione?
        let ora: Int
    }

    /// Tutto ciò che cambia un documento di Prospetti oltre ai dati dei calcoli, al giorno e alla modalità cliente.
    struct ChiaveDocumento: Equatable {
        let scelta: SceltaProspetto
        /// Le note del taccuino (`versioneNote`): le legge il fascicolo dell'incontro.
        let note: Int
        let prospetto: SceltaProspetto?
        let cliente: String
        let orizzonteConfronto: Int?
        let orizzonteSostituzione: Int?
        let fascicolo: Set<TipoProspetto>
        let appuntamento: String?
        let ora: Int
    }

    /// Le parti del Portafoglio che non dipendono dai filtri di canale e area.
    struct PortafoglioComune {
        let daRicontattare: [Portafoglio.DaRicontattare]
        let dovuti: [RiesameDovuto]
        let fine: [FineAnno]
        let attenzioni: [Attenzione]
    }

    /// I riesami del mese dell'Agenda: il mese mostrato (il suo primo giorno), il filtro cliente e l'ora del calcolo.
    struct ChiaveRiesamiMese: Hashable {
        let mese: Date
        let filtro: String?
        let ora: Int
    }

    /// I giorni mostrati dall'Agenda (mese, settimana o giorno): il primo e l'ultimo, il filtro cliente e lo strato
    /// delle occasioni. Non dipendono dall'ora: solo dai dati dei calcoli.
    struct ChiaveGiorniAgenda: Hashable {
        let inizio: Date
        let fine: Date
        let filtro: String?
        let occasioni: Bool
    }

    /// Quante voci tengono al massimo le cache dell'Agenda per mese e per intervallo (si svuotano oltre).
    static let vociMassimeAgenda = 12

    /// L'ora corrente come numero intero: i calcoli che guardano «adesso» (prossimo appuntamento, riesami
    /// dovuti) si rifanno almeno una volta all'ora anche se i dati non cambiano.
    static func ora(_ data: Date = Date()) -> Int { Int(data.timeIntervalSinceReferenceDate / 3600) }

    // Le voci si leggono e si scrivono solo dalle estensioni di StatoShell (G3)
    var chiave: Chiave?
    /// Il giorno della chiave, da `inizioGiorno` (compreso) a `fineGiorno` (escluso): finché `Date()` ci sta dentro
    /// non serve rifare `startOfDay` a ogni getter. `.distantPast` = da ricalcolare (cambio di giorno o di fuso).
    var inizioGiorno: Date = .distantPast
    var fineGiorno: Date = .distantPast
    /// L'ultima `ChiaveVista`, valida nell'intervallo dato (l'ora intera dentro il giorno).
    var vista: (chiave: ChiaveVista, da: Date, scade: Date)?
    var clientiPerId: [String: Cliente]?
    var posizioniPerCliente: [String: [Posizione]]?
    var prossimi: [Appuntamento]?
    var diOggi: [Appuntamento]?
    var aperte: [Attivita]?
    var riepilogoTutte: RiepilogoPosizioni?
    var chiaveRiesami: ChiaveRiesame?
    var riesami: [String: Riesame?] = [:]
    /// La memoria del riesame (fotografie e variazioni), per cliente (StatoMemoriaRiesame.swift).
    var memorie: [String: MemoriaRiesame] = [:]
    var portafoglioComune: (ora: Int, valore: PortafoglioComune)?
    /// I riesami dovuti di tutti i clienti visibili, con l'ora del calcolo: li chiedono il Portafoglio e la mossa del giorno.
    var dovuti: (ora: Int, valore: [RiesameDovuto])?
    var portafoglio: (chiave: ChiavePortafoglio, valore: Portafoglio)?
    var documento: (chiave: ChiaveDocumento, valore: DocumentoStampabile?)?
    /// Le proposte ferme, con l'ora del calcolo (StatoSeguito.swift).
    var seguito: (ora: Int, valore: [PropostaInSospeso])?
    /// Le occasioni per intervallo di date e filtro (AgendaOccasioni.swift).
    var occasioni: [ChiaveOccasioni: [Occasione]] = [:]
    /// Le scadenze di conformità di tutti i clienti visibili, per il centro notifiche (Notifiche.swift).
    var conformitaClienti: [EsitoConformita]?
    /// I clienti che possono ancora dedurre a fine anno, per il centro notifiche (Notifiche.swift).
    var deducibiliFineAnno: [FineAnno]?
    /// La mossa del giorno della scrivania, con l'ora del calcolo (StatoMossaDelGiorno.swift).
    var mossaDelGiorno: (ora: Int, valore: EsitoMossaDelGiorno)?
    /// Il nastro «Da fare» del portafoglio di Posizioni, con l'ora del calcolo (StatoPortafoglioApple.swift).
    var nastroDaFare: (ora: Int, valore: NastroDaFare)?
    /// L'andamento del portafoglio di tutti i clienti visibili, con l'ora del calcolo (StatoPortafoglioApple.swift).
    var andamentoPortafoglio: (ora: Int, valore: AndamentoPortafoglio)?
    /// I tre anelli del Portafoglio clienti della scrivania, con l'ora del calcolo (StatoScrivania.swift).
    var statoDelLavoro: (ora: Int, valore: StatoDelLavoro)?
    /// I riesami del mese della striscia dell'Agenda (RiesamiAgenda.swift): il body dell'Agenda li chiede a ogni disegno.
    var riesamiMese: [ChiaveRiesamiMese: RiesamiDelMese] = [:]
    /// Impegni, scadenze, occasioni e attività per giorno dell'Agenda (StatoShell.giorniAgenda), per intervallo.
    var indiciAgenda: [ChiaveGiorniAgenda: GiorniAgenda] = [:]
    // Le voci dei singoli clienti (riepilogo, dossier, coerenza, fisco, conformità, completezza, bisogni, prima stesura
    // dell'Analisi 360, andamento, aree di Analisi 360, attenzioni, radar) stanno in CacheClienti, per cliente.
    /// Il cruscotto di Studio di oggi (StatoStudio.swift): dipende solo dai dati dei calcoli, dal giorno e dalla modalità cliente.
    var cruscottoStudio: CruscottoStudio?
    /// Il track record di Studio di oggi (StatoTrackRecord.swift): stesse dipendenze del cruscotto.
    var trackRecord: TrackRecord?
    /// Le occasioni dei messaggi di oggi (StatoMessaggi.swift): dipendono dai dati dei calcoli (messaggi compresi) e dal giorno.
    var occasioniMessaggi: OccasioniMessaggi?
    /// Il numero dell'ultima impaginazione del documento di Prospetti: cambia solo quando il documento si
    /// impagina di nuovo, quindi dice alle pagine sul tavolo se sono ancora le stesse. Non si azzera con la
    /// chiave e viene da un contatore comune a tutti gli stati, così due documenti non hanno mai lo stesso numero.
    private(set) var generazioneDocumento = 0
    nonisolated(unsafe) private static var ultimaGenerazione = 0

    /// Un documento impaginato adesso: prende un numero nuovo.
    func nuovaGenerazioneDocumento() {
        DerivatiDati.ultimaGenerazione &+= 1
        generazioneDocumento = DerivatiDati.ultimaGenerazione
    }

    /// Dati dei calcoli, giorno o modalità cliente cambiati: si dimentica tutto (non il numero del documento).
    func azzera(_ nuova: Chiave) {
        chiave = nuova
        clientiPerId = nil
        posizioniPerCliente = nil
        prossimi = nil
        diOggi = nil
        aperte = nil
        riepilogoTutte = nil
        chiaveRiesami = nil
        riesami = [:]
        memorie = [:]
        portafoglioComune = nil
        dovuti = nil
        portafoglio = nil
        documento = nil
        seguito = nil
        occasioni = [:]
        conformitaClienti = nil
        deducibiliFineAnno = nil
        mossaDelGiorno = nil
        nastroDaFare = nil
        andamentoPortafoglio = nil
        statoDelLavoro = nil
        riesamiMese = [:]
        indiciAgenda = [:]
        vista = nil
        cruscottoStudio = nil
        trackRecord = nil
        occasioniMessaggi = nil
        radar = nil
        datiCalcoli = nil
        contiAree = [:]
    }
}

extension StatoShell {
    /// I dati ricavati validi per lo stato di adesso (azzerati se i dati dei calcoli, il giorno o la modalità
    /// cliente sono cambiati).
    func derivatiValidi() -> DerivatiDati {
        // Iscrive la vista che chiede dati ricavati al giorno e all'ora: le cache giornaliere e orarie (prossimi
        // appuntamenti, appuntamenti di oggi, portafoglio…) si rileggono allo scoccare dell'ora e a mezzanotte
        _ = orologioVista
        let adesso = Date()
        // La via breve: stessa versione e modalità, e siamo ancora nello stesso giorno (due confronti, niente calendario)
        if let k = derivati.chiave, k.versione == versioneCalcoli, k.modo == modoCliente,
           adesso >= derivati.inizioGiorno, adesso < derivati.fineGiorno {
            return derivati
        }
        let calendario = Calendar.current
        let giorno = calendario.startOfDay(for: adesso)
        let k = DerivatiDati.Chiave(versione: versioneCalcoli, giorno: giorno, modo: modoCliente)
        if derivati.chiave != k { derivati.azzera(k) }
        derivati.inizioGiorno = giorno
        derivati.fineGiorno = calendario.date(byAdding: .day, value: 1, to: giorno) ?? adesso
        return derivati
    }

    /// L'archivio per i motori che chiedono tutto `DatiPrisma`, letto una volta per `versioneCalcoli`, giorno e modalità
    /// cliente e **senza iscrivere la vista a tutti i campi** (giro 0, tappa 2): chi lo chiede in un body si aggiorna solo
    /// con `versioneCalcoli` (e l'ora, come ogni dato ricavato). Valgono solo i campi dei calcoli (`DatiPrisma.stessiCalcoli`):
    /// note, conversazioni, spazi, pratiche, allenamento OCF, schede di adeguatezza, confronti del TFR, cliente attivo e le
    /// impostazioni che non toccano i calcoli possono essere vecchi. Chi ne ha bisogno li legge dai dati vivi e li rimette
    /// nella copia (così si iscrive solo a quelli), come `statiPratiche` e `traguardi`.
    func datiDeiCalcoli() -> DatiPrisma {
        let d = derivatiValidi()
        if let x = d.datiCalcoli { return x }
        let x = dati.istantaneaNonOsservata
        d.datiCalcoli = x
        return x
    }

    /// Il radar del portafoglio: una voce per cliente dalla cache per cliente (CacheClienti), il quadro in cache per
    /// `versioneCalcoli` e giorno. Legge solo clienti, posizioni, prodotti, portafogli modello e la tolleranza del radar,
    /// tutti campi «dei calcoli»: la vista del radar non legge l'archivio intero.
    /// Con molti clienti da rifare insieme, nell'app vera, le voci si calcolano in sottofondo e intanto si mostra
    /// l'ultimo radar (CacheClienti.arrivi ridisegna la vista quando arrivano).
    func radarPortafoglio() -> RadarPortafoglio {
        _ = cacheClienti.arrivi
        let d = derivatiValidi()
        if let r = d.radar { return r }
        let (r, completo) = radarDaiClienti(sottofondo: persistente || cacheClienti.sottofondoPerProva)
        if completo { d.radar = r }
        cacheClienti.ultimoRadar = r
        return r
    }

    /// Quante posizioni per area mostra la colonna di Posizioni (del cliente attivo o di tutto il portafoglio), con il
    /// filtro di canale e di stato (nil = tutte), una volta per dati, giorno e modalità cliente.
    func contiAreePosizioni(portafoglio: Bool, canale: Canale?, stato filtro: StatoPosizione?) -> DerivatiDati.ContiAree {
        let d = derivatiValidi()
        let cliente = portafoglio ? "*" : clienteAttivoId
        let k = "\(cliente)|\(canale?.rawValue ?? "-")|\(filtro.map { "\($0)" } ?? "-")"
        if let c = d.contiAree[k] { return c }
        let base = portafoglio ? posizioni : posizioniCliente(clienteAttivoId)
        var perArea: [AreaPosizione: Int] = [:]
        var totale = 0
        for p in base where (canale == nil || p.canale == canale) && (filtro == nil || p.stato == filtro) {
            perArea[p.area, default: 0] += 1
            totale += 1
        }
        let c = DerivatiDati.ContiAree(totale: totale, perArea: perArea)
        if d.contiAree.count > DerivatiDati.vociMassimeAgenda { d.contiAree = [:] }
        d.contiAree[k] = c
        return c
    }

    /// Cambio di giorno, d'orario o di fuso: la prossima richiesta rifà il giorno delle chiavi.
    func riverificaGiornoDerivati() {
        derivati.inizioGiorno = .distantPast
        derivati.fineGiorno = .distantPast
        derivati.vista = nil
        // Il giorno nuovo arriva anche alle viste (derivati non è osservato, orologioVista sì)
        aggiornaOrologioVista()
    }

    /// Il cliente con questo id tra quelli visibili (in modalità cliente solo il suo): ricerca in un dizionario.
    func cliente(_ id: String) -> Cliente? {
        let d = derivatiValidi()
        if let mappa = d.clientiPerId { return mappa[id] }
        // Con due clienti con lo stesso id vale il primo, come con `first(where:)`
        let mappa = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        d.clientiPerId = mappa
        return mappa[id]
    }

    /// Lo stesso di `cliente(_:)`, per chi cerca un cliente per id fuori dalle viste (notifiche).
    func clientePerId(_ id: String) -> Cliente? { cliente(id) }

    var prossimiAppuntamenti: [Appuntamento] {
        let d = derivatiValidi()
        if let elenco = d.prossimi { return elenco }
        let inizio = Calendar.current.startOfDay(for: Date())
        let elenco = appuntamenti
            // I blocchi «Non disponibile» (Vera, «liberami…») non sono incontri con un cliente
            .filter { $0.inizio >= inizio && $0.stato == .pianificato && $0.tipo != .nonDisponibile }
            .sorted { $0.inizio < $1.inizio }
        d.prossimi = elenco
        return elenco
    }

    var appuntamentiDiOggi: [Appuntamento] {
        let d = derivatiValidi()
        if let elenco = d.diOggi { return elenco }
        let elenco = appuntamenti.filter { Calendar.current.isDateInToday($0.inizio) && $0.stato == .pianificato }
        d.diOggi = elenco
        return elenco
    }

    var attivitaAperte: [Attivita] {
        let d = derivatiValidi()
        if let elenco = d.aperte { return elenco }
        let elenco = attivita.filter { !$0.completata }.sorted { $0.scadenza < $1.scadenza }
        d.aperte = elenco
        return elenco
    }

    /// Le posizioni di un cliente, dall'archivio intero (anche fuori dalla modalità cliente).
    func posizioniCliente(_ id: String) -> [Posizione] {
        let d = derivatiValidi()
        if let gruppi = d.posizioniPerCliente { return gruppi[id] ?? [] }
        let gruppi = Dictionary(grouping: dati.posizioni, by: \.clienteId)
        d.posizioniPerCliente = gruppi
        return gruppi[id] ?? []
    }

    /// Il quadro di tutte le posizioni visibili (widget Scadenze e Portafoglio clienti).
    var riepilogoTuttePosizioni: RiepilogoPosizioni {
        let d = derivatiValidi()
        if let r = d.riepilogoTutte { return r }
        let r = RiepilogoPosizioni(posizioni)
        d.riepilogoTutte = r
        return r
    }

    /// Il quadro delle posizioni di un cliente (widget del cliente in primo piano).
    func riepilogoPosizioniCliente(_ id: String) -> RiepilogoPosizioni {
        let v = voceCliente(id)
        if let r = v.riepilogo { return r }
        let r = RiepilogoPosizioni(posizioniCliente(id))
        v.riepilogo = r
        return r
    }

    /// La coerenza con il profilo delle posizioni del cliente (pannello del dossier e dettaglio delle proposte).
    func coerenzaCliente(_ c: Cliente) -> EsitoCoerenza {
        let v = voceCliente(c.id)
        if let e = v.coerenza { return e }
        let e = MotoreCoerenza.calcola(cliente: c, posizioni: posizioniCliente(c.id), prodotti: dati.prodotti)
        v.coerenza = e
        return e
    }

    /// Il fisco delle polizze di un cliente (Analisi 360): detrazioni, capitali al decesso, bollo, deducibilità.
    func fiscoPolizze(_ c: Cliente) -> FiscoPolizzeCliente {
        let v = voceCliente(c.id)
        if let f = v.fisco { return f }
        let f = FiscoPolizze.riepilogo(cliente: c, posizioni: posizioniCliente(c.id))
        v.fisco = f
        return f
    }

    /// Il riesame annuale di un cliente (nil se il cliente non c'è): passa da tutta la fonte di Vera,
    /// quindi si calcola una volta sola per dati, ora, confronto aperto e orizzonte della sostituzione.
    func riesameCliente(_ id: String) -> Riesame? {
        let d = derivatiValidi()
        let k = DerivatiDati.ChiaveRiesame(prospetto: prospetto, orizzonte: orizzonteSostituzione, ora: DerivatiDati.ora())
        if d.chiaveRiesami != k {
            d.chiaveRiesami = k
            d.riesami = [:]
        }
        if let memorizzato = d.riesami[id] { return memorizzato }
        let r = fonteVera(id).map { MotoreRiesame.calcola($0, conformita: conformitaCliente(id), occasioni: occasioniRiesame(id)) }
        d.riesami[id] = .some(r)
        return r
    }

    /// Le cifre delle aree di Analisi 360 di un cliente (griglia e dettagli), una volta sola per dati dei calcoli, giorno,
    /// ora e modalità cliente (come `ChiaveVista`). La cache sta qui e non nella finestra: chiudere e riaprire
    /// Analisi 360 non rifà i motori.
    func aree360(_ id: String) -> AreeAnalisi360 {
        let voce = voceCliente(id)
        let ora = DerivatiDati.ora()
        if let c = voce.aree360, c.ora == ora { return c.valore }
        let v = MotoreAree360.calcola(cliente: cliente(id), posizioni: posizioniCliente(id),
                                      analisi: analisi360(id), obiettivi: obiettiviCliente(id),
                                      prodotti: dati.prodotti)
        voce.aree360 = (ora, v)
        return v
    }

    /// Ciò che il Portafoglio di Posizioni mostra di tutti i clienti, a prescindere dai filtri: chi ricontattare,
    /// i riesami dovuti, lo spazio deducibile di fine anno e le cose da sistemare nei dossier.
    func portafoglioComune() -> DerivatiDati.PortafoglioComune {
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.portafoglioComune, c.ora == ora { return c.valore }
        let v = DerivatiDati.PortafoglioComune(
            daRicontattare: MotorePortafoglio.daRicontattare(posizioni, clienti: clienti, appuntamenti: appuntamenti, incontri: dati.incontri),
            dovuti: riesamiDovuti(),
            fine: MotoreFineAnno.conSpazio(clienti: clienti, posizioni: posizioni),
            attenzioni: attenzioniDaiClienti())
        d.portafoglioComune = (ora, v)
        return v
    }

    /// I riesami dovuti di tutti i clienti visibili, una volta all'ora (Portafoglio, nastro e mossa del giorno).
    func riesamiDovuti() -> [RiesameDovuto] {
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.dovuti, c.ora == ora { return c.valore }
        let v = MotoreRiesame.dovuti(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: dati.incontri)
        d.dovuti = (ora, v)
        return v
    }

    /// Il portafoglio di tutti i clienti con i filtri di canale e area (chi ricontattare non dipende dai filtri).
    func riepilogoPortafoglio(canale: Canale?, area: AreaPosizione?) -> Portafoglio {
        let d = derivatiValidi()
        let k = DerivatiDati.ChiavePortafoglio(canale: canale, area: area, ora: DerivatiDati.ora())
        if let c = d.portafoglio, c.chiave == k { return c.valore }
        let filtrate = posizioni.filter { (canale == nil || $0.canale == canale) && (area == nil || $0.area == area) }
        var p = MotorePortafoglio.calcola(filtrate, clienti: clienti, appuntamenti: appuntamenti, incontri: dati.incontri)
        p.daRicontattare = portafoglioComune().daRicontattare
        d.portafoglio = (k, p)
        return p
    }

    /// Il documento di Prospetti per una scelta, impaginato una volta sola finché non cambia qualcosa che conta
    /// (dati, note, cliente, orizzonti, fascicolo, giorno, ora): il body di Prospetti lo chiede a ogni disegno.
    func documentoProspettoInCache(_ scelta: SceltaProspetto) -> DocumentoStampabile? {
        let d = derivatiValidi()
        let k = DerivatiDati.ChiaveDocumento(scelta: scelta, note: versioneNote, prospetto: prospetto, cliente: clienteAttivoId,
                                             orizzonteConfronto: orizzonteConfronto, orizzonteSostituzione: orizzonteSostituzione,
                                             fascicolo: sceltaFascicolo, appuntamento: fascicoloAppuntamento, ora: DerivatiDati.ora())
        if let c = d.documento, c.chiave == k { return c.valore }
        let documento = documentoProspetto(scelta)
        d.documento = (k, documento)
        d.nuovaGenerazioneDocumento()
        return documento
    }

    /// Il numero dell'impaginazione del documento di Prospetti restituito per ultimo da
    /// `documentoProspettoInCache` (lo stesso finché il documento viene dalla cache).
    var generazioneDocumento: Int { derivati.generazioneDocumento }

    /// La chiave delle viste che mostrano dati ricavati, per le sottoviste `Equatable` che non osservano StatoShell.
    var chiaveVista: ChiaveVista {
        // Iscrive chi legge la chiave al giorno e all'ora (osservati), oltre a versioneCalcoli e modoCliente
        _ = orologioVista
        let adesso = Date()
        if let v = derivati.vista, v.chiave.calcoli == versioneCalcoli, v.chiave.modo == modoCliente,
           adesso >= v.da, adesso < v.scade {
            return v.chiave
        }
        let calendario = Calendar.current
        let giorno = calendario.startOfDay(for: adesso)
        let ora = DerivatiDati.ora(adesso)
        let k = ChiaveVista(calcoli: versioneCalcoli, giorno: giorno, ora: ora, modo: modoCliente)
        // Valida fino alla fine dell'ora intera, e mai oltre la fine del giorno
        let inizioOra = Date(timeIntervalSinceReferenceDate: Double(ora) * 3600)
        let fineOra = Date(timeIntervalSinceReferenceDate: Double(ora + 1) * 3600)
        let fineGiorno = calendario.date(byAdding: .day, value: 1, to: giorno) ?? fineOra
        derivati.vista = (k, max(giorno, inizioOra), min(fineOra, fineGiorno))
        return k
    }
}

/// Il giorno (inizio, nel fuso di adesso) e l'ora intera come `DerivatiDati.ora`: il valore osservato di
/// `StatoShell.orologioVista`, che cambia allo scoccare dell'ora, a mezzanotte e con un altro fuso.
struct OrologioVista: Equatable {
    let giorno: Date
    let ora: Int

    static func di(_ data: Date) -> OrologioVista {
        OrologioVista(giorno: Calendar.current.startOfDay(for: data), ora: DerivatiDati.ora(data))
    }
}

/// Ciò da cui dipendono le viste che mostrano dati ricavati: la chiave delle sottoviste `Equatable` che non
/// osservano StatoShell (versione dei calcoli, giorno, ora intera come `DerivatiDati.ora`, modalità cliente).
/// Con la stessa chiave le cache di DerivatiDati danno gli stessi valori, quindi la vista è la stessa.
struct ChiaveVista: Equatable {
    let calcoli: Int
    let giorno: Date
    let ora: Int
    let modo: String?
}

extension DatiPrisma {
    /// Uguali in tutto ciò che entra nei calcoli e nei documenti. Non contano le note del taccuino (hanno la loro
    /// versione), le conversazioni con Vera, gli spazi di lavoro, il cliente attivo (le cache sono per cliente) e
    /// le impostazioni che cambiano solo l'aspetto, Vera, il backup e i promemoria. Gli array e i dizionari non
    /// toccati condividono la memoria con quelli di prima e si confrontano in O(1).
    func stessiCalcoli(di altro: DatiPrisma) -> Bool {
        var a = self
        var b = altro
        a.note = []
        b.note = []
        a.conversazioni = [:]
        b.conversazioni = [:]
        a.spazi = []
        b.spazi = []
        b.clienteAttivoId = a.clienteAttivoId
        b.impostazioni.aspetto = a.impostazioni.aspetto
        b.impostazioni.sfondoAnimato = a.impostazioni.sfondoAnimato
        b.impostazioni.pioggia = a.impostazioni.pioggia
        b.impostazioni.acquaDellaScrivania = a.impostazioni.acquaDellaScrivania
        b.impostazioni.riduciMovimento = a.impostazioni.riduciMovimento
        b.impostazioni.guidaNascosta = a.impostazioni.guidaNascosta
        b.impostazioni.introduzioneVista = a.impostazioni.introduzioneVista
        b.impostazioni.backup = a.impostazioni.backup
        b.impostazioni.promemoria = a.impostazioni.promemoria
        b.impostazioni.vera = a.impostazioni.vera
        // Le novità viste aprono solo il pannello «Novità»: le impostazioni di Studio invece entrano nei calcoli
        b.impostazioni.novitaViste = a.impostazioni.novitaViste
        // Le schede di adeguatezza e l'elenco dei documenti da consegnare non entrano in nessun calcolo in cache
        a.schedeAdeguatezza = []; b.schedeAdeguatezza = []
        b.impostazioni.consegna = a.impostazioni.consegna
        // Il confronto «TFR in azienda o nel fondo» si calcola nella vista, senza cache
        a.confrontiTFR = [:]; b.confrontiTFR = [:]
        // L'allenamento OCF (giro 6) non entra in nessun calcolo in cache: una risposta non rifà le cache dei clienti
        b.ocf = a.ocf
        // Le pratiche dopo la firma («Luce» giro 3) si calcolano nella vista e nelle notifiche, senza cache: segnare un
        // passo non rifà le cache dei clienti
        a.pratiche = []; b.pratiche = []
        b.impostazioni.pratiche = a.impostazioni.pratiche
        // Chilometri, spese e scadenze («Luce» giro 9) si calcolano nella vista, senza cache
        b.speseStudio = a.speseStudio
        b.kmClienti = a.kmClienti
        b.impostazioni.studio.spese = a.impostazioni.studio.spese
        return a == b
    }
}
