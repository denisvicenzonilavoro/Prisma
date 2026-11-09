import Foundation
import Observation

/// L'archivio in memoria, a pezzi (giro 0 di «Prisma istantaneo», Design/velocita-proposta.md, proposta A).
///
/// Ha un campo osservato per ogni campo di `DatiPrisma`, con lo stesso nome: una vista che legge `stato.dati.note`
/// si aggiorna solo quando cambiano le note, non per un tasto in un cliente. Le modifiche si scrivono come sempre
/// (`stato.dati.clienti[i].nome = x`, `stato.dati.impostazioni.aspetto = .scuro`).
///
/// Non è un valore: `let prima = stato.dati` è lo stesso oggetto, non una copia. Per una copia (salvataggio, motori,
/// backup, Prisma ovunque, confronti prima e dopo) si usa `istantanea`; per sostituire tutto l'archivio `carica(_:)`.
/// Di proposito non è né Equatable né Codable: chi confonde i due tipi lo scopre al momento di compilare.
/// Il formato su disco resta `DatiPrisma`.
@Observable final class DatiVivi {
    /// Che cosa è cambiato, per i contatori delle cache di StatoShell (la stessa regola di `DatiPrisma.stessiCalcoli`).
    enum Cambio {
        /// Un campo che entra nei calcoli e nei documenti, di tutti i clienti (o non attribuibile a uno solo).
        case calcoli
        /// Un campo dei calcoli cambiato solo per questi clienti (le loro voci di CacheClienti si rifanno, le altre no).
        case calcoliClienti(Set<String>)
        /// Le note del taccuino (hanno la loro versione).
        case note
        /// Un campo che non entra in nessun calcolo in cache (conversazioni, spazi, cliente attivo…).
        case neutro
        /// Il cliente attivo (neutro per i calcoli; il tavolo con l'iPad lo segue).
        case clienteAttivo(prima: String)
        /// Le impostazioni, con quelle di prima: contano per i calcoli solo alcune (`Impostazioni.stessiCalcoli`).
        case impostazioni(prima: Impostazioni)
        /// Tutto l'archivio sostituito da `carica(_:)`, con l'archivio di prima.
        case tutto(prima: DatiPrisma)
    }

    /// Chi riceve i cambi (StatoShell.datiCambiati): una sola chiamata per ogni modifica, anche annidata.
    /// La chiusura tiene StatoShell con un riferimento debole.
    @ObservationIgnored var aggancio: ((Cambio) -> Void)?
    /// Vero mentre `carica` assegna i campi: i cambi dei singoli campi non si segnalano, si segnala tutto alla fine.
    @ObservationIgnored private var inCarica = false

    /// Numero dei campi di `DatiPrisma` copiati qui (la prova lo confronta con Mirror).
    static let numeroCampi = 48

    var versione: Int { didSet { segnala(.calcoli) } }
    var clienti: [Cliente] { didSet(prima) { segnalaClienti(prima, clienti, \.id) } }
    var appuntamenti: [Appuntamento] { didSet(prima) { segnalaClienti(prima, appuntamenti, \.clienteId) } }
    var attivita: [Attivita] { didSet(prima) { segnalaClienti(prima, attivita, \.clienteId) } }
    var posizioni: [Posizione] { didSet(prima) { segnalaClienti(prima, posizioni, \.clienteId) } }
    var simulazioni: [Simulazione] { didSet(prima) { segnalaClienti(prima, simulazioni, \.clienteId) } }
    var analisi: [String: Analisi360] { didSet(prima) { segnalaAnalisi(prima) } }
    var incontri: [Incontro] { didSet(prima) { segnalaClienti(prima, incontri, \.clienteId) } }
    var prodotti: [Prodotto] { didSet { segnala(.calcoli) } }
    var obiettivi: [Obiettivo] { didSet(prima) { segnalaClienti(prima, obiettivi, \.clienteId) } }
    var documenti: [Documento] { didSet(prima) { segnalaClienti(prima, documenti, \.clienteId) } }
    var valutazioni: [ValutazioneInvestimento] { didSet(prima) { segnalaClienti(prima, valutazioni, \.clienteId) } }
    var conversazioni: [String: [MessaggioVera]] { didSet { segnala(.neutro) } }
    var commenti: [CommentoReport] { didSet(prima) { segnalaClienti(prima, commenti, \.clienteId) } }
    var note: [Nota] { didSet { segnala(.note) } }
    var spazi: [SpazioLavoro] { didSet { segnala(.neutro) } }
    var fotografie: [FotografiaRiesame] { didSet(prima) { segnalaClienti(prima, fotografie, \.clienteId) } }
    var schedeAdeguatezza: [SchedaAdeguatezza] { didSet { segnala(.neutro) } }
    var confrontiTFR: [String: IpotesiTFR] { didSet { segnala(.neutro) } }
    var parcelle: [Parcella] { didSet(prima) { segnalaClienti(prima, parcelle, \.clienteId) } }
    var raccomandazioni: [Raccomandazione] { didSet(prima) { segnalaClienti(prima, raccomandazioni, \.clienteId) } }
    var messaggi: [MessaggioCliente] { didSet(prima) { segnalaClienti(prima, messaggi, \.clienteId) } }
    var eventiVita: [EventoLineaVita] { didSet(prima) { segnalaClienti(prima, eventiVita, \.clienteId) } }
    var sessioniCopilota: [SessioneCopilota] { didSet(prima) { segnalaClienti(prima, sessioniCopilota, \.clienteId) } }
    var giornaleOvunque: [OperazioneOvunque] { didSet { segnala(.calcoli) } }
    var conflittiOvunque: [ConflittoOvunque] { didSet { segnala(.calcoli) } }
    var arriviOvunque: [ArrivoOvunque] { didSet { segnala(.calcoli) } }
    var inquadratureDaConfermare: [InquadraturaPonte] { didSet { segnala(.calcoli) } }
    var mercato: ArchivioMercato { didSet { segnala(.calcoli) } }
    var famiglie: FamiglieCaricate? { didSet { segnala(.calcoli) } }
    var ocf: ArchivioOCF { didSet { segnala(.neutro) } }
    var portafogliModello: [PortafoglioModello] { didSet { segnala(.calcoli) } }
    var pratiche: [Pratica] { didSet { segnala(.neutro) } }
    var partiteRischio: [PartitaRischio] { didSet(prima) { segnalaClienti(prima, partiteRischio, \.clienteId) } }
    var promesse: [PromessaCliente] { didSet(prima) { segnalaClienti(prima, promesse, \.clienteId) } }
    var confrontiDocumenti: [ConfrontoDocumenti] { didSet(prima) { segnalaClienti(prima, confrontiDocumenti, \.clienteId) } }
    var coperture: [CoperturaPolizza] { didSet(prima) { segnalaClienti(prima, coperture, \.clienteId) } }
    /// Le spese del consulente non entrano in nessun calcolo in cache (giro 9 di «Luce»).
    var speseStudio: ArchivioSpese { didSet { segnala(.neutro) } }
    /// I km per cliente di Studio › Spese: nessun calcolo in cache.
    var kmClienti: [String: Double] { didSet { segnala(.neutro) } }
    /// I potenziali clienti («Luce» giro 12) si calcolano nella vista, senza cache: spostare una scheda non rifà le cache
    /// dei clienti.
    var potenziali: [PotenzialeCliente] { didSet { segnala(.neutro) } }
    /// Le campagne avviate («Luce» giro 12) entrano nelle occasioni dei messaggi e nei gruppi (regola dei 30 giorni).
    var campagne: [Campagna] { didSet { segnala(.calcoli) } }
    /// Le note dall'iPhone («Luce» giro 13): nessun calcolo in cache.
    var noteInArrivo: [NotaInArrivo] { didSet { segnala(.neutro) } }
    /// Le notti di lavoro di «Stanotte» («Luce» giro 14): nessun calcolo in cache.
    var notti: [NotteDiLavoro] { didSet { segnala(.neutro) } }
    /// Le cose date al cliente («Luce» giro 15): capsule, sinistri e traccia delle uscite; nessun calcolo in cache (i
    /// traguardi leggono le capsule vive).
    var capsule: [CapsulaTempo] { didSet { segnala(.neutro) } }
    var sinistri: [Sinistro] { didSet { segnala(.neutro) } }
    var uscite: [UscitaCliente] { didSet { segnala(.neutro) } }
    var clienteAttivoId: String { didSet(prima) { segnala(.clienteAttivo(prima: prima)) } }
    var impostazioni: Impostazioni { didSet(prima) { segnala(.impostazioni(prima: prima)) } }

    init(_ d: DatiPrisma) {
        versione = d.versione
        clienti = d.clienti
        appuntamenti = d.appuntamenti
        attivita = d.attivita
        posizioni = d.posizioni
        simulazioni = d.simulazioni
        analisi = d.analisi
        incontri = d.incontri
        prodotti = d.prodotti
        obiettivi = d.obiettivi
        documenti = d.documenti
        valutazioni = d.valutazioni
        conversazioni = d.conversazioni
        commenti = d.commenti
        note = d.note
        spazi = d.spazi
        fotografie = d.fotografie
        schedeAdeguatezza = d.schedeAdeguatezza
        confrontiTFR = d.confrontiTFR
        parcelle = d.parcelle
        raccomandazioni = d.raccomandazioni
        messaggi = d.messaggi
        eventiVita = d.eventiVita
        sessioniCopilota = d.sessioniCopilota
        giornaleOvunque = d.giornaleOvunque
        conflittiOvunque = d.conflittiOvunque
        arriviOvunque = d.arriviOvunque
        inquadratureDaConfermare = d.inquadratureDaConfermare
        mercato = d.mercato
        famiglie = d.famiglie
        ocf = d.ocf
        portafogliModello = d.portafogliModello
        pratiche = d.pratiche
        partiteRischio = d.partiteRischio
        promesse = d.promesse
        confrontiDocumenti = d.confrontiDocumenti
        coperture = d.coperture
        speseStudio = d.speseStudio
        kmClienti = d.kmClienti
        potenziali = d.potenziali
        campagne = d.campagne
        noteInArrivo = d.noteInArrivo
        notti = d.notti
        capsule = d.capsule
        sinistri = d.sinistri
        uscite = d.uscite
        clienteAttivoId = d.clienteAttivoId
        impostazioni = d.impostazioni
    }

    /// Le impostazioni lette senza iscrivere la vista, per i corpi `Equatable` con la `ChiaveVista` (CorpoPortafoglio,
    /// ElencoTrackRecord). Solo per i campi che entrano nei calcoli (`Impostazioni.stessiCalcoli`): cambiandoli cambia
    /// `versioneCalcoli`, quindi la chiave, e il corpo si ridisegna lo stesso. Letta con `impostazioni` iscriverebbe il
    /// corpo a ogni impostazione (aspetto, sfondo, un tasto nel nome utente…) scavalcando l'uguaglianza della chiave.
    var impostazioniDeiCalcoli: Impostazioni { _impostazioni }

    private func segnala(_ cambio: Cambio) {
        if !inCarica { aggancio?(cambio) }
    }

    /// Un campo dei clienti cambiato: segnala solo i clienti toccati (CacheClienti), o nulla se l'array è uguale.
    private func segnalaClienti<T: Equatable>(_ prima: [T], _ ora: [T], _ cliente: KeyPath<T, String>) {
        guard !inCarica else { return }
        segnala(.calcoliClienti(Self.clientiToccati(prima, ora, cliente)))
    }

    private func segnalaAnalisi(_ prima: [String: Analisi360]) {
        guard !inCarica else { return }
        var ids = Set<String>()
        for (id, a) in analisi where prima[id] != a { ids.insert(id) }
        for id in prima.keys where analisi[id] == nil { ids.insert(id) }
        segnala(.calcoliClienti(ids))
    }

    /// I clienti degli elementi diversi fra due versioni di un array: con la stessa lunghezza posto per posto, se no
    /// tutto ciò che sta fra il pezzo iniziale e quello finale uguali (aggiunte, tolte, spostamenti). In più, mai in
    /// meno: un elemento cambiato porta sempre il cliente di prima e quello di adesso. Gli elementi non toccati
    /// condividono la memoria, quindi il confronto costa poco.
    static func clientiToccati<T: Equatable>(_ a: [T], _ b: [T], _ cliente: KeyPath<T, String>) -> Set<String> {
        var ids = Set<String>()
        if a.count == b.count {
            for i in a.indices where a[i] != b[i] {
                ids.insert(a[i][keyPath: cliente])
                ids.insert(b[i][keyPath: cliente])
            }
            return ids
        }
        var inizio = 0
        while inizio < a.count, inizio < b.count, a[inizio] == b[inizio] { inizio += 1 }
        var fine = 0
        while fine < a.count - inizio, fine < b.count - inizio, a[a.count - 1 - fine] == b[b.count - 1 - fine] { fine += 1 }
        for x in a[inizio..<(a.count - fine)] { ids.insert(x[keyPath: cliente]) }
        for x in b[inizio..<(b.count - fine)] { ids.insert(x[keyPath: cliente]) }
        return ids
    }

    /// Una copia dell'archivio com'è adesso (un valore: le modifiche successive non la toccano). Gli array non
    /// toccati condividono la memoria, quindi costa poco. Letta in un body iscrive la vista a tutti i campi.
    var istantanea: DatiPrisma {
        var d = DatiPrisma(clienti: clienti, appuntamenti: appuntamenti, attivita: attivita, posizioni: posizioni,
                           clienteAttivoId: clienteAttivoId, impostazioni: impostazioni)
        d.versione = versione
        d.simulazioni = simulazioni
        d.analisi = analisi
        d.incontri = incontri
        d.prodotti = prodotti
        d.obiettivi = obiettivi
        d.documenti = documenti
        d.valutazioni = valutazioni
        d.conversazioni = conversazioni
        d.commenti = commenti
        d.note = note
        d.spazi = spazi
        d.fotografie = fotografie
        d.schedeAdeguatezza = schedeAdeguatezza
        d.confrontiTFR = confrontiTFR
        d.parcelle = parcelle
        d.raccomandazioni = raccomandazioni
        d.messaggi = messaggi
        d.eventiVita = eventiVita
        d.sessioniCopilota = sessioniCopilota
        d.giornaleOvunque = giornaleOvunque
        d.conflittiOvunque = conflittiOvunque
        d.arriviOvunque = arriviOvunque
        d.inquadratureDaConfermare = inquadratureDaConfermare
        d.mercato = mercato
        d.famiglie = famiglie
        d.ocf = ocf
        d.portafogliModello = portafogliModello
        d.pratiche = pratiche
        d.partiteRischio = partiteRischio
        d.promesse = promesse
        d.confrontiDocumenti = confrontiDocumenti
        d.coperture = coperture
        d.speseStudio = speseStudio
        d.kmClienti = kmClienti
        d.potenziali = potenziali
        d.campagne = campagne
        d.noteInArrivo = noteInArrivo
        d.notti = notti
        d.capsule = capsule
        d.sinistri = sinistri
        d.uscite = uscite
        return d
    }

    /// La stessa copia di `istantanea`, letta senza iscrivere chi la chiede a nessun campo: solo per le cache che hanno già
    /// la loro chiave osservata (`StatoShell.datiDeiCalcoli`, su `versioneCalcoli`). Letta altrove darebbe viste che non
    /// si aggiornano.
    var istantaneaNonOsservata: DatiPrisma {
        var d = DatiPrisma(clienti: _clienti, appuntamenti: _appuntamenti, attivita: _attivita, posizioni: _posizioni,
                           clienteAttivoId: _clienteAttivoId, impostazioni: _impostazioni)
        d.versione = _versione
        d.simulazioni = _simulazioni
        d.analisi = _analisi
        d.incontri = _incontri
        d.prodotti = _prodotti
        d.obiettivi = _obiettivi
        d.documenti = _documenti
        d.valutazioni = _valutazioni
        d.conversazioni = _conversazioni
        d.commenti = _commenti
        d.note = _note
        d.spazi = _spazi
        d.fotografie = _fotografie
        d.schedeAdeguatezza = _schedeAdeguatezza
        d.confrontiTFR = _confrontiTFR
        d.parcelle = _parcelle
        d.raccomandazioni = _raccomandazioni
        d.messaggi = _messaggi
        d.eventiVita = _eventiVita
        d.sessioniCopilota = _sessioniCopilota
        d.giornaleOvunque = _giornaleOvunque
        d.conflittiOvunque = _conflittiOvunque
        d.arriviOvunque = _arriviOvunque
        d.inquadratureDaConfermare = _inquadratureDaConfermare
        d.mercato = _mercato
        d.famiglie = _famiglie
        d.ocf = _ocf
        d.portafogliModello = _portafogliModello
        d.pratiche = _pratiche
        d.partiteRischio = _partiteRischio
        d.promesse = _promesse
        d.confrontiDocumenti = _confrontiDocumenti
        d.coperture = _coperture
        d.speseStudio = _speseStudio
        d.kmClienti = _kmClienti
        d.potenziali = _potenziali
        d.campagne = _campagne
        d.noteInArrivo = _noteInArrivo
        d.notti = _notti
        d.capsule = _capsule
        d.sinistri = _sinistri
        d.uscite = _uscite
        return d
    }

    /// Sostituisce tutto l'archivio (ripristino, dati di prova, Prisma ovunque): assegna solo i campi diversi, poi
    /// segnala un solo cambio con l'archivio di prima.
    func carica(_ d: DatiPrisma) {
        let prima = istantanea
        inCarica = true
        if versione != d.versione { versione = d.versione }
        if clienti != d.clienti { clienti = d.clienti }
        if appuntamenti != d.appuntamenti { appuntamenti = d.appuntamenti }
        if attivita != d.attivita { attivita = d.attivita }
        if posizioni != d.posizioni { posizioni = d.posizioni }
        if simulazioni != d.simulazioni { simulazioni = d.simulazioni }
        if analisi != d.analisi { analisi = d.analisi }
        if incontri != d.incontri { incontri = d.incontri }
        if prodotti != d.prodotti { prodotti = d.prodotti }
        if obiettivi != d.obiettivi { obiettivi = d.obiettivi }
        if documenti != d.documenti { documenti = d.documenti }
        if valutazioni != d.valutazioni { valutazioni = d.valutazioni }
        if conversazioni != d.conversazioni { conversazioni = d.conversazioni }
        if commenti != d.commenti { commenti = d.commenti }
        if note != d.note { note = d.note }
        if spazi != d.spazi { spazi = d.spazi }
        if fotografie != d.fotografie { fotografie = d.fotografie }
        if schedeAdeguatezza != d.schedeAdeguatezza { schedeAdeguatezza = d.schedeAdeguatezza }
        if confrontiTFR != d.confrontiTFR { confrontiTFR = d.confrontiTFR }
        if parcelle != d.parcelle { parcelle = d.parcelle }
        if raccomandazioni != d.raccomandazioni { raccomandazioni = d.raccomandazioni }
        if messaggi != d.messaggi { messaggi = d.messaggi }
        if eventiVita != d.eventiVita { eventiVita = d.eventiVita }
        if sessioniCopilota != d.sessioniCopilota { sessioniCopilota = d.sessioniCopilota }
        if giornaleOvunque != d.giornaleOvunque { giornaleOvunque = d.giornaleOvunque }
        if conflittiOvunque != d.conflittiOvunque { conflittiOvunque = d.conflittiOvunque }
        if arriviOvunque != d.arriviOvunque { arriviOvunque = d.arriviOvunque }
        if inquadratureDaConfermare != d.inquadratureDaConfermare { inquadratureDaConfermare = d.inquadratureDaConfermare }
        if mercato != d.mercato { mercato = d.mercato }
        if famiglie != d.famiglie { famiglie = d.famiglie }
        if ocf != d.ocf { ocf = d.ocf }
        if portafogliModello != d.portafogliModello { portafogliModello = d.portafogliModello }
        if pratiche != d.pratiche { pratiche = d.pratiche }
        if partiteRischio != d.partiteRischio { partiteRischio = d.partiteRischio }
        if promesse != d.promesse { promesse = d.promesse }
        if confrontiDocumenti != d.confrontiDocumenti { confrontiDocumenti = d.confrontiDocumenti }
        if coperture != d.coperture { coperture = d.coperture }
        if speseStudio != d.speseStudio { speseStudio = d.speseStudio }
        if kmClienti != d.kmClienti { kmClienti = d.kmClienti }
        if potenziali != d.potenziali { potenziali = d.potenziali }
        if campagne != d.campagne { campagne = d.campagne }
        if noteInArrivo != d.noteInArrivo { noteInArrivo = d.noteInArrivo }
        if notti != d.notti { notti = d.notti }
        if capsule != d.capsule { capsule = d.capsule }
        if sinistri != d.sinistri { sinistri = d.sinistri }
        if uscite != d.uscite { uscite = d.uscite }
        if clienteAttivoId != d.clienteAttivoId { clienteAttivoId = d.clienteAttivoId }
        if impostazioni != d.impostazioni { impostazioni = d.impostazioni }
        inCarica = false
        aggancio?(.tutto(prima: prima))
    }
}

extension Impostazioni {
    /// Uguali in tutto ciò che entra nei calcoli (la parte delle impostazioni di `DatiPrisma.stessiCalcoli`).
    func stessiCalcoli(di altre: Impostazioni) -> Bool {
        var b = altre
        b.aspetto = aspetto
        b.sfondoAnimato = sfondoAnimato
        b.pioggia = pioggia
        b.acquaDellaScrivania = acquaDellaScrivania
        b.riduciMovimento = riduciMovimento
        b.guidaNascosta = guidaNascosta
        b.introduzioneVista = introduzioneVista
        b.backup = backup
        b.promemoria = promemoria
        b.vera = vera
        b.novitaViste = novitaViste
        b.consegna = consegna
        b.pratiche = pratiche
        // Chilometri, spese e scadenze (giro 9 di «Luce») non entrano nei calcoli in cache
        b.studio.spese = studio.spese
        // Il Territorio non entra nei calcoli in cache: le sue cache hanno le impostazioni nella chiave («Luce» giro 11)
        b.territorio = territorio
        // Il lavoro della notte («Luce» giro 14) non entra nei calcoli in cache
        b.notte = notte
        return self == b
    }
}
