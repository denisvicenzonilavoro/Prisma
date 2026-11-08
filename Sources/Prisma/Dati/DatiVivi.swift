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
        /// Un campo che entra nei calcoli e nei documenti.
        case calcoli
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
    static let numeroCampi = 39

    var versione: Int { didSet { segnala(.calcoli) } }
    var clienti: [Cliente] { didSet { segnala(.calcoli) } }
    var appuntamenti: [Appuntamento] { didSet { segnala(.calcoli) } }
    var attivita: [Attivita] { didSet { segnala(.calcoli) } }
    var posizioni: [Posizione] { didSet { segnala(.calcoli) } }
    var simulazioni: [Simulazione] { didSet { segnala(.calcoli) } }
    var analisi: [String: Analisi360] { didSet { segnala(.calcoli) } }
    var incontri: [Incontro] { didSet { segnala(.calcoli) } }
    var prodotti: [Prodotto] { didSet { segnala(.calcoli) } }
    var obiettivi: [Obiettivo] { didSet { segnala(.calcoli) } }
    var documenti: [Documento] { didSet { segnala(.calcoli) } }
    var valutazioni: [ValutazioneInvestimento] { didSet { segnala(.calcoli) } }
    var conversazioni: [String: [MessaggioVera]] { didSet { segnala(.neutro) } }
    var commenti: [CommentoReport] { didSet { segnala(.calcoli) } }
    var note: [Nota] { didSet { segnala(.note) } }
    var spazi: [SpazioLavoro] { didSet { segnala(.neutro) } }
    var fotografie: [FotografiaRiesame] { didSet { segnala(.calcoli) } }
    var schedeAdeguatezza: [SchedaAdeguatezza] { didSet { segnala(.neutro) } }
    var confrontiTFR: [String: IpotesiTFR] { didSet { segnala(.neutro) } }
    var parcelle: [Parcella] { didSet { segnala(.calcoli) } }
    var raccomandazioni: [Raccomandazione] { didSet { segnala(.calcoli) } }
    var messaggi: [MessaggioCliente] { didSet { segnala(.calcoli) } }
    var eventiVita: [EventoLineaVita] { didSet { segnala(.calcoli) } }
    var sessioniCopilota: [SessioneCopilota] { didSet { segnala(.calcoli) } }
    var giornaleOvunque: [OperazioneOvunque] { didSet { segnala(.calcoli) } }
    var conflittiOvunque: [ConflittoOvunque] { didSet { segnala(.calcoli) } }
    var arriviOvunque: [ArrivoOvunque] { didSet { segnala(.calcoli) } }
    var inquadratureDaConfermare: [InquadraturaPonte] { didSet { segnala(.calcoli) } }
    var mercato: ArchivioMercato { didSet { segnala(.calcoli) } }
    var famiglie: FamiglieCaricate? { didSet { segnala(.calcoli) } }
    var ocf: ArchivioOCF { didSet { segnala(.neutro) } }
    var portafogliModello: [PortafoglioModello] { didSet { segnala(.calcoli) } }
    var pratiche: [Pratica] { didSet { segnala(.neutro) } }
    var partiteRischio: [PartitaRischio] { didSet { segnala(.calcoli) } }
    var promesse: [PromessaCliente] { didSet { segnala(.calcoli) } }
    var confrontiDocumenti: [ConfrontoDocumenti] { didSet { segnala(.calcoli) } }
    var coperture: [CoperturaPolizza] { didSet { segnala(.calcoli) } }
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
        return self == b
    }
}
