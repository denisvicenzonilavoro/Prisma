import Foundation

/// Tutto ciò che Prisma salva nell'archivio locale (archivio.json).
struct DatiPrisma: Codable, Equatable {
    /// Versione del formato, per le migrazioni future.
    var versione = DatiPrisma.versioneAttuale
    var clienti: [Cliente]
    var appuntamenti: [Appuntamento]
    var attivita: [Attivita]
    var posizioni: [Posizione] = []
    var simulazioni: [Simulazione] = []
    /// Analisi 360 salvate, per cliente (chi non ce l'ha la vede ricavata dalle posizioni).
    var analisi: [String: Analisi360] = [:]
    var incontri: [Incontro] = []
    /// Catalogo delle schede prodotto (di tutti i clienti).
    var prodotti: [Prodotto] = []
    var obiettivi: [Obiettivo] = []
    var documenti: [Documento] = []
    /// Valutazioni d'investimento (prospetto e report di riscatto).
    var valutazioni: [ValutazioneInvestimento] = []
    /// Conversazioni con Vera, per cliente.
    var conversazioni: [String: [MessaggioVera]] = [:]
    /// Commenti del consulente nei report per i clienti.
    var commenti: [CommentoReport] = []
    /// Note del taccuino, legate ai clienti.
    var note: [Nota] = []
    /// Spazi di lavoro salvati dal consulente (quelli pronti di Prisma non si salvano).
    var spazi: [SpazioLavoro] = []
    /// Fotografie delle cifre chiave salvate a ogni riesame, di tutti i clienti (dalla versione 24).
    var fotografie: [FotografiaRiesame] = []
    /// Schede di adeguatezza delle proposte (dalla versione 22 dell'archivio).
    var schedeAdeguatezza: [SchedaAdeguatezza] = []
    /// Ipotesi del confronto «TFR in azienda o nel fondo», per cliente (dalla versione 24).
    var confrontiTFR: [String: IpotesiTFR] = [:]
    /// Parcelle della consulenza indipendente (Studio › Parcelle e fatture, dalla versione 26).
    var parcelle: [Parcella] = []
    /// Il registro delle raccomandazioni per il track record (Studio › Track record, dalla versione 26). Immutabile:
    /// si aggiungono solo raccomandazioni, note e scelte del cliente (StatoTrackRecord.swift).
    var raccomandazioni: [Raccomandazione] = []
    /// I messaggi preparati per i clienti (Messaggi, «Prisma scrive per te», dalla versione 26): restano nel dossier
    /// del cliente con la data, il tono, il canale e le cifre usate. Prisma non spedisce niente da solo.
    var messaggi: [MessaggioCliente] = []
    /// Gli eventi della linea della vita dei clienti (Clienti › Dossier › La linea della vita, versione 26, giro 4):
    /// matrimonio, casa, figli, eredità… con età, importo e durata, per cliente (`EventoLineaVita.clienteId`).
    var eventiVita: [EventoLineaVita] = []
    /// Le sessioni d'ascolto del copilota dell'incontro (Incontri › Copilota, versione 26, giro 5): data, cliente,
    /// schede riconosciute con lo stato, verbale e attività create. La trascrizione (solo testo, mai audio) si scrive
    /// solo se il consulente sceglie «Conserva la trascrizione» (`SessioneCopilota.encode`).
    var sessioniCopilota: [SessioneCopilota] = []
    /// Prisma ovunque (versione 26, giro 8, Design/ovunque-fattibilita.md §4): sui dispositivi, le operazioni del giornale
    /// non ancora confermate dal Mac (si salvano insieme alla modifica che le ha prodotte). Sul Mac resta vuoto.
    var giornaleOvunque: [OperazioneOvunque] = []
    /// Sul Mac, i conflitti arrivati dai dispositivi in attesa di una scelta («Da decidere»): finché non si sceglie vale
    /// il valore del Mac.
    var conflittiOvunque: [ConflittoOvunque] = []
    /// Sul Mac, le cose create sui dispositivi e già unite («Arrivato da iPhone»), le più recenti in fondo.
    var arriviOvunque: [ArrivoOvunque] = []
    /// Le posizioni inquadrate sull'iPhone e arrivate con il giornale: bozze da confermare sul Mac (calcoli e canale li
    /// decide il Mac), mai posizioni definitive.
    var inquadratureDaConfermare: [InquadraturaPonte] = []
    /// Mercato, «Prisma conosce il mercato» (versione 26, giro 7): serie scaricate da BCE ed Eurostat (solo con
    /// «Dati di mercato» acceso) o importate, quote per ISIN con data e fonte, avvisi con lo stato (nuovo, visto).
    var mercato = ArchivioMercato()
    /// Le tabelle delle famiglie italiane caricate dal consulente da Impostazioni (Analisi 360 › «Rispetto alle
    /// famiglie come la sua», versione 26, giro 6): prevalgono sulle tavole della Banca d'Italia incluse nell'app
    /// (`TabelleFamiglie.tabellePredefinite`). nil = tavole incluse.
    var famiglie: FamiglieCaricate?
    /// L'allenamento per l'esame OCF (Studio › Esame OCF, versione 26, giro 6): materie, domande, storico delle
    /// risposte e data dell'esame. Le domande le importa il consulente; Prisma ne ha solo poche di esempio.
    var ocf = ArchivioOCF()
    /// I portafogli modello del radar (Posizioni › Radar, versione 27, «Luce» giro 2): li scrive l'utente in
    /// Impostazioni › Portafogli modello. Vuoto finché non ne scrive uno.
    var portafogliModello: [PortafoglioModello] = []
    /// Le pratiche dopo la firma (Pratiche › Dopo la firma, versione 27, «Luce» giro 3): nascono dalle proposte
    /// accettate; dentro ci sono solo i segni a mano, le note e il sollecito (i passi riconosciuti li calcola
    /// MotorePratiche).
    var pratiche: [Pratica] = []
    /// Le partite del gioco del rischio (Sala, versione 27, «Luce» giro 4): solo quelle salvate con «Salva nel
    /// dossier» (decisione 52). Non cambiano mai la propensione del cliente e non entrano in «Prisma ovunque».
    var partiteRischio: [PartitaRischio] = []
    /// Vera, fase 3 (Vera/BRIEF.md): le promesse ai clienti con la loro frase (8), i confronti tra due documenti salvati
    /// nella scheda (11) e le coperture lette dalle polizze (12). Versione 27, campi letti con tolleranza.
    var promesse: [PromessaCliente] = []
    var confrontiDocumenti: [ConfrontoDocumenti] = []
    var coperture: [CoperturaPolizza] = []
    /// Studio › Spese («Luce» giro 9, versione 27, SpeseStudio.swift): le spese con gli scontrini, le scadenze e i corsi di
    /// aggiornamento del consulente, scritti da lui, e le visite concluse dei clienti eliminati (senza nome né testi, per i
    /// km dei mesi già chiusi). Restano sul Mac: non entrano in «Prisma ovunque».
    var speseStudio = ArchivioSpese()
    /// I km di andata e ritorno fra la partenza del consulente e ogni cliente (clienteId → km), scritti dall'utente per
    /// Studio › Spese (versione 27, «Luce» giro 9). Un dato del cliente: sta nel suo file della cartella a pezzi e se ne va
    /// con lui. Resta sul Mac: non entra in «Prisma ovunque».
    var kmClienti: [String: Double] = [:]
    var clienteAttivoId: String
    var impostazioni: Impostazioni

    /// 2: anagrafica completa, nucleo familiare, profilo e consensi dei clienti.
    /// 3: posizioni in essere e in proposta.
    /// 4: tipo, canale e posizione degli appuntamenti; note e appuntamento collegato delle attività.
    /// 5: scenari del simulatore e Analisi 360 dei clienti.
    /// 6: conversazioni e impostazioni di Vera.
    /// 7: profilo dei bisogni dei clienti (mappa, eventi di vita, bisogni rilevati confermati).
    /// 8: incontri (preparazione, ascolto, appunti, decisioni, prossimi passi).
    /// 9: schede prodotto e obiettivi dei clienti.
    /// 10: documenti dei clienti con i dati estratti.
    /// 11: condizioni dei contratti nelle schede prodotto e valutazioni d'investimento.
    /// 12: rilevazioni dei valori delle posizioni (storico per il resoconto).
    /// 13: trattenuto sul rendimento e dati fiscali delle posizioni (regime, titoli di Stato, bollo, previdenza).
    /// 14: reddito lordo annuo nel profilo del cliente (previdenza e deducibilità).
    /// 15: commenti del consulente nei report (scritti con Vera).
    /// 16: quota in gestione separata delle polizze multiramo; impostazioni di backup con l'ultimo errore.
    /// 17: spazi di lavoro salvati.
    /// 18: note del taccuino.
    /// 19: data del valore e totale versato tra i dati letti dai documenti (estratti conto).
    /// 20: multiramo a due parti (rendimento, costi e rischio della gestione separata e dei fondi, ribilanciamento) nelle posizioni e nelle schede prodotto; dati di rischio delle parti nelle condizioni.
    /// 21: seguito delle proposte (esito «rimandata», giorni del seguito); dati non pertinenti per la completezza; orari di lavoro dell'agenda; esperienza per tipo di prodotto e capacità di sostenere perdite.
    /// 22: schede di adeguatezza delle proposte e documenti da consegnare per canale; scadenze di conformità dei clienti e regole di validità; impostazioni del calendario delle occasioni e promemoria delle occasioni.
    /// 23: categoria dei documenti e dati letti nuovi (ISIN, data del documento, rendimento prima dei costi, documenti
    ///     d'identità e questionari); confronto dei documenti con il dossier: voci lasciate come in Prisma e storico dei
    ///     dati aggiornati nelle posizioni e nelle schede prodotto.
    /// 24: metri di confronto dei rendimenti (valori annui, indici e scelte nelle impostazioni; metro scelto nella posizione) e confronto «TFR in azienda o nel fondo» per cliente; fotografie dei riesami (cifre chiave datate per cliente).
    /// 25: multiramo con il rendimento di ogni fondo (`Posizione.fondi`) e la scelta esplicita (`sceltaMultiramo`); ipotesi del TFR riviste (campi facoltativi).
    /// 26: «Orizzonte»: impostazioni di Studio (aliquote provvigionali Alleanza per tipo di prodotto, obiettivi dell'anno
    ///     del consulente, `Impostazioni.studio`) e ultima versione delle novità vista (`Impostazioni.novitaViste`);
    ///     parcelle (`parcelle`), dati fiscali del consulente (`Impostazioni.studio.fatturazione`) e del cliente
    ///     (`Cliente.fiscale`), registro delle raccomandazioni (`raccomandazioni`); messaggi ai clienti (`messaggi`) e
    ///     impostazioni dei messaggi (`Impostazioni.messaggi`, giro 3); eventi della linea della vita (`eventiVita`) e
    ///     risparmio annuo libero nel profilo (`ProfiloInvestitore.risparmioAnnuo`, giro 4); consenso all'ascolto del copilota
    ///     (`Cliente.consensoCopilota`) e sessioni del copilota (`sessioniCopilota`, giro 5); tabelle delle famiglie
    ///     caricate (`famiglie`) e allenamento per l'esame OCF (`ocf`, giro 6); Mercato: serie, quote per ISIN e
    ///     avvisi (`mercato`), impostazioni di Mercato (`Impostazioni.mercato`), ISIN, numero di quote e cedola
    ///     delle posizioni (`Posizione.isin`, `numeroQuote`, `cedola`, giro 7); Prisma ovunque (giro 8):
    ///     impostazioni dello spazio (`Impostazioni.ovunque`, senza passphrase né chiave), giornale del dispositivo
    ///     (`giornaleOvunque`), conflitti da decidere (`conflittiOvunque`), arrivi dai dispositivi (`arriviOvunque`) e
    ///     posizioni inquadrate da confermare (`inquadratureDaConfermare`). Tutti facoltativi.
    /// 27: «Luce» (Design/template-luce-specifica.md, decisione 103: una sola versione per tutta Luce, campi nuovi letti
    ///     con `decodeIfPresent`). Giro 1: le app nuove Territorio, Pratiche, Sala e Biblioteca negli spazi di lavoro,
    ///     letti con tolleranza (una finestra di un'app che questo Prisma non conosce si salta, uno spazio illeggibile
    ///     non fa perdere gli altri: decisione 104), e le novità viste «luce» (`Impostazioni.novitaViste`). Giro 2: i
    ///     portafogli modello (`portafogliModello`), la tolleranza del radar (`Impostazioni.tolleranzaRadar`), il modello
    ///     di ogni cliente (`Cliente.modelloId`) e il segno delle bozze di riequilibrio (`Posizione.riequilibrio`). Giro 3:
    ///     le pratiche dopo la firma (`pratiche`, lette con tolleranza: una pratica senza id o posizione si scarta) e
    ///     la soglia delle pratiche ferme (`Impostazioni.pratiche`, 7 giorni se manca o è illeggibile). Giro 4: la
    ///     giornata della pensione nell'Analisi 360 (`Analisi360.giornata`, voci lette con tolleranza) e le partite del
    ///     gioco del rischio salvate nel dossier (`partiteRischio`, lette con tolleranza). Giro 5: la storia della
    ///     settimana e dell'anno (`Impostazioni.storie`: apertura del lunedì, settimana e anno visti), i traguardi
    ///     festeggiati (`Impostazioni.traguardi`: tipi spenti, anniversari, festeggiati, scartati) e il giorno in cui un
    ///     obiettivo è stato raggiunto (`Obiettivo.raggiuntoIl`); i messaggi con il tipo nuovo `traguardo` sono letti con
    ///     tolleranza (un Prisma di prima li salta).
    ///     Giro 5 anche: il registro della
    ///     palestra della trattativa (`Impostazioni.palestra`: data, cliente, difficoltà e punteggio, al massimo 50,
    ///     letti con tolleranza; mai le conversazioni).
    ///     Giro 7: le aziende dei clienti imprenditori (`Cliente.aziende`: ragione sociale, forma, partita IVA, settore,
    ///     dipendenti, fatturato e anno, utile, quota e ruolo del cliente, reddito che ne ricava, persona chiave, TFM,
    ///     welfare e passi della continuità), lette con tolleranza (un'azienda senza id o ragione sociale si scarta).
    ///     Giro 10: il luogo di nascita (`Cliente.luogoNascita`) e l'IBAN per l'addebito (`Cliente.iban`, solo con
    ///     `Impostazioni.pratiche.conservaIban` acceso, letto solo se passa il controllo mod 97; mai in «Prisma
    ///     ovunque»), i moduli compilati nei Documenti (`Documento.Tipo.modulo` e `Documento.modulo`:
    ///     `CompilazioneModulo`, un tipo sconosciuto si legge come `.altro`) e i messaggi `datiMancanti` (letti con
    ///     tolleranza). I modelli di modulo non sono nell'archivio: stanno nella cartella `Moduli/` accanto (PDF e
    ///     `moduli.json`), nei backup e mai in «Prisma ovunque».
    ///     Vera, fase 3: le promesse ai
    ///     clienti (`promesse`), i confronti tra documenti (`confrontiDocumenti`), le coperture delle polizze
    ///     (`coperture`) e il resoconto dell'incontro (`Incontro.resoconto`), tutti letti con tolleranza.
    ///     Giro 8 («Sala: racconti senza uscita»): l'inizio del rapporto con il cliente (`Cliente.clienteDal`),
    ///     l'indennizzo stimato per evento delle polizze (`Posizione.indennizzoStimato`) e le impostazioni della Sala
    ///     (`Impostazioni.sala`: eventi di Lancia l'anno con probabilità e fonte, anni della partita, avvertenze e titolo
    ///     del valore approvati), tutti letti con tolleranza. Le lettere dal futuro e le partite di Lancia l'anno non si
    ///     salvano.
    ///     Giro 9: chilometri, spese e scadenze del consulente (`speseStudio`: spese con gli scontrini, scadenze, corsi di
    ///     aggiornamento e le visite tenute dei clienti eliminati `visiteTolte`, letti con tolleranza), le loro impostazioni (`Impostazioni.studio.spese`: partenza,
    ///     correzioni dei giri, ore richieste per anno, nomi nel pacchetto spenti) e dove si
    ///     è svolto un appuntamento (`Appuntamento.presso`: dal cliente, in studio, altrove; nil = da chiedere).
    ///     I km di andata e ritorno per cliente (`kmClienti`), nel file di ogni cliente.
    static let versioneAttuale = 27

    init(clienti: [Cliente], appuntamenti: [Appuntamento], attivita: [Attivita], posizioni: [Posizione],
         simulazioni: [Simulazione] = [], analisi: [String: Analisi360] = [:], incontri: [Incontro] = [],
         prodotti: [Prodotto] = [], obiettivi: [Obiettivo] = [], documenti: [Documento] = [],
         valutazioni: [ValutazioneInvestimento] = [], note: [Nota] = [], clienteAttivoId: String, impostazioni: Impostazioni) {
        self.note = note
        self.incontri = incontri
        self.prodotti = prodotti
        self.obiettivi = obiettivi
        self.documenti = documenti
        self.valutazioni = valutazioni
        self.simulazioni = simulazioni
        self.analisi = analisi
        self.clienti = clienti
        self.appuntamenti = appuntamenti
        self.attivita = attivita
        self.posizioni = posizioni
        self.clienteAttivoId = clienteAttivoId
        self.impostazioni = impostazioni
    }

    static func demo() -> DatiPrisma {
        var d = DatiPrisma(
            clienti: DatiDemo.clienti(),
            appuntamenti: DatiDemo.appuntamenti(),
            attivita: DatiDemo.attivita(),
            posizioni: DatiDemo.posizioni(),
            simulazioni: DatiDemo.simulazioni(),
            incontri: DatiDemo.incontri(),
            prodotti: DatiDemo.prodotti() + [DatiDemo.orizzonteValore()],
            obiettivi: DatiDemo.obiettivi(),
            documenti: DatiDemo.documenti(),
            valutazioni: DatiDemo.valutazioni(),
            note: DatiDemo.note(),
            clienteAttivoId: "giulia",
            impostazioni: Impostazioni()
        )
        // La linea della vita (giro 4): eventi e risparmio libero dei clienti di prova (DatiDemoLineaVita.swift)
        d.eventiVita = DatiDemo.eventiVita()
        DatiDemo.aggiungiRisparmiLiberi(&d.clienti)
        // Il radar del portafoglio («Luce» giro 2): i tre modelli del template, segnati «dati di prova»
        PortafogliModelloDiProva.applica(&d)
        // Le pratiche dopo la firma («Luce» giro 3): le quattro del template, segnate «dati di prova»
        d.pratiche = PraticheDiProva.pratiche()
        // I traguardi festeggiati («Luce» giro 5): Sofia e Giulia, segnati «dati di prova»
        TraguardiDiProva.applica(&d)
        // Chilometri, spese e scadenze («Luce» giro 9): spese, corsi e scadenze non fiscali, segnati «dati di prova»
        SpeseDiProva.applica(&d)
        return d
    }

    /// Le chiavi dell'archivio. Interne (non private) per il formato a pezzi (ArchivioPezzi.swift): ogni chiave ha il suo
    /// posto su disco (`ArchivioPezzi.pezzo`), con uno `switch` completo, così una chiave nuova senza posto non compila.
    enum CodingKeys: String, CodingKey, CaseIterable {
        case versione, clienti, appuntamenti, attivita, posizioni, simulazioni, analisi, incontri, prodotti, obiettivi, documenti, valutazioni, conversazioni, commenti, note, spazi, clienteAttivoId, impostazioni
        case schedeAdeguatezza
        case confrontiTFR, fotografie
        case parcelle, raccomandazioni
        case messaggi
        case eventiVita
        case sessioniCopilota
        case giornaleOvunque, conflittiOvunque, arriviOvunque, inquadratureDaConfermare
        case mercato, famiglie, ocf
        case portafogliModello
        case pratiche
        case partiteRischio
        case promesse, confrontiDocumenti, coperture
        case speseStudio, kmClienti
    }

    /// Lettura tollerante: gli archivi delle versioni precedenti non hanno tutte le sezioni.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versione = try c.decodeIfPresent(Int.self, forKey: .versione) ?? 1
        // Un pezzo del formato a cartella (ArchivioPezzi) ha solo alcune chiavi: i clienti possono mancare. Un archivio
        // intero (archivio.json, l'istantanea di Prisma ovunque) senza clienti resta invece non leggibile, come sempre.
        if decoder.userInfo[ArchivioPezzi.chiavePezzo] as? Bool == true {
            clienti = try c.decodeIfPresent([Cliente].self, forKey: .clienti) ?? []
        } else {
            clienti = try c.decode([Cliente].self, forKey: .clienti)
        }
        appuntamenti = try c.decodeIfPresent([Appuntamento].self, forKey: .appuntamenti) ?? []
        attivita = try c.decodeIfPresent([Attivita].self, forKey: .attivita) ?? []
        posizioni = try c.decodeIfPresent([Posizione].self, forKey: .posizioni) ?? []
        simulazioni = try c.decodeIfPresent([Simulazione].self, forKey: .simulazioni) ?? []
        analisi = try c.decodeIfPresent([String: Analisi360].self, forKey: .analisi) ?? [:]
        incontri = (try? c.decodeIfPresent([Incontro].self, forKey: .incontri)) ?? []
        prodotti = (try? c.decodeIfPresent([Prodotto].self, forKey: .prodotti)) ?? []
        obiettivi = (try? c.decodeIfPresent([Obiettivo].self, forKey: .obiettivi)) ?? []
        documenti = (try? c.decodeIfPresent([Documento].self, forKey: .documenti)) ?? []
        valutazioni = (try? c.decodeIfPresent([ValutazioneInvestimento].self, forKey: .valutazioni)) ?? []
        conversazioni = (try? c.decodeIfPresent([String: [MessaggioVera]].self, forKey: .conversazioni)) ?? [:]
        commenti = (try? c.decodeIfPresent([CommentoReport].self, forKey: .commenti)) ?? []
        // Dalla versione 27 con tolleranza: uno spazio o una finestra illeggibile (un'app di un Prisma più nuovo) si salta
        spazi = (try? c.decodeIfPresent(ElencoTollerante<SpazioLavoro>.self, forKey: .spazi))?.elementi ?? []
        note = (try? c.decodeIfPresent([Nota].self, forKey: .note)) ?? []
        // Fotografie dei riesami (dalla versione 24): una fotografia illeggibile si scarta, le altre restano
        fotografie = (try? c.decodeIfPresent(ElencoTollerante<FotografiaRiesame>.self, forKey: .fotografie))?.elementi ?? []
        // Schede di adeguatezza (dalla versione 22): una scheda illeggibile si scarta, le altre restano
        schedeAdeguatezza = (try? c.decodeIfPresent(ElencoTollerante<SchedaAdeguatezza>.self, forKey: .schedeAdeguatezza))?.elementi ?? []
        // Confronti del TFR (dalla versione 24): gli archivi di prima non li hanno
        confrontiTFR = (try? c.decodeIfPresent([String: IpotesiTFR].self, forKey: .confrontiTFR)) ?? [:]
        // Parcelle e raccomandazioni (dalla versione 26): un elemento illeggibile si scarta, gli altri restano
        parcelle = ((try? c.decodeIfPresent(ElencoTollerante<Parcella>.self, forKey: .parcelle)) ?? nil)?.elementi ?? []
        raccomandazioni = ((try? c.decodeIfPresent(ElencoTollerante<Raccomandazione>.self, forKey: .raccomandazioni)) ?? nil)?.elementi ?? []
        // Messaggi ai clienti (versione 26, giro 3): un messaggio illeggibile si scarta, gli altri restano
        messaggi = ((try? c.decodeIfPresent(ElencoTollerante<MessaggioCliente>.self, forKey: .messaggi)) ?? nil)?.elementi ?? []
        // Eventi della linea della vita (versione 26, giro 4): un evento illeggibile si scarta, gli altri restano
        eventiVita = ((try? c.decodeIfPresent(ElencoTollerante<EventoLineaVita>.self, forKey: .eventiVita)) ?? nil)?.elementi ?? []
        // Sessioni del copilota (versione 26, giro 5): una sessione illeggibile si scarta, le altre restano
        sessioniCopilota = ((try? c.decodeIfPresent(ElencoTollerante<SessioneCopilota>.self, forKey: .sessioniCopilota)) ?? nil)?.elementi ?? []
        // Prisma ovunque (versione 26, giro 8): un elemento illeggibile si scarta, gli altri restano
        giornaleOvunque = ((try? c.decodeIfPresent(ElencoTollerante<OperazioneOvunque>.self, forKey: .giornaleOvunque)) ?? nil)?.elementi ?? []
        conflittiOvunque = ((try? c.decodeIfPresent(ElencoTollerante<ConflittoOvunque>.self, forKey: .conflittiOvunque)) ?? nil)?.elementi ?? []
        arriviOvunque = ((try? c.decodeIfPresent(ElencoTollerante<ArrivoOvunque>.self, forKey: .arriviOvunque)) ?? nil)?.elementi ?? []
        inquadratureDaConfermare = ((try? c.decodeIfPresent(ElencoTollerante<InquadraturaPonte>.self, forKey: .inquadratureDaConfermare)) ?? nil)?.elementi ?? []
        // Mercato (versione 26, giro 7): gli archivi di prima non l'hanno; una sezione illeggibile si apre vuota
        mercato = ((try? c.decodeIfPresent(ArchivioMercato.self, forKey: .mercato)) ?? nil) ?? ArchivioMercato()
        // Tabelle delle famiglie e allenamento OCF (versione 26, giro 6): illeggibili = tavole incluse e archivio OCF vuoto
        famiglie = (try? c.decodeIfPresent(FamiglieCaricate.self, forKey: .famiglie)) ?? nil
        ocf = (try? c.decodeIfPresent(ArchivioOCF.self, forKey: .ocf)) ?? ArchivioOCF()
        // Portafogli modello del radar (versione 27, giro 2): un modello illeggibile si scarta, gli altri restano
        portafogliModello = ((try? c.decodeIfPresent(ElencoTollerante<PortafoglioModello>.self, forKey: .portafogliModello)) ?? nil)?.elementi ?? []
        // Pratiche dopo la firma (versione 27, giro 3): una pratica illeggibile si scarta, le altre restano
        pratiche = ((try? c.decodeIfPresent(ElencoTollerante<Pratica>.self, forKey: .pratiche)) ?? nil)?.elementi ?? []
        // Partite del gioco del rischio (versione 27, giro 4): una partita illeggibile si scarta, le altre restano
        partiteRischio = ((try? c.decodeIfPresent(ElencoTollerante<PartitaRischio>.self, forKey: .partiteRischio)) ?? nil)?.elementi ?? []
        // Vera, fase 3: promesse, confronti tra documenti e coperture delle polizze (versione 27, letti con tolleranza)
        promesse = ((try? c.decodeIfPresent(ElencoTollerante<PromessaCliente>.self, forKey: .promesse)) ?? nil)?.elementi ?? []
        confrontiDocumenti = ((try? c.decodeIfPresent(ElencoTollerante<ConfrontoDocumenti>.self, forKey: .confrontiDocumenti)) ?? nil)?.elementi ?? []
        coperture = ((try? c.decodeIfPresent(ElencoTollerante<CoperturaPolizza>.self, forKey: .coperture)) ?? nil)?.elementi ?? []
        // Chilometri, spese e scadenze (versione 27, giro 9): illeggibili = archivio delle spese vuoto
        speseStudio = ((try? c.decodeIfPresent(ArchivioSpese.self, forKey: .speseStudio)) ?? nil) ?? ArchivioSpese()
        // I km per cliente: un valore negativo o non finito si scarta, gli altri restano
        kmClienti = (((try? c.decodeIfPresent([String: Double].self, forKey: .kmClienti)) ?? nil) ?? [:])
            .filter { $0.value.isFinite && $0.value >= 0 }
        clienteAttivoId = try c.decodeIfPresent(String.self, forKey: .clienteAttivoId) ?? (clienti.first?.id ?? "")
        impostazioni = try c.decodeIfPresent(Impostazioni.self, forKey: .impostazioni) ?? Impostazioni()
    }

    func encode(to encoder: Encoder) throws {
        try codifica(in: encoder, solo: nil)
    }

    /// La scrittura dell'archivio: tutte le chiavi (`solo` nil, come la scrittura sintetizzata di prima: archivio.json,
    /// backup di prima, istantanea di Prisma ovunque) o solo quelle di un pezzo del formato a cartella (ArchivioPezzi).
    func codifica(in encoder: Encoder, solo: Set<CodingKeys>?) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        func metti<T: Encodable>(_ valore: T, _ chiave: CodingKeys) throws {
            if solo?.contains(chiave) ?? true { try c.encode(valore, forKey: chiave) }
        }
        try metti(versione, .versione)
        try metti(clienti, .clienti)
        try metti(appuntamenti, .appuntamenti)
        try metti(attivita, .attivita)
        try metti(posizioni, .posizioni)
        try metti(simulazioni, .simulazioni)
        try metti(analisi, .analisi)
        try metti(incontri, .incontri)
        try metti(prodotti, .prodotti)
        try metti(obiettivi, .obiettivi)
        try metti(documenti, .documenti)
        try metti(valutazioni, .valutazioni)
        try metti(conversazioni, .conversazioni)
        try metti(commenti, .commenti)
        try metti(note, .note)
        try metti(spazi, .spazi)
        try metti(fotografie, .fotografie)
        try metti(schedeAdeguatezza, .schedeAdeguatezza)
        try metti(confrontiTFR, .confrontiTFR)
        try metti(parcelle, .parcelle)
        try metti(raccomandazioni, .raccomandazioni)
        try metti(messaggi, .messaggi)
        try metti(eventiVita, .eventiVita)
        try metti(sessioniCopilota, .sessioniCopilota)
        try metti(giornaleOvunque, .giornaleOvunque)
        try metti(conflittiOvunque, .conflittiOvunque)
        try metti(arriviOvunque, .arriviOvunque)
        try metti(inquadratureDaConfermare, .inquadratureDaConfermare)
        try metti(mercato, .mercato)
        // Come la scrittura sintetizzata: senza tabelle caricate la chiave non c'è
        if let famiglie, solo?.contains(.famiglie) ?? true { try c.encode(famiglie, forKey: .famiglie) }
        try metti(ocf, .ocf)
        try metti(portafogliModello, .portafogliModello)
        try metti(pratiche, .pratiche)
        try metti(partiteRischio, .partiteRischio)
        try metti(promesse, .promesse)
        try metti(confrontiDocumenti, .confrontiDocumenti)
        try metti(coperture, .coperture)
        try metti(speseStudio, .speseStudio)
        try metti(kmClienti, .kmClienti)
        try metti(clienteAttivoId, .clienteAttivoId)
        try metti(impostazioni, .impostazioni)
    }
}

struct Impostazioni: Codable, Equatable {
    var nomeUtente = "Denis"
    var inizialiUtente = "DV"
    var backup = ImpostazioniBackup()
    /// Dalla versione 6 dell'archivio.
    var vera = ImpostazioniVera()
    /// PDF da consegnare ai clienti (letto con tolleranza: gli archivi di prima non l'hanno).
    var pdf = ImpostazioniPDF()
    /// La guida «Comincia con i tuoi dati» nascosta dalla scrivania.
    var guidaNascosta = false
    /// L'introduzione «Come funziona Prisma» è stata vista (dopo il primo sblocco parte da sola finché non lo è).
    var introduzioneVista = false
    /// Dimensione dei testi dell'interfaccia (si applica all'avvio).
    var dimensioneTesto = DimensioneTesto.normale
    /// Aspetto dell'interfaccia: segue il Mac, sempre chiaro o sempre scuro (i PDF restano chiari).
    var aspetto = AspettoInterfaccia.automatico
    /// Lo sfondo d'acqua della scrivania si muove (no = «Sfondo fermo»).
    var sfondoAnimato = true
    /// Quanta pioggia cade sull'acqua della scrivania.
    var pioggia = IntensitaPioggia.leggera
    /// «L'acqua della scrivania» (Impostazioni › Aspetto): l'acqua risponde, con una goccia al clic sul fondo libero, alle
    /// notifiche nuove e allo sblocco, e vibra piano mentre Vera risponde. Acceso di base; letto con tolleranza, senza
    /// alzare la versione: gli archivi e i backup di prima, che non l'hanno, si aprono con l'acqua accesa.
    var acquaDellaScrivania = true
    /// «Riduci movimento» di Prisma (Impostazioni › Aspetto): si somma a quello del sistema. Tutto compare già fermo
    /// con una dissolvenza breve e l'acqua della scrivania si ferma. Spento di base; letto con tolleranza, senza alzare
    /// la versione: gli archivi e i backup di prima, che non l'hanno, si aprono con il movimento normale.
    var riduciMovimento = false
    /// Promemoria nel Centro notifiche del Mac (spenti finché non li accendi).
    var promemoria = ImpostazioniPromemoria()
    /// Le ricerche salvate dal pannello ⌘K (le più recenti prima).
    var ricercheSalvate: [RicercaSalvata] = []
    /// Dopo quanti giorni una proposta presentata, senza appuntamento in agenda, torna tra le cose da recuperare
    /// (dalla versione 21; si sceglie tra `Impostazioni.sceltaGiorniSeguito`).
    var giorniSeguitoProposte = Impostazioni.giorniSeguitoPredefiniti
    /// Orari di lavoro dell'agenda: dove «Pianifica» cerca lo spazio libero (dalla versione 21).
    var orari = OrariLavoro()
    /// Documenti da consegnare prima della firma, per canale (Impostazioni › Proposte). Dalla versione 22.
    var consegna = ImpostazioniConsegna()
    /// Validità delle scadenze di conformità (Impostazioni › Conformità). Dalla versione 22.
    var conformita = RegoleConformita()
    /// Il calendario delle occasioni (dalla versione 22 dell'archivio).
    var occasioni = ImpostazioniOccasioni()
    /// I metri di confronto dei rendimenti: valori annui e indici del consulente, metro di ogni tipo di posizione
    /// (Impostazioni › Riferimenti). Dalla versione 24.
    var riferimenti = RiferimentiRendimento()
    /// Studio: aliquote provvigionali Alleanza per tipo di prodotto e obiettivi dell'anno del consulente
    /// (Impostazioni › Studio). Dalla versione 26; vuote finché il consulente non le scrive.
    var studio = ImpostazioniStudio()
    /// L'ultima versione delle novità vista (per esempio «orizzonte»): il pannello «Novità» si apre da solo una volta
    /// per versione. nil = mai vista. Dalla versione 26; non entra nei calcoli.
    var novitaViste: String?
    /// Messaggi ai clienti: firme per canale e anticipo delle scadenze (Impostazioni › Messaggi). Dalla versione 26
    /// (giro 3), letto con tolleranza: gli archivi di prima si aprono con le firme vuote.
    var messaggi = ImpostazioniMessaggi()
    /// Prisma ovunque: lo spazio cifrato in una cartella di iCloud Drive scelta dall'utente (Impostazioni › iPhone e iPad).
    /// Spento di base. Mai la passphrase né la chiave (stanno nel Portachiavi del dispositivo). Versione 26 (giro 8),
    /// letto con tolleranza: gli archivi di prima si aprono con lo spazio spento.
    var ovunque = ImpostazioniOvunque()
    /// Mercato: l'interruttore «Dati di mercato» (spento di base: senza, Prisma non esce mai su internet), le serie da
    /// scaricare e le soglie degli avvisi, vuote finché l'utente non le sceglie (Impostazioni › Mercato). Dalla
    /// versione 26 (giro 7), letto con tolleranza.
    var mercato = ImpostazioniMercato()
    /// La tolleranza generale del radar del portafoglio, in punti di distanza dal modello (Impostazioni › Portafogli
    /// modello). nil = non ancora scritta: Prisma non ne inventa una, e senza nessun cliente è «fuori». Versione 27.
    var tolleranzaRadar: Double?
    /// Le pratiche dopo la firma: dopo quanti giorni senza un passo nuovo una pratica è ferma (Impostazioni › Pratiche).
    /// Versione 27 («Luce» giro 3), letta con tolleranza: senza, 7 giorni.
    var pratiche = ImpostazioniPratiche()
    /// «La tua settimana, il tuo anno» (versione 27, «Luce» giro 5): l'apertura da sola del lunedì (accesa di base) e
    /// la settimana e l'anno già visti. Letta con tolleranza.
    var storie = ImpostazioniStorie()
    /// I traguardi festeggiati (versione 27, «Luce» giro 5): tipi spenti, anniversari, festeggiati e scartati. Letta
    /// con tolleranza.
    var traguardi = ImpostazioniTraguardi()
    /// La palestra della trattativa (Studio › Palestra): solo data, cliente, difficoltà e punteggio degli allenamenti,
    /// al massimo 50; mai le conversazioni. Versione 27 («Luce» giro 5), letta con tolleranza: senza, nessun allenamento.
    var palestra = ImpostazioniPalestra()
    /// Impostazioni › Sala (versione 27, «Luce» giro 8): gli eventi di Lancia l'anno con probabilità e fonte scritte
    /// dall'utente, gli anni della partita, le avvertenze e il titolo del valore approvati. Letta con tolleranza: senza,
    /// nessun evento a caso e i segnaposto dichiarati.
    var sala = ImpostazioniSala()

    init() {}

    private enum CodingKeys: String, CodingKey {
        // Compatibilità: le impostazioni di Vera restano sotto la chiave «eve» (il vecchio nome) negli archivi e nei backup.
        case nomeUtente, inizialiUtente, backup, vera = "eve", pdf, guidaNascosta, introduzioneVista, dimensioneTesto, aspetto, sfondoAnimato, pioggia
        case promemoria, ricercheSalvate, giorniSeguitoProposte, orari
        case acquaDellaScrivania, riduciMovimento
        case consegna, conformita, occasioni
        case riferimenti
        case studio, novitaViste
        case messaggi
        case ovunque, mercato
        case tolleranzaRadar
        case pratiche
        case storie, traguardi
        case palestra
        case sala
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nomeUtente = try c.decodeIfPresent(String.self, forKey: .nomeUtente) ?? "Denis"
        // Correzione del nome predefinito delle prime versioni ("Dennis")
        if nomeUtente == "Dennis" { nomeUtente = "Denis" }
        inizialiUtente = try c.decodeIfPresent(String.self, forKey: .inizialiUtente) ?? "DV"
        backup = try c.decodeIfPresent(ImpostazioniBackup.self, forKey: .backup) ?? ImpostazioniBackup()
        vera = (try? c.decodeIfPresent(ImpostazioniVera.self, forKey: .vera)) ?? ImpostazioniVera()
        pdf = (try? c.decodeIfPresent(ImpostazioniPDF.self, forKey: .pdf)) ?? ImpostazioniPDF()
        guidaNascosta = (try? c.decodeIfPresent(Bool.self, forKey: .guidaNascosta)) ?? false
        // L'introduzione: gli archivi di prima non la hanno (Denis la vede una volta, poi dal menu Aiuto)
        introduzioneVista = (try? c.decodeIfPresent(Bool.self, forKey: .introduzioneVista)) ?? false
        dimensioneTesto = (try? c.decodeIfPresent(DimensioneTesto.self, forKey: .dimensioneTesto)) ?? .normale
        // Impostazioni del tema: gli archivi di prima non le hanno
        aspetto = (try? c.decodeIfPresent(AspettoInterfaccia.self, forKey: .aspetto)) ?? .automatico
        sfondoAnimato = (try? c.decodeIfPresent(Bool.self, forKey: .sfondoAnimato)) ?? true
        pioggia = (try? c.decodeIfPresent(IntensitaPioggia.self, forKey: .pioggia)) ?? .leggera
        // «L'acqua della scrivania»: gli archivi di prima non l'hanno, l'acqua resta accesa
        acquaDellaScrivania = (try? c.decodeIfPresent(Bool.self, forKey: .acquaDellaScrivania)) ?? true
        // «Riduci movimento» di Prisma: gli archivi di prima non l'hanno, il movimento resta normale
        riduciMovimento = (try? c.decodeIfPresent(Bool.self, forKey: .riduciMovimento)) ?? false
        // Promemoria del Mac: gli archivi di prima non li hanno
        promemoria = (try? c.decodeIfPresent(ImpostazioniPromemoria.self, forKey: .promemoria)) ?? ImpostazioniPromemoria()
        // Ricerche salvate: gli archivi di prima non le hanno
        ricercheSalvate = (try? c.decodeIfPresent([RicercaSalvata].self, forKey: .ricercheSalvate)) ?? []
        // Giorni del seguito delle proposte: gli archivi di prima non li hanno, un valore fuori scelta torna al predefinito
        let giorni = (try? c.decodeIfPresent(Int.self, forKey: .giorniSeguitoProposte)) ?? Impostazioni.giorniSeguitoPredefiniti
        giorniSeguitoProposte = Impostazioni.sceltaGiorniSeguito.contains(giorni) ? giorni : Impostazioni.giorniSeguitoPredefiniti
        // Orari di lavoro: gli archivi di prima non li hanno
        orari = (try? c.decodeIfPresent(OrariLavoro.self, forKey: .orari)) ?? OrariLavoro()
        // Giro 4 (versione 22): gli archivi di prima non hanno documenti da consegnare, regole di conformità e occasioni
        consegna = (try? c.decodeIfPresent(ImpostazioniConsegna.self, forKey: .consegna)) ?? ImpostazioniConsegna()
        conformita = (try? c.decodeIfPresent(RegoleConformita.self, forKey: .conformita)) ?? RegoleConformita()
        occasioni = (try? c.decodeIfPresent(ImpostazioniOccasioni.self, forKey: .occasioni)) ?? ImpostazioniOccasioni()
        // Giro 6 (versione 24): gli archivi di prima non hanno i metri di confronto dei rendimenti
        riferimenti = (try? c.decodeIfPresent(RiferimentiRendimento.self, forKey: .riferimenti)) ?? RiferimentiRendimento()
        // Orizzonte (versione 26): gli archivi di prima non hanno le impostazioni di Studio né le novità viste
        studio = (try? c.decodeIfPresent(ImpostazioniStudio.self, forKey: .studio)) ?? ImpostazioniStudio()
        novitaViste = (try? c.decodeIfPresent(String.self, forKey: .novitaViste)) ?? nil
        // Giro 3 di Orizzonte (sempre versione 26): gli archivi di prima non hanno le impostazioni dei messaggi
        messaggi = (try? c.decodeIfPresent(ImpostazioniMessaggi.self, forKey: .messaggi)) ?? ImpostazioniMessaggi()
        // Giro 8 di Orizzonte (sempre versione 26): gli archivi di prima non hanno Prisma ovunque, lo spazio resta spento
        ovunque = ((try? c.decodeIfPresent(ImpostazioniOvunque.self, forKey: .ovunque)) ?? nil) ?? ImpostazioniOvunque()
        // Giro 7 di Orizzonte (sempre versione 26): gli archivi di prima non hanno Mercato, che resta spento
        mercato = ((try? c.decodeIfPresent(ImpostazioniMercato.self, forKey: .mercato)) ?? nil) ?? ImpostazioniMercato()
        // Tolleranza del radar (versione 27, giro 2): illeggibile o negativa = non scritta
        tolleranzaRadar = ((try? c.decodeIfPresent(Double.self, forKey: .tolleranzaRadar)) ?? nil).flatMap { $0 >= 0 ? $0 : nil }
        // Pratiche (versione 27, giro 3): senza o illeggibili, ferma dopo 7 giorni
        pratiche = ((try? c.decodeIfPresent(ImpostazioniPratiche.self, forKey: .pratiche)) ?? nil) ?? ImpostazioniPratiche()
        // Storie e traguardi (versione 27, giro 5): senza o illeggibili, i valori di base
        storie = ((try? c.decodeIfPresent(ImpostazioniStorie.self, forKey: .storie)) ?? nil) ?? ImpostazioniStorie()
        traguardi = ((try? c.decodeIfPresent(ImpostazioniTraguardi.self, forKey: .traguardi)) ?? nil) ?? ImpostazioniTraguardi()
        // Palestra della trattativa (versione 27, giro 5): senza o illeggibile, nessun allenamento registrato
        palestra = ((try? c.decodeIfPresent(ImpostazioniPalestra.self, forKey: .palestra)) ?? nil) ?? ImpostazioniPalestra()
        // Sala, racconti senza uscita (versione 27, giro 8): senza o illeggibile, nessun evento e i segnaposto
        sala = ((try? c.decodeIfPresent(ImpostazioniSala.self, forKey: .sala)) ?? nil) ?? ImpostazioniSala()
    }
}

/// Aspetto dell'interfaccia (Impostazioni → Aspetto).
enum AspettoInterfaccia: String, Codable, CaseIterable, Identifiable {
    case automatico, chiaro, scuro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .automatico: return "Automatico"
        case .chiaro: return "Chiaro"
        case .scuro: return "Scuro"
        }
    }
}

/// Quanta pioggia cade sull'acqua della scrivania.
enum IntensitaPioggia: String, Codable, CaseIterable, Identifiable {
    case leggera, media, forte

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .leggera: return "Leggera"
        case .media: return "Media"
        case .forte: return "Forte"
        }
    }

    /// Forza della pioggia per lo sfondo animato (come FORZE nel prototipo approvato).
    var forza: Double {
        switch self {
        case .leggera: return 0.14
        case .media: return 0.3
        case .forte: return 0.55
        }
    }
}

/// Quanto si ingrandiscono i testi dell'interfaccia.
enum DimensioneTesto: String, Codable, CaseIterable, Identifiable {
    case normale, grande, moltoGrande

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .normale: return "Normale"
        case .grande: return "Grande"
        case .moltoGrande: return "Molto grande"
        }
    }

    var fattore: CGFloat {
        switch self {
        case .normale: return 1
        case .grande: return 1.12
        case .moltoGrande: return 1.25
        }
    }
}

/// I PDF salvati per i clienti: protezione con password proposta e come si forma la password.
/// Prisma non conserva nessuna password: la ricava dai dati del cliente o la scrivi ogni volta.
struct ImpostazioniPDF: Codable, Equatable {
    enum Regola: String, Codable, CaseIterable, Identifiable {
        case dataNascita, codiceFiscale, aMano

        var id: String { rawValue }

        var nome: String {
            switch self {
            case .dataNascita: return "Data di nascita (ggmmaaaa)"
            case .codiceFiscale: return "Codice fiscale"
            case .aMano: return "La scrivo ogni volta"
            }
        }
    }

    var proteggi = false
    var regola = Regola.dataNascita

    init() {}

    private enum CodingKeys: String, CodingKey { case proteggi, regola }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        proteggi = (try? c.decodeIfPresent(Bool.self, forKey: .proteggi)) ?? false
        regola = (try? c.decodeIfPresent(Regola.self, forKey: .regola)) ?? .dataNascita
    }

    /// La password proposta per un cliente ("" se il dato manca o si scrive a mano).
    func password(per cliente: Cliente?) -> String {
        guard let cliente else { return "" }
        switch regola {
        case .dataNascita: return cliente.dataNascita.map { Formati.formato("ddMMyyyy").string(from: $0) } ?? ""
        case .codiceFiscale: return cliente.codiceFiscale.uppercased().filter { $0.isLetter || $0.isNumber }
        case .aMano: return ""
        }
    }

    static let lunghezzaMinima = 6
}

/// Promemoria nel Centro notifiche del Mac: appuntamenti, attività, scadenze delle posizioni e compleanni.
/// Spenti di partenza: il permesso di macOS si chiede solo quando li accendi. Letti con tolleranza
/// (gli archivi di prima non li hanno); il permesso di macOS non sta nell'archivio.
struct ImpostazioniPromemoria: Codable, Equatable {
    var attivi = false
    var appuntamenti = true
    var attivita = true
    var scadenze = true
    var compleanni = true
    /// Le occasioni dei clienti (riscatto, penali, età…) nel Centro notifiche del Mac (dalla versione 22).
    var occasioni = true
    /// Quanti minuti prima dell'inizio arriva il promemoria di un appuntamento.
    var anticipoMinuti = 30
    /// Il nome del cliente nel promemoria (spento: solo l'ora e cosa fare).
    var nomiClienti = true

    /// Gli anticipi che si possono scegliere.
    static let anticipi = [15, 30, 60]

    init() {}

    private enum CodingKeys: String, CodingKey {
        case attivi, appuntamenti, attivita, scadenze, compleanni, anticipoMinuti, nomiClienti
        case occasioni
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attivi = (try? c.decodeIfPresent(Bool.self, forKey: .attivi)) ?? false
        appuntamenti = (try? c.decodeIfPresent(Bool.self, forKey: .appuntamenti)) ?? true
        attivita = (try? c.decodeIfPresent(Bool.self, forKey: .attivita)) ?? true
        scadenze = (try? c.decodeIfPresent(Bool.self, forKey: .scadenze)) ?? true
        compleanni = (try? c.decodeIfPresent(Bool.self, forKey: .compleanni)) ?? true
        let anticipo = (try? c.decodeIfPresent(Int.self, forKey: .anticipoMinuti)) ?? 30
        anticipoMinuti = ImpostazioniPromemoria.anticipi.contains(anticipo) ? anticipo : 30
        nomiClienti = (try? c.decodeIfPresent(Bool.self, forKey: .nomiClienti)) ?? true
        occasioni = (try? c.decodeIfPresent(Bool.self, forKey: .occasioni)) ?? true
    }

    /// «15 minuti», «30 minuti», «1 ora».
    static func nomeAnticipo(_ minuti: Int) -> String {
        if minuti >= 60, minuti % 60 == 0 {
            let ore = minuti / 60
            return ore == 1 ? "1 ora" : "\(ore) ore"
        }
        return "\(minuti) minuti"
    }
}

/// Impostazioni di Vera (comprese nel backup).
struct ImpostazioniVera: Codable, Equatable {
    /// Quando Vera risponde anche a voce.
    enum RisposteAVoce: String, Codable, CaseIterable, Identifiable {
        /// Solo quando le parli tu.
        case quandoParli
        case sempre
        case mai

        var id: String { rawValue }

        var nome: String {
            switch self {
            case .quandoParli: return "Quando le parli"
            case .sempre: return "Sempre"
            case .mai: return "Mai"
            }
        }
    }

    /// Le conversazioni restano nel dossier del cliente (sul Mac, nel backup).
    var conservaConversazioni = true
    /// La voce di sistema scelta (identificatore); nil = la migliore voce femminile italiana installata.
    var voce: String?
    /// Velocità della voce: 1 è quella naturale.
    var velocitaVoce = 1.0
    var risposteAVoce = RisposteAVoce.quandoParli
    /// A voce legge tutta la risposta, non solo l'inizio.
    var leggiTutto = false
    /// Dopo aver risposto a voce, Vera torna ad ascoltare finché non le dici «basta».
    var conversazioneContinua = true
    /// Quale riconoscimento vocale usare per ascoltarti (sempre sul Mac).
    var riconoscimento = SceltaRiconoscimento.automatico
    /// Modalità diagnostica: sotto il campo di Vera compare l'ultimo passaggio dell'ascolto.
    var mostraPassaggiVoce = false
    /// Chi fa girare il modello sul Mac: Ollama oppure un server compatibile OpenAI (MLX, llama.cpp, LM Studio).
    var fornitore = TipoFornitore.ollama
    /// Ollama: solo indirizzi locali, il nome del modello da usare.
    var indirizzoLocale = MotoreLocale.indirizzoPredefinito
    var modelloLocale = MotoreLocale.modelloPredefinito
    /// Server compatibile OpenAI: anche qui solo indirizzi del Mac.
    var indirizzoCompatibile = FornitoreCompatibileOpenAI.indirizzoPredefinito
    var modelloCompatibile = ""
    /// Quando Vera ragiona prima di rispondere.
    var ragionamento = SceltaRagionamento.automatico
    /// All'avvio di Prisma Vera apre Ollama (se serve) e carica il modello: è già pronta alla prima domanda.
    var prontaAllAvvio = true
    /// Quanto il modello resta in memoria dopo l'ultima risposta (formato di Ollama: «10m»).
    var restaInMemoria = MotoreLocale.restaInMemoria
    /// I modelli del confronto (Impostazioni › Vera), separati da virgole.
    var modelliConfronto = ConfrontoModelli.predefiniti
    /// iPhone e iPad usano Qwen di questo Mac in rete locale, cifrato con il codice di abbinamento (PonteVera).
    var ponte = ImpostazioniPonte()
    /// «La memoria» (fase 2 di Vera): Vera propone i ricordi e li salva dopo il tuo sì (cifrati, Vera/memoria.cifrato).
    var memoriaAttiva = true
    /// «Impara dalle correzioni»: 👍 e 👎 sotto le risposte, le lezioni rilette prima di rispondere.
    var imparaDalleCorrezioni = true
    /// «Il filo lungo»: la finestra del modello in token (una sola per tutte le chiamate: Ollama ricarica il modello se cambia).
    var finestra = FinestraVera.predefinita
    /// Il modello della ricerca per significato (Ollama, /api/embed), caricato solo quando serve.
    var modelloRicerca = RicercaVera.modelloPredefinito

    /// Il modello del fornitore scelto.
    var modello: String {
        get { fornitore == .ollama ? modelloLocale : modelloCompatibile }
        set { if fornitore == .ollama { modelloLocale = newValue } else { modelloCompatibile = newValue } }
    }

    /// L'indirizzo del fornitore scelto.
    var indirizzo: String {
        get { fornitore == .ollama ? indirizzoLocale : indirizzoCompatibile }
        set { if fornitore == .ollama { indirizzoLocale = newValue } else { indirizzoCompatibile = newValue } }
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case conservaConversazioni, voce, velocitaVoce, risposteAVoce, leggiTutto, conversazioneContinua, indirizzoLocale, modelloLocale, riconoscimento, mostraPassaggiVoce
        case fornitore, indirizzoCompatibile, modelloCompatibile, ragionamento, prontaAllAvvio, restaInMemoria, modelliConfronto, ponte
        case memoriaAttiva, imparaDalleCorrezioni, finestra, modelloRicerca
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        conservaConversazioni = (try? c.decodeIfPresent(Bool.self, forKey: .conservaConversazioni)) ?? true
        voce = try? c.decodeIfPresent(String.self, forKey: .voce)
        velocitaVoce = min(1.4, max(0.7, (try? c.decodeIfPresent(Double.self, forKey: .velocitaVoce)) ?? 1))
        risposteAVoce = (try? c.decodeIfPresent(RisposteAVoce.self, forKey: .risposteAVoce)) ?? .quandoParli
        leggiTutto = (try? c.decodeIfPresent(Bool.self, forKey: .leggiTutto)) ?? false
        conversazioneContinua = (try? c.decodeIfPresent(Bool.self, forKey: .conversazioneContinua)) ?? true
        indirizzoLocale = (try? c.decodeIfPresent(String.self, forKey: .indirizzoLocale)) ?? MotoreLocale.indirizzoPredefinito
        let modello = (try? c.decodeIfPresent(String.self, forKey: .modelloLocale)) ?? MotoreLocale.modelloPredefinito
        // Chi aveva il modello predefinito di prima (qwen3:4b) passa al nuovo; un modello scelto a mano resta
        modelloLocale = modello == MotoreLocale.modelloPrecedente ? MotoreLocale.modelloPredefinito : modello
        fornitore = (try? c.decodeIfPresent(TipoFornitore.self, forKey: .fornitore)) ?? .ollama
        indirizzoCompatibile = (try? c.decodeIfPresent(String.self, forKey: .indirizzoCompatibile)) ?? FornitoreCompatibileOpenAI.indirizzoPredefinito
        modelloCompatibile = (try? c.decodeIfPresent(String.self, forKey: .modelloCompatibile)) ?? ""
        ragionamento = (try? c.decodeIfPresent(SceltaRagionamento.self, forKey: .ragionamento)) ?? .automatico
        prontaAllAvvio = (try? c.decodeIfPresent(Bool.self, forKey: .prontaAllAvvio)) ?? true
        let memoria = (try? c.decodeIfPresent(String.self, forKey: .restaInMemoria)) ?? ""
        restaInMemoria = memoria.isEmpty ? MotoreLocale.restaInMemoria : memoria
        modelliConfronto = (try? c.decodeIfPresent(String.self, forKey: .modelliConfronto)) ?? ConfrontoModelli.predefiniti
        riconoscimento = (try? c.decodeIfPresent(SceltaRiconoscimento.self, forKey: .riconoscimento)) ?? .automatico
        mostraPassaggiVoce = (try? c.decodeIfPresent(Bool.self, forKey: .mostraPassaggiVoce)) ?? false
        ponte = (try? c.decodeIfPresent(ImpostazioniPonte.self, forKey: .ponte)) ?? ImpostazioniPonte()
        memoriaAttiva = (try? c.decodeIfPresent(Bool.self, forKey: .memoriaAttiva)) ?? true
        imparaDalleCorrezioni = (try? c.decodeIfPresent(Bool.self, forKey: .imparaDalleCorrezioni)) ?? true
        finestra = FinestraVera.valida((try? c.decodeIfPresent(Int.self, forKey: .finestra)) ?? FinestraVera.predefinita)
        let ricerca = (try? c.decodeIfPresent(String.self, forKey: .modelloRicerca)) ?? ""
        modelloRicerca = ricerca.isEmpty ? RicercaVera.modelloPredefinito : ricerca
    }
}

struct ImpostazioniBackup: Codable, Equatable {
    /// Cartella scelta dall'utente (nil = cartella predefinita sul Mac).
    var cartella: String?
    var automatico = true
    var ultimo: Date?
    /// L'ultimo tentativo e l'errore dell'ultimo backup non riuscito (disco scollegato, cartella piena…).
    var ultimoTentativo: Date?
    var ultimoErrore: String?
    /// I backup si proteggono con una password (che sta nel Portachiavi del Mac, mai qui).
    /// Opzionale: gli archivi di prima non hanno il campo e si leggono lo stesso.
    var protetto: Bool?
    /// «Escludi la Biblioteca dal backup» («Luce» giro 6, decisione 9 della Biblioteca): i PDF della Biblioteca (e il loro
    /// testo) restano fuori dai backup. Opzionale: nil = la Biblioteca è nel backup.
    var escludiBiblioteca: Bool?

    /// true se i nuovi backup vanno protetti con la password.
    var cifrato: Bool { protetto == true }
    static let lunghezzaMinimaPassword = 8

    /// true se l'ultimo backup riuscito ha più di 8 giorni (o non c'è): va segnalato.
    var inRitardo: Bool {
        guard automatico else { return false }
        guard let ultimo else { return ultimoTentativo != nil }
        return Date().timeIntervalSince(ultimo) > 8 * 24 * 60 * 60
    }

    static let intervalloAutomatico: TimeInterval = 7 * 24 * 60 * 60

    var prossimo: Date? {
        guard automatico else { return nil }
        return ultimo.map { $0.addingTimeInterval(Self.intervalloAutomatico) } ?? Date()
    }
}
