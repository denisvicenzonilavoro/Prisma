#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Combine
import Observation
import SwiftUI

/// Stato della finestra Prisma: dati dell'archivio, finestre interne, backup, avvisi.
/// Le viste dell'Agenda: il mese (predefinito, con le attività accorpate), la settimana, il giorno, le occasioni.
enum VistaAgenda: Hashable { case mese, settimana, giorno, occasioni }

enum FiltroAttivita: Hashable { case aperte, completate, tutte }

enum SchedaSimulazioni: Hashable { case simulatore, scenari, tfr }

/// Gli strumenti dentro Analisi 360 (le app accorpate Simulazioni e Confronti). nil in `strumentoAnalisi`
/// = le aree di analisi, come prima.
enum StrumentoAnalisi: String, CaseIterable, Identifiable {
    case simulatore, scenari, confronto, tfr

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .simulatore: return "Simulatore"
        case .scenari: return "Scenari"
        case .confronto: return "Confronto"
        case .tfr: return "TFR"
        }
    }

    /// Simbolo SF della voce.
    var simbolo: String {
        switch self {
        case .simulatore: return "chart.line.uptrend.xyaxis"
        case .scenari: return "square.stack.3d.up"
        case .confronto: return "rectangle.split.2x1"
        case .tfr: return "building.columns"
        }
    }
}

enum SchedaIncontro: Hashable { case preparazione, ascolto, passi }

/// Ciò che si può mettere a confronto: una posizione (in essere o proposta) o uno scenario salvato.
enum VoceConfronto: Hashable {
    case posizione(String)
    case simulazione(String)
}

@Observable final class StatoShell {
    struct Finestra: Identifiable, Equatable {
        let app: AppPrisma
        var id: AppPrisma { app }
        /// Cornice quando non è ingrandita, nelle coordinate dell'area delle finestre.
        var cornice: CGRect
        var ingrandita = true
        var ridotta = false
    }

    /// Dati dell'archivio locale, a pezzi (DatiVivi.swift): ogni campo si osserva da solo, e ogni modifica, anche
    /// annidata (`dati.clienti[i].nome = x`) o con `dati.carica(_:)`, passa da `datiCambiati` e viene salvata da sola.
    /// È un oggetto: per una copia a valore si usa `dati.istantanea`.
    let dati: DatiVivi
    /// Un segnale per ogni modifica dei dati (al posto di `$dati`): salvataggio, notifiche, promemoria, Prisma
    /// ovunque e la prova della fluidità lo ascoltano con il loro ritardo, e leggono i dati al momento della consegna.
    let modificheDati = PassthroughSubject<Void, Never>()
    /// Il cliente attivo nuovo, quando cambia (il tavolo con l'iPad torna alla schermata neutra).
    let clienteAttivoCambiato = PassthroughSubject<String, Never>()
    /// Cresce a ogni modifica dei dati (salvataggio, segno della cache del dossier per Vera).
    private(set) var versioneDati = 0
    /// Cresce quando cambia qualcosa che entra nei calcoli e nei documenti: tutto tranne le note del taccuino,
    /// le conversazioni con Vera, gli spazi di lavoro, il cliente attivo e le impostazioni che non toccano i
    /// calcoli (DatiPrisma.stessiCalcoli). È la chiave delle cache di DerivatiDati. Resta osservata: una vista che legge
    /// solo dalle cache si aggiorna grazie a lei.
    private(set) var versioneCalcoli = 0
    /// Cresce quando cambiano le note del taccuino (le leggono i documenti, per esempio il fascicolo).
    private(set) var versioneNote = 0
    /// Le versioni per cliente delle cache dei motori (CacheClienti.swift, giro 0 tappa 4): crescono quando cambia
    /// qualcosa di quel cliente. Non osservate: le viste si aggiornano con `versioneCalcoli`, che cresce comunque.
    @ObservationIgnored private var versioniCliente: [String: Int] = [:]
    /// Cresce con ciò che vale per tutti i clienti (catalogo, modelli, mercato, impostazioni dei calcoli, archivio
    /// sostituito, campi non attribuiti a un cliente): rifà le voci di tutti.
    @ObservationIgnored private(set) var versioneComuneClienti = 0
    /// Il numero da cui prendono le versioni (comune e dei clienti): mai due volte lo stesso.
    @ObservationIgnored private var ultimaVersioneClienti = 0
    /// I motori dei singoli clienti, per cliente (CacheClienti.swift).
    @ObservationIgnored let cacheClienti = CacheClienti()

    /// Finestre interne, pannelli e blocco (StatoShellFinestre.swift ne inoltra le proprietà con i nomi di sempre):
    /// cambiarli non pubblica StatoShell, così le app aperte e i widget non si ricalcolano.
    let sistema = StatoFinestre()
    /// Titoli e abilitazioni del menu Vai (li osserva solo ComandiPrisma).
    let menu = StatoMenu()
    /// Dati ricavati dall'archivio, tenuti da parte per `versioneCalcoli` (DerivatiDati.swift).
    let derivati = DerivatiDati()

    private(set) var avviso: String?
    /// L'avviso è il commiato di Vera (con la sfera): dopo un pulsante della mini finestra.
    private(set) var avvisoDiVera = false
    var schermoIntero = false
    var schedaImpostazioni: SchedaImpostazioni = .panoramica
    var schedaCliente: SchedaCliente = .panoramica
    /// La scheda di Studio (Cruscotto, Parcelle e fatture, Track record, Esame OCF): resta finché l'app è aperta, così
    /// la scrivania e le novità possono aprire quella giusta (StudioApp.swift).
    var schedaStudio: SchedaStudio = .cruscotto
    /// «Luce»: la scheda di Pratiche e la vista di Territorio (StatoSala.swift).
    var schedaPratiche: SchedaPratiche = .proposta
    var vistaTerritorio: VistaTerritorio = .oggi
    /// Da dove si apre Messaggi (cliente, occasione, messaggio salvato): la scrivono le altre app con `preparaMessaggio`,
    /// l'app Messaggi la prende con `prendiRichiestaMessaggi()` (CollegamentiMessaggi.swift).
    var richiestaMessaggi: RichiestaMessaggi?
    /// Le occasioni di Messaggi «su richiesta» (una parcella fuori dalle regole del motore), le più recenti: solo in memoria.
    @ObservationIgnored var occasioniSuRichiesta: [OccasioneMessaggio] = []
    /// I file da allegare all'apertura in Mail o in Messaggi, per occasione (copie temporanee): solo in memoria.
    @ObservationIgnored var allegatiMessaggi: [String: [URL]] = [:]
    /// Posizione aperta nel dettaglio (usata anche dalle istantanee).
    var posizioneInDettaglio: String?
    /// Il pannello del dossier Posizioni a cui scorrere ("resistenza", "costi"); si consuma appena raggiunto.
    var ancoraPosizioni: String?
    /// Solo per le istantanee: il cliente del radar con il dettaglio già aperto (Posizioni › Radar, «Luce» giro 2).
    @ObservationIgnored var radarDettaglioIstantanea: String?
    /// Solo per le istantanee: la pratica con il dettaglio già aperto (Pratiche › Dopo la firma, «Luce» giro 3).
    @ObservationIgnored var praticaDettaglioIstantanea: String?
    #if os(macOS)
    /// Solo per le istantanee: le misure di prova del gruppo Velocità (Impostazioni › Strumenti, MisuraVelocita.swift).
    @ObservationIgnored var misureIstantanea: MisuraVelocita?
    #endif
    /// Il gruppo delle Impostazioni a cui scorrere dentro la pagina (`"impostazioni-occasioni"` in Promemoria e
    /// occasioni; `"impostazioni-conformita"` porta alla pagina Conformità); si consuma appena raggiunto.
    var ancoraImpostazioni: String?
    /// I report spuntati per il fascicolo dell'incontro (per la sessione).
    var sceltaFascicolo: Set<TipoProspetto> = TipoProspetto.fascicoloPredefinito
    /// L'appuntamento per cui si prepara il fascicolo (dà la data e il tipo d'incontro alla copertina).
    var fascicoloAppuntamento: String?
    /// Il documento mostrato a tutto schermo all'incontro (nil se non si presenta).
    var presentazione: Presentazione? {
        didSet { aggiornaMenu(); presentazioneCambiata.send(presentazione != nil) }
    }
    /// Si presenta o no (al posto di `$presentazione`, per la mini finestra di Vera).
    let presentazioneCambiata = PassthroughSubject<Bool, Never>()
    /// L'ultima analisi del dossier calcolata, con la versione dei dati (non pubblicata). La cache vera è in
    /// DerivatiDati: questa resta come segno per la prova di Vera.
    @ObservationIgnored var cacheDossier: (chiave: Int, valore: AnalisiDossier)?
    /// Posizioni mostra il portafoglio di tutti i clienti invece del dossier del cliente attivo.
    // Il portafoglio parla di tutti i clienti: in modalità cliente resta chiuso
    var portafoglio = false { didSet { if portafoglio && modoCliente != nil { portafoglio = false } } }
    /// Posizioni › Portafoglio: la vista (Portafoglio o Prova del fuoco), lo scenario e i cursori della prova del fuoco
    /// (StatoProvaFuoco.swift). Un oggetto a parte: trascinare il cursore non pubblica StatoShell. Non si salva.
    let provaFuoco = StatoProvaFuoco()
    /// Posizioni › Smontaggio («Luce» giro 2): il documento letto e le scelte, finché Prisma è aperta (SmontaggioApple.swift).
    let smontaggio = StatoSmontaggio()
    /// Pratiche › Proposta («Luce» giro 3): il bisogno scelto, la sequenza delle cinque tappe, le scelte di prodotto
    /// (StatoPraticheProposta.swift). Un oggetto a parte: la sequenza non pubblica StatoShell. Non si salva.
    let praticheProposta = StatoPraticheProposta()
    /// Mercato (giro 7, StatoMercato.swift): il campo e il risultato della ricerca per ISIN, lo scaricamento in corso, il
    /// foglio aperto. Un oggetto a parte: scrivere nel campo non pubblica StatoShell. Non si salva.
    let sessioneMercato = SessioneMercato()
    /// Inquadra e capisci (giro 5): i testi letti con la fotocamera dell'iPhone e arrivati sul ponte cifrato
    /// (`riceviDalPonte`), in attesa che il consulente li guardi. Gli ultimi `StatoShell.massimoInquadrature`; non si
    /// salvano e non entrano nel dossier da soli.
    var inquadratureInArrivo: [InquadraturaPonte] = [] { didSet { inquadratureCambiate.send(inquadratureInArrivo) } }
    /// Le inquadrature in arrivo quando cambiano (al posto di `$inquadratureInArrivo`, StatoInquadra.swift).
    let inquadratureCambiate = PassthroughSubject<[InquadraturaPonte], Never>()
    /// Il copilota dell'incontro a schermo (giro 5, StatoCopilotaIncontro.swift): fase dell'ascolto, riga in corso,
    /// livelli dell'onda, verbale aperto. Un oggetto a parte: l'onda non pubblica StatoShell. Non si salva.
    let copilota = StatoCopilotaIncontro()
    /// Inquadra e capisci: la scena del Mac (velo, iPhone disegnato, scheda «Prisma sul Mac») e la schermata della
    /// fotocamera sull'iPhone (StatoInquadra.swift). Un oggetto a parte: la cascata dei campi non pubblica StatoShell.
    let inquadra = StatoInquadra()
    /// La Sala di «Luce» (StatoSala.swift): l'esperienza sul palco, osservata solo dalla Sala.
    let sala = StatoSala()
    /// La storia della settimana e dell'anno di «Luce» (giro 5, StoriaLuce.swift): le pagine e quella in corso,
    /// osservate solo dalla storia. Non si salva.
    let storia = StatoStoria()
    /// La palestra della trattativa (Studio › Palestra, «Luce» giro 5, StatoPalestra.swift): un oggetto a parte, ogni
    /// parola di Vera ridisegna solo la conversazione. Non si salva (solo l'esito, in `dati.impostazioni.palestra`).
    let palestra = StatoPalestra()
    /// Prisma ovunque (giro 8, StatoOvunque.swift): lo stato della pagina Impostazioni › iPhone e iPad, la chiave dello
    /// spazio in memoria e i lavori della sincronizzazione. Un oggetto a parte: i pallini e i controlli non pubblicano
    /// StatoShell. Non si salva (le impostazioni dello spazio stanno in `dati.impostazioni.ovunque`).
    let ovunque = StatoOvunque()
    /// Modalità cliente: lo schermo girato verso il cliente mostra solo il suo dossier (id del cliente).
    var modoCliente: String? { didSet { aggiornaMenu() } }
    /// Il pulsante dell'intestazione di Posizioni chiede di aprire il modulo (nuova posizione o proposta).
    var richiestaNuovaPosizione: StatoPosizione?
    /// Il pulsante "Nuovo cliente" dell'intestazione chiede alla rubrica di aprire il modulo.
    var richiestaNuovoCliente = false
    /// Completezza dei dati: chiede a Clienti o Posizioni di aprire il modulo su un campo (si consuma appena letta).
    var richiestaCompletamento: RichiestaCompletamento?
    /// Completezza dei dati: il campo dell'Analisi 360 da evidenziare (si toglie lasciando quell'area).
    var fuocoAnalisi: FuocoAnalisi?
    /// Seguito delle proposte: il modulo dell'esito da mostrare, con l'app che lo presenta.
    var richiestaEsito: RichiestaEsito?
    /// Contatti letti da un file, in attesa di conferma nell'anteprima della rubrica.
    var importazione: ImportazioneClienti?
    /// Posizioni lette da un file, in attesa di conferma in Posizioni.
    var importazionePosizioni: ImportazionePosizioni?
    /// Il pannello «Aggiorna i valori» in Posizioni (elenco della compagnia o griglia dei valori fermi).
    var aggiornaValori: AggiornaValori.Sessione?

    // Agenda e Attività (stato delle viste, non salvato)
    /// Giornata aperta in agenda.
    var giornoAgenda = Calendar.current.startOfDay(for: Date())
    var vistaAgenda: VistaAgenda = .mese
    var appuntamentoSelezionato: String?
    /// nil = tutti i clienti.
    var filtroClienteAgenda: String?
    /// L'occasione scelta in Agenda (calendario delle occasioni): non si salva.
    var occasioneSelezionata: Occasione?
    /// Il gruppo di tipi della vista «Occasioni» (nil = tutti): non si salva.
    var gruppoOccasioniAgenda: GruppoOccasione?
    var attivitaSelezionata: String?
    var filtroStatoAttivita: FiltroAttivita = .aperte
    var filtroClienteAttivita: String?
    var filtroPrioritaAttivita: Attivita.Priorita?
    /// Il pulsante dell'intestazione di Attività chiede di aprire il modulo.
    var richiestaNuovaAttivita = false

    // Strumenti di analisi (stato delle viste, non salvato)
    /// Area aperta in Analisi 360 (nil = panoramica).
    var areaAnalisi: AreaAnalisi? {
        // Un'area scelta da qualunque app (Incontri, Bisogni, Prospetti…) chiude lo strumento aperto in Analisi 360
        didSet { if areaAnalisi != nil, strumentoAnalisi != nil { strumentoAnalisi = nil } }
    }
    /// Strumento aperto in Analisi 360 (simulatore, scenari, confronto, TFR); nil = le aree di analisi.
    /// Lo imposta `apri(.simulazioni)` / `apri(.confronti)`; scegliere un'area o la panoramica lo azzera.
    var strumentoAnalisi: StrumentoAnalisi?
    /// La vista della panoramica di Analisi 360: le quattro aree o «Rispetto alle famiglie come la sua» (giro 6,
    /// FamiglieComeLaSua.swift). Resta finché l'app è aperta; non si salva nell'archivio.
    var vistaAnalisi360: VistaAnalisi360 = .aree
    /// Ipotesi sul tavolo del simulatore.
    var bozzaSimulazione: Simulazione?
    var schedaSimulazioni: SchedaSimulazioni = .simulatore
    /// Scenari scelti per il confronto nella scheda Scenari.
    var scenariConfrontati: Set<String> = []
    var confrontoA: VoceConfronto?
    var confrontoB: VoceConfronto?
    /// Orizzonte comune del confronto (nil = ognuno il suo).
    var orizzonteConfronto: Int?
    /// Orizzonte scelto per la sostituzione (nil: la durata della proposta o l'orizzonte del cliente).
    var orizzonteSostituzione: Int?

    // Incontri
    var incontroAperto: String?
    var schedaIncontro: SchedaIncontro = .preparazione
    /// Proposte ricavate dagli appunti (per incontro) e quelle scelte per entrare nel dossier.
    var proposteIncontro: [String: [PropostaIncontro]] = [:]
    var proposteScelte: Set<String> = []
    var estrazioneInCorso = false

    // Prodotti e Obiettivi
    var prodottoSelezionato: String?
    var filtroCanaleProdotti: Canale?
    var filtroAreaProdotti: AreaPosizione?
    var obiettivoSelezionato: String?

    // Note
    var notaSelezionata: String?
    /// La pagina nuova appena aperta: se resta vuota non entra nel taccuino.
    @ObservationIgnored private var bozzaNota: String?
    /// nil = tutti i clienti.
    var filtroClienteNote: String?
    var ricercaNote = ""

    // Centro notifiche (il pannello aperto o chiuso sta in `sistema`)
    /// Le notifiche, ricalcolate poco dopo ogni modifica dei dati e una volta al minuto
    /// (non a ogni disegno della barra in alto).
    private(set) var notifiche: [Notifica] = []
    @ObservationIgnored private var timerNotifiche: Timer?
    /// Il giorno e l'ora intera di adesso, osservati: `chiaveVista` e `derivatiValidi` li leggono, così le viste che
    /// mostrano dati ricavati (e i corpi `Equatable` con la `ChiaveVista`) si rifanno allo scoccare dell'ora e a
    /// mezzanotte anche senza modifiche ai dati. Li aggiornano il timer delle notifiche (al minuto) e il cambio di
    /// giorno o di fuso (`riverificaGiornoDerivati`).
    private(set) var orologioVista = OrologioVista.di(Date())
    /// Le notifiche già viste in questa sessione (la campanella conta le altre).
    var notificheViste: Set<String> = []
    /// Eventi interni della shell (sblocco, notifica nuova con la posizione della campanella): EventiShell.swift.
    let eventiShell = EventiShell()
    /// Promemoria del Mac: il permesso di macOS (nil finché non si sa, e sempre nelle istantanee e nelle prove).
    var permessoPromemoria: PermessoPromemoria?

    /// Vera parla del portafoglio (tutti i clienti) invece che del cliente attivo.
    var veraPortafoglio = false { didSet { if veraPortafoglio && modoCliente != nil { veraPortafoglio = false } } }

    // Ricerca (⌘K)
    var testoRicerca = ""
    /// Cresce a ogni ⌘K: la Ricerca rimette il cursore nel campo.
    var richiestaFuocoRicerca = 0

    // Documenti
    var documentoSelezionato: String?
    /// Raccolta, filtri, scheda e pagina dell'anteprima dell'app Documenti.
    var vistaDocumenti = VistaDocumenti()
    var documentiInLettura: Set<String> = []

    // Prospetti e report
    /// Prospetto scelto (nil = quadro delle posizioni del cliente attivo).
    var prospetto: SceltaProspetto?
    /// Valutazione aperta nel modulo di modifica.
    var valutazioneInModifica: ValutazioneInvestimento?
    @ObservationIgnored private var testiDocumenti = MemoriaTesti()

    // Vera
    var veraInCorso = false { didSet { veraInCorsoSoggetto.send(veraInCorso) } }
    /// `veraInCorso` com'è adesso, per chi lo segue con Combine (al posto di `$veraInCorso`, MiniVeraShell.swift).
    let veraInCorsoSoggetto = CurrentValueSubject<Bool, Never>(false)
    /// La modalità scelta nella testata dell'app Vera («Lavoro / Conversazione»); nil = la sceglie Vera dalla domanda.
    /// Vale per le domande dell'app (non per la mini finestra) fino a «Nuova conversazione».
    var modalitaVeraScelta: ModalitaVera?
    var domandaVera = "" { didSet { if dettaturaAttiva, domandaVera != oldValue { dettaturaCambiata() } } }
    /// Conversazioni non conservate nell'archivio (se l'utente lo sceglie nelle impostazioni).
    var conversazioniTemporanee: [String: [MessaggioVera]] = [:]
    /// La voce e l'orecchio di Vera: nascono alla prima parola (niente microfono finché non serve).
    /// Chi vuole solo fermarli (blocco, Vera chiusa) usa `…SeNata`/`…SeNato`, così non li fa nascere.
    @ObservationIgnored private(set) var voceVeraSeNata: VoceVera?
    @ObservationIgnored private(set) var ascoltoVeraSeNato: AscoltoVera?
    var voceVera: VoceVera {
        if let v = voceVeraSeNata { return v }
        let v = VoceVera()
        voceVeraSeNata = v
        return v
    }
    var ascoltoVera: AscoltoVera {
        if let a = ascoltoVeraSeNato { return a }
        let a = AscoltoVera()
        ascoltoVeraSeNato = a
        return a
    }
    /// La prossima risposta di Vera si dice anche a voce (la domanda è arrivata a voce).
    @ObservationIgnored var rispostaAVoce = false
    /// Conversazione a voce in corso: dopo ogni risposta Vera torna ad ascoltare, finché non le dici «basta».
    var conversazioneAVoce = false { didSet { aggiornaMenu() } }
    /// Qwen sul Mac (Ollama): pronto o perché no. Si aggiorna con `verificaMotoreLocale()`.
    var disponibilitaLocale = DisponibilitaVera.nonDisponibile("Ollama non ancora verificato.")
    /// La risposta di Vera mentre arriva (osservata solo dalla bolla in arrivo).
    let flussoVera = FlussoVera()
    /// La mini finestra di Vera (⌥ Spazio, sfera nella barra): osservata solo dal suo pannello e dalla sfera.
    let miniVera = StatoMiniVera()
    /// La risposta in corso: si interrompe con una nuova conversazione.
    @ObservationIgnored var compitoVera: Task<Void, Never>?
    /// Il confronto tra modelli (Impostazioni › Vera): a che punto è, e dove sta l'ultimo rapporto.
    var avanzamentoConfronto: String?
    var rapportoConfronto: URL?
    /// Nelle istantanee e nelle prove, dove Qwen non c'è: Vera risponde subito con i calcoli di Prisma.
    @ObservationIgnored var rispostePreparate = false
    /// L'appuntamento chiesto a Vera a cui manca ancora il giorno o l'ora: la prossima frase lo completa.
    @ObservationIgnored var appuntamentoInSospeso: Appuntamento.Bozza?
    /// Lo scenario «E se…?» a cui manca un dato: Vera l'ha chiesto e la prossima frase lo completa (ScenariVeraShell.swift).
    @ObservationIgnored var scenarioInSospeso: ParametriScenarioVera?
    /// La dettatura di macOS nel campo di Vera: ogni richiesta la avvia; la frase parte da sola alla pausa.
    var richiestaDettatura = 0
    var dettaturaAttiva = false
    /// In automatico, dopo un fallimento: il riconoscimento con cui riprovare, quelli ancora da provare, poi la dettatura di macOS.
    @ObservationIgnored var ripiegoAscolto: SceltaRiconoscimento?
    @ObservationIgnored var ripieghiRimasti: [SceltaRiconoscimento]?
    @ObservationIgnored var usaDettatura = false
    @ObservationIgnored var lavoroDettatura: DispatchWorkItem?
    /// La dettatura di macOS ha già scritto qualcosa in questa richiesta (per la diagnostica).
    @ObservationIgnored var dettaturaHaScritto = false
    /// L'esito dell'ultima prova del riconoscimento e del microfono (dalle impostazioni), la prova in corso.
    var esitoProvaRiconoscimento: String?
    var esitoProvaMicrofono: String?
    @ObservationIgnored var provaInCorso: ProvaRiconoscimento?
    /// Modalità diagnostica: l'ultimo passaggio dell'ascolto o della voce, mostrato sotto il campo di Vera.
    var passaggioVoce: String?
    /// Nelle istantanee: lo stato della voce da mostrare (non c'è microfono).
    @ObservationIgnored var voceIstantanea: StatoVoce?

    // Backup
    private(set) var elencoBackup: [VoceBackup] = []
    private(set) var backupInCorso = false { didSet { backupInCorsoCambiato.send(backupInCorso) } }
    /// `backupInCorso` quando cambia (al posto di `$backupInCorso`, StatoMobile).
    let backupInCorsoCambiato = PassthroughSubject<Bool, Never>()
    /// La password dei backup per questa sessione (dal Portachiavi o appena scritta): mai nell'archivio.
    @ObservationIgnored private var passwordBackupInMemoria: String?
    /// Il Portachiavi si legge da solo una volta per sessione (il Mac può chiedere il permesso):
    /// i backup automatici non lo richiedono a ogni controllo.
    @ObservationIgnored private var portachiaviLetto = false
    /// Impostazioni › Archivio: si apre la richiesta della password dei backup.
    var chiediPasswordBackup = false
    /// Un backup protetto da ripristinare, in attesa della password.
    var ripristinoDaSbloccare: RichiestaPasswordBackup? { didSet { ripristinoDaSbloccareCambiato.send(ripristinoDaSbloccare) } }
    /// `ripristinoDaSbloccare` quando cambia (al posto di `$ripristinoDaSbloccare`, StatoMobile).
    let ripristinoDaSbloccareCambiato = PassthroughSubject<RichiestaPasswordBackup?, Never>()

    /// Area delle finestre interne (sotto la barra, sopra il dock), aggiornata dalla vista. Non pubblicata:
    /// la shell disegna le finestre con la sua area (ShellView), questa serve alle azioni (aprire, spostare, affiancare).
    @ObservationIgnored var area: CGRect = CGRect(x: 0, y: 0, width: 1200, height: 700)

    /// false nelle istantanee: niente disco, niente animazioni.
    let persistente: Bool

    @ObservationIgnored private var lavoroAvviso: DispatchWorkItem?
    /// Le sottoscrizioni dello stato (anche quelle di RipresaSistema.swift).
    @ObservationIgnored var abbonamenti = Set<AnyCancellable>()
    #if os(macOS)
    /// Il controllo del backup automatico, quando il Mac è libero (al posto di un timer orario).
    @ObservationIgnored private var attivitaBackup: NSBackgroundActivityScheduler?
    /// Il tavolo con l'iPad (Tavolo/TavoloMac.swift): nasce al primo uso e ascolta in rete solo quando lo apri.
    @ObservationIgnored lazy var tavolo = TavoloMac(stato: self)
    #endif
    /// Il salvataggio in background (Archivio.swift): generazione 0 = i dati letti all'avvio.
    private let salvataggio = SalvataggioArchivio()
    /// La memoria di Vera (fase 2 del brief): ricordi, lezioni e riassunti cifrati (StatoMemoriaVera.swift).
    @ObservationIgnored lazy var memoriaVera = StatoMemoriaVera(persistente: persistente)
    /// I vettori della ricerca per significato, in una cache cifrata (RicercaVera.swift).
    @ObservationIgnored lazy var indiceVera = IndiceVera(persistente: persistente) { [weak self] in self?.memoriaVera.chiaveMemoria() }
    /// La biblioteca delle norme (funzione 13, BibliotecaVera.swift).
    @ObservationIgnored lazy var biblioteca = StatoBiblioteca(persistente: persistente)
    /// Biblioteca · «Trova la pagina» («Luce» giro 6, StatoTrovaPagina.swift): domanda, risultato, indice in memoria.
    @ObservationIgnored lazy var trovaPagina = StatoTrovaPagina(biblioteca: biblioteca, persistente: persistente)
    @ObservationIgnored private var salvataggioSospeso = false
    /// Stop del Mac o schermo spento (RipresaSistema.swift): i lavori a tempo aspettano il risveglio.
    private(set) var lavoriInPausa = false
    @ObservationIgnored private var ripresaLavori: DispatchWorkItem?
    /// Archivio di una versione più recente di Prisma: niente salvataggi né backup automatici.
    private(set) var solaLettura = false
    /// Archivio di una versione più recente: neanche il ripristino di un backup è sicuro.
    private(set) var ripristinoBloccato = false

    init(persistente: Bool = true) {
        self.persistente = persistente
        if persistente {
            // La lettura parte già in PrismaApp.init (AvvioArchivio): qui di solito è pronta
            let avvio = AvvioArchivio.attendi()
            let caricati = avvio.esito
            dati = DatiVivi(caricati.dati)
            // Prisma si apre sempre sulla schermata di benvenuto (mai nelle istantanee e nelle prove):
            // prima del primo disegno e prima di collegaMenu, così il menu Vai nasce già spento
            sistema.bloccato = true
            sistema.bloccatoStabile = true
            // Prima di disegnare qualcosa: i caratteri dell'interfaccia nascono con questa misura
            Tipo.fattore = caricati.dati.impostazioni.dimensioneTesto.fattore
            salvataggioSospeso = caricati.solaLettura
            solaLettura = caricati.solaLettura
            ripristinoBloccato = caricati.bloccaRipristino
            copieNonLeggibili = avvio.copieNonLeggibili
            if let a = caricati.avviso {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.mostraAvviso(a) }
            }
            // Una pagina nuova rimasta vuota alla chiusura non torna come «Bozza»
            if dati.note.contains(where: \.vuota) { dati.note.removeAll(where: \.vuota) }
            collegaDati()
            avviaSalvataggio()
            #if os(macOS)
            avviaBackupAutomatico()
            #elseif os(iOS)
            // Su iPhone e iPad niente backup automatico: i dati arrivano dal backup del Mac
            #endif
            preparaVera()
            applicaImpostazioniVera()
            DiagnosticaVoce.osservatore = { [weak self] riga in self?.passaggioVoce = riga }
            aggiornaElencoBackup()
            // Promemoria del Mac: solo qui, con l'archivio sul disco (mai nelle istantanee e nelle prove)
            avviaPromemoria()
            #if os(macOS)
            // L'aspetto scelto vale prima del primo disegno: niente lampo chiaro con l'aspetto scuro
            NSApplication.shared.appearance = StatoShell.aspettoMac(dati.impostazioni.aspetto)
            // Stop del Mac e risveglio (RipresaSistema.swift)
            avviaRipresa()
            // La mini finestra di Vera: ⌥ Spazio da qualsiasi app (PannelloMiniVera.swift)
            ControlloMiniVera.condiviso.avvia(stato: self)
            // Il ponte di Vera per iPhone e iPad (ServerPonteVera.swift): acceso solo se scelto in Impostazioni › Vera
            // (all'avvio qui, poi da `datiCambiati` quando cambiano le impostazioni di Vera)
            ServerPonteVera.condiviso.aggiorna(dati.impostazioni.vera)
            // I messaggi nuovi del ponte (giro 5): schede del copilota dall'iPad, testi inquadrati dall'iPhone
            ServerPonteVera.condiviso.consegnaArrivi { [weak self] arrivo in
                guard let stato = self else { return .rifiutata("Prisma sul Mac si sta chiudendo.") }
                return await MainActor.run { stato.riceviDalPonte(arrivo) }
            }
            // Inquadra e capisci: con la scena in attesa, il testo dell'iPhone entra da solo (StatoInquadra.swift)
            osservaInquadrature()
            #elseif os(iOS)
            // Su iPhone e iPad l'aspetto lo dà `.preferredColorScheme` della radice (StatoMobile);
            // background e ritorno in primo piano (RipresaSistema.swift)
            avviaRipresa()
            #endif
            // Prisma ovunque (StatoOvunque.swift): spento finché l'utente non lo accende; acceso, apre lo spazio con la
            // chiave del Portachiavi e fa un primo giro, fuori dal thread principale
            avviaOvunque()
            // I file rimasti da un'importazione interrotta vanno nel Cestino (il disco lavora in background);
            // solo con l'archivio letto senza intoppi (con un archivio recuperato o di prova i file servono ancora)
            if caricati.avviso == nil, !caricati.solaLettura, copieNonLeggibili == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaPulizia) { [weak self] in
                    guard let self, !self.lavoriInPausa else { return }
                    self.pulisciDocumentiOrfaniInBackground()
                }
            }
        } else {
            dati = DatiVivi(DatiPrisma.demo())
            collegaDati()
        }
        avviaNotifiche()
        collegaMenu()
    }

    deinit {
        // Il run loop trattiene il timer: senza questo resterebbe acceso dopo uno stato delle prove o delle istantanee
        timerNotifiche?.invalidate()
    }

    /// Il menu Vai segue blocco, modalità cliente, presentazione e conversazione a voce, senza osservare StatoShell:
    /// il blocco da StatoFinestre, il resto dai didSet di modoCliente, presentazione e conversazioneAVoce.
    private func collegaMenu() {
        sistema.bloccatoCambiera
            .sink { [weak self] b in self?.aggiornaMenu(bloccato: b) }
            .store(in: &abbonamenti)
    }

    /// Ripete al menu Vai lo stato di adesso (`bloccato` arriva da StatoFinestre prima che cambi, come `$bloccato`).
    func aggiornaMenu(bloccato: Bool? = nil) {
        menu.aggiorna(bloccato: bloccato ?? sistema.bloccato, inModoCliente: modoCliente != nil,
                      inPresentazione: presentazione != nil, conversazioneAVoce: conversazioneAVoce)
    }

    /// Collega i dati a `datiCambiati` (dopo le pulizie di init, che come prima non contano come modifiche).
    private func collegaDati() {
        dati.aggancio = { [weak self] cambio in self?.datiCambiati(cambio) }
    }

    /// L'unico punto da cui parte tutto ciò che segue una modifica dei dati: i contatori delle cache (la regola di
    /// `DatiPrisma.stessiCalcoli`, campo per campo), le impostazioni di Vera e il segnale `modificheDati`.
    private func datiCambiati(_ cambio: DatiVivi.Cambio) {
        versioneDati &+= 1
        var veraCambiata = false
        switch cambio {
        case .calcoli:
            versioneCalcoli &+= 1
            cambiaVersioneComuneClienti()
        case .calcoliClienti(let ids):
            versioneCalcoli &+= 1
            ultimaVersioneClienti &+= 1
            for id in ids { versioniCliente[id] = ultimaVersioneClienti }
        case .note:
            versioneNote &+= 1
        case .neutro:
            break
        case .clienteAttivo(let prima):
            if dati.clienteAttivoId != prima { clienteAttivoCambiato.send(dati.clienteAttivoId) }
        case .impostazioni(let prima):
            if !dati.impostazioni.stessiCalcoli(di: prima) {
                versioneCalcoli &+= 1
                cambiaVersioneComuneClienti()
            }
            veraCambiata = dati.impostazioni.vera != prima.vera
        case .tutto(let prima):
            // Gli array non toccati condividono la memoria con i vecchi: confrontarli costa O(1)
            let ora = dati.istantanea
            if ora.note != prima.note { versioneNote &+= 1 }
            if !ora.stessiCalcoli(di: prima) {
                versioneCalcoli &+= 1
                cambiaVersioneComuneClienti()
            }
            veraCambiata = ora.impostazioni.vera != prima.impostazioni.vera
            if ora.clienteAttivoId != prima.clienteAttivoId { clienteAttivoCambiato.send(ora.clienteAttivoId) }
        }
        if veraCambiata {
            // «Il filo lungo» e le lezioni seguono le impostazioni di Vera
            applicaImpostazioniVera()
            #if os(macOS)
            // Il ponte di Vera per iPhone e iPad segue le impostazioni (solo con l'archivio sul disco)
            if persistente { ServerPonteVera.condiviso.aggiorna(dati.impostazioni.vera) }
            #endif
        }
        modificheDati.send()
    }

    /// Qualcosa che vale per tutti i clienti è cambiato: le voci di CacheClienti si rifanno tutte (e quelle dei clienti
    /// eliminati si lasciano andare).
    private func cambiaVersioneComuneClienti() {
        ultimaVersioneClienti &+= 1
        versioneComuneClienti = ultimaVersioneClienti
        versioniCliente = [:]
        cacheClienti.tieniSolo(Set(dati.clienti.map(\.id)))
    }

    /// La versione dei dati di un cliente per CacheClienti (0 = non cambiato da quando è cambiato il comune).
    func versioneCliente(_ id: String) -> Int { versioniCliente[id] ?? 0 }

    #if os(macOS)
    /// L'aspetto da dare all'app (nil = segue il Mac); come `AspettoInterfaccia.aspettoMac`, fuori dal MainActor.
    static func aspettoMac(_ aspetto: AspettoInterfaccia) -> NSAppearance? {
        switch aspetto {
        case .automatico: return nil
        case .chiaro: return NSAppearance(named: .aqua)
        case .scuro: return NSAppearance(named: .darkAqua)
        }
    }
    #elseif os(iOS)
    /// Per le funzioni legate ai pannelli e alle finestre del Mac, che su iPhone e iPad arrivano nei prossimi giri.
    static let soloSulMacPerOra = "Su iPhone e iPad questa funzione non c'è ancora: usala da Prisma sul Mac."
    /// Il file da scegliere con `.fileImporter` (al posto di NSOpenPanel del Mac): lo presenta il guscio
    /// dell'iPad (GuscioiPad), poi StatoMobile.importa passa la copia a `importaClienti(da:)` e simili.
    var sceltaFileMobile: SceltaFileMobile?
    #endif

    // MARK: - Lettura

    // In modalità cliente le app vedono solo il cliente davanti a te: gli altri non compaiono da nessuna parte
    var clienti: [Cliente] { modoCliente.map { id in dati.clienti.filter { $0.id == id } } ?? dati.clienti }
    var appuntamenti: [Appuntamento] { modoCliente.map { id in dati.appuntamenti.filter { $0.clienteId == id } } ?? dati.appuntamenti }
    var attivita: [Attivita] { modoCliente.map { id in dati.attivita.filter { $0.clienteId == id } } ?? dati.attivita }
    var nomeUtente: String { dati.impostazioni.nomeUtente }
    var inizialiUtente: String { dati.impostazioni.inizialiUtente }

    /// In modalità cliente il cliente attivo resta quello mostrato: nessun percorso porta a un altro dossier.
    var clienteAttivoId: String {
        get { modoCliente ?? dati.clienteAttivoId }
        set {
            guard modoCliente == nil else { return }
            // Il fascicolo preparato per l'appuntamento di un cliente non segue un altro cliente
            // e lo scenario «E se…?» lasciato a metà non prende la risposta pensata per un altro cliente
            if newValue != dati.clienteAttivoId {
                fascicoloAppuntamento = nil
                scenarioInSospeso = nil
            }
            dati.clienteAttivoId = newValue
        }
    }

    var clienteAttivo: Cliente? { clienti.first { $0.id == clienteAttivoId } }

    /// Di chi parla la finestra di un'app: il suo cliente, tutti i clienti (filtri vuoti, portafoglio)
    /// o nil se l'app non riguarda i clienti. Le app del dossier mostrano il cliente attivo;
    /// Agenda, Attività e Note il cliente del loro filtro.
    func contesto(di app: AppPrisma) -> String? {
        let attivo = clienteAttivo?.nome ?? "Nessun cliente"
        let tutti = "Tutti i clienti"
        let delPortafoglio = "Portafoglio · tutti i clienti"
        func filtro(_ id: String?) -> String {
            guard let id else { return tutti }
            return cliente(id)?.nome ?? tutti
        }
        switch app {
        case .clienti, .analisi360, .obiettivi, .simulazioni, .confronti, .documenti, .incontri:
            return attivo
        case .posizioni:
            return portafoglio ? delPortafoglio : attivo
        case .vera:
            return veraPortafoglio ? delPortafoglio : attivo
        case .presentazioni:
            return sceltaProspetto.tipo == .portafoglio ? delPortafoglio : attivo
        case .agenda:
            return filtro(filtroClienteAgenda)
        case .attivita:
            return filtro(filtroClienteAttivita)
        case .note:
            return filtro(filtroClienteNote)
        case .prodotti:
            return "Catalogo dei prodotti"
        case .ricerca:
            return testoRicerca.isEmpty ? nil : "«\(testoRicerca)»"
        case .studio:
            return "Il tuo lavoro"
        // «Luce»: la Sala parla del cliente attivo; Territorio e Pratiche di tutti i clienti
        case .sala:
            return attivo
        case .territorio, .pratiche:
            return tutti
        case .messaggi, .mercato, .impostazioni, .biblioteca:
            return nil
        }
    }

    // MARK: - Clienti

    /// Aggiunge o aggiorna un cliente e lo mette in primo piano.
    func salvaCliente(_ cliente: Cliente) {
        var c = cliente
        c.nome = c.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        if c.iniziali.trimmingCharacters(in: .whitespaces).isEmpty { c.iniziali = Cliente.iniziali(di: c.nome) }
        if let i = dati.clienti.firstIndex(where: { $0.id == c.id }) {
            dati.clienti[i] = c
        } else {
            dati.clienti.append(c)
        }
        dati.clienteAttivoId = c.id
    }

    /// Elimina un cliente con i suoi appuntamenti e attività.
    func eliminaCliente(_ id: String) {
        // Una risposta di Vera ancora in arrivo non deve ricreare dati del cliente tolto
        compitoVera?.cancel()
        compitoVera = nil
        veraInCorso = false
        dati.clienti.removeAll { $0.id == id }
        dati.appuntamenti.removeAll { $0.clienteId == id }
        dati.attivita.removeAll { $0.clienteId == id }
        dati.posizioni.removeAll { $0.clienteId == id }
        dati.simulazioni.removeAll { $0.clienteId == id }
        dati.analisi[id] = nil
        // Le partite del gioco del rischio della Sala («Luce» giro 4)
        dati.partiteRischio.removeAll { $0.clienteId == id }
        // Vera, fase 3: promesse, confronti e coperture del cliente
        dati.promesse.removeAll { $0.clienteId == id }
        dati.confrontiDocumenti.removeAll { $0.clienteId == id }
        dati.coperture.removeAll { $0.clienteId == id }
        dati.conversazioni[id] = nil
        dati.commenti.removeAll { $0.clienteId == id }
        dati.note.removeAll { $0.clienteId == id }
        dati.incontri.removeAll { $0.clienteId == id }
        dati.obiettivi.removeAll { $0.clienteId == id }
        dati.valutazioni.removeAll { $0.clienteId == id }
        dati.schedeAdeguatezza.removeAll { $0.clienteId == id }
        dati.fotografie.removeAll { $0.clienteId == id }
        dati.confrontiTFR[id] = nil
        // Studio (giro 2): le parcelle e le raccomandazioni del cliente se ne vanno con lui
        dati.parcelle.removeAll { $0.clienteId == id }
        dati.raccomandazioni.removeAll { $0.clienteId == id }
        // Messaggi (giro 3): i messaggi preparati per il cliente se ne vanno con lui
        dati.messaggi.removeAll { $0.clienteId == id }
        // Linea della vita (giro 4): gli eventi del cliente se ne vanno con lui
        dati.eventiVita.removeAll { $0.clienteId == id }
        // Copilota (giro 5): le sessioni d'ascolto del cliente se ne vanno con lui
        dati.sessioniCopilota.removeAll { $0.clienteId == id }
        for d in dati.documenti where d.clienteId == id { rimuoviFile(d) }
        dati.documenti.removeAll { $0.clienteId == id }
        if modoCliente == id { modoCliente = nil }
        if dati.clienteAttivoId == id {
            dati.clienteAttivoId = dati.clienti.first?.id ?? ""
        }
        azzeraNote()
    }

    // MARK: - Note

    func nota(_ id: String?) -> Nota? {
        guard let id else { return nil }
        return dati.note.first { $0.id == id }
    }

    func noteCliente(_ id: String) -> [Nota] {
        dati.note.filter { $0.clienteId == id }.sorted(by: Nota.ordina)
    }

    /// L'elenco dell'app Note: filtro per cliente e ricerca (ogni parola, senza badare ad accenti).
    var noteFiltrate: [Nota] {
        let parole = MotoreRicerca.parole(ricercaNote)
        return dati.note
            .filter { filtroClienteNote == nil || $0.clienteId == filtroClienteNote }
            .filter { n in parole.allSatisfy { MotoreRicerca.contiene(n.titolo, $0) || MotoreRicerca.contiene(n.testo, $0) } }
            .sorted(by: Nota.ordina)
    }

    /// Apre una pagina nuova per il cliente (quello del filtro, o il cliente attivo).
    @discardableResult
    func nuovaNota(clienteId: String? = nil) -> Nota? {
        let filtro = filtroClienteNote.flatMap { cliente($0)?.id }
        guard let cliente = clienteId ?? filtro ?? clienti.first(where: { $0.id == clienteAttivoId })?.id ?? clienti.first?.id else {
            mostraAvviso("Aggiungi prima un cliente: ogni nota appartiene a una persona.")
            return nil
        }
        togliNoteVuote()
        let n = Nota(clienteId: cliente, titolo: "", testo: "")
        dati.note.append(n)
        bozzaNota = n.id
        ricercaNote = ""
        if filtroClienteNote != nil && filtroClienteNote != cliente { filtroClienteNote = cliente }
        notaSelezionata = n.id
        return n
    }

    /// Scegli una nota: le pagine nuove lasciate vuote non restano nel taccuino.
    func scegliNota(_ id: String?) {
        guard id != notaSelezionata else { return }
        togliNoteVuote(tranne: id)
        notaSelezionata = id
    }

    /// Toglie la pagina nuova lasciata vuota (una nota esistente svuotata per riscriverla resta).
    private func togliNoteVuote(tranne id: String? = nil) {
        guard let b = bozzaNota, b != id else { return }
        dati.note.removeAll { $0.id == b && $0.vuota }
        bozzaNota = nil
    }

    /// Dopo un cliente eliminato o un archivio ripristinato, filtro e selezione delle note ripartono.
    private func azzeraNote() {
        // Anche agenda e attività: un filtro su un cliente che non c'è più mostrerebbe pagine vuote
        if let f = filtroClienteAgenda, cliente(f) == nil { filtroClienteAgenda = nil }
        if let f = filtroClienteAttivita, cliente(f) == nil { filtroClienteAttivita = nil }
        if let f = filtroClienteNote, cliente(f) == nil { filtroClienteNote = nil }
        if nota(notaSelezionata) == nil { notaSelezionata = nil }
        bozzaNota = nil
    }

    /// Modifica una nota; la data di aggiornamento cambia solo se cambia qualcosa.
    func modificaNota(_ id: String, _ cambia: (inout Nota) -> Void) {
        guard let i = dati.note.firstIndex(where: { $0.id == id }) else { return }
        var n = dati.note[i]
        cambia(&n)
        n.titolo = String(n.titolo.prefix(Nota.limiteTitolo))
        guard n != dati.note[i] else { return }
        // Cambiato il cliente, il filtro lo segue: la nota resta sotto gli occhi (non se ne apre un'altra)
        if n.clienteId != dati.note[i].clienteId, filtroClienteNote != nil { filtroClienteNote = n.clienteId }
        if !n.vuota, n.id == bozzaNota { bozzaNota = nil }
        if n.titolo != dati.note[i].titolo || n.testo != dati.note[i].testo || n.clienteId != dati.note[i].clienteId {
            n.aggiornataIl = Nota.adesso
        }
        dati.note[i] = n
    }

    func eliminaNota(_ id: String) {
        dati.note.removeAll { $0.id == id }
        if notaSelezionata == id { notaSelezionata = nil }
    }

    /// Dall'appunto alla prossima azione: la bozza di un'attività per il cliente della nota
    /// (si completa e si salva nel modulo delle attività).
    func bozzaAttivitaDaNota(_ id: String) -> Attivita? {
        guard let n = nota(id) else { return nil }
        var a = Attivita.nuova(clienteId: n.clienteId)
        a.titolo = n.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        a.note = "Dalla nota «\(n.titoloMostrato)»."
        return a
    }

    /// Il testo da esportare: titolo, cliente, data e testo.
    func testoEsportato(_ n: Nota) -> String {
        [n.titoloMostrato, "\(cliente(n.clienteId)?.nome ?? "") · aggiornata il \(Formati.dataEstesa.string(from: n.aggiornataIl))", "", n.testo]
            .joined(separator: "\n")
    }

    func alternaPreferito(_ id: String) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == id }) else { return }
        dati.clienti[i].preferito.toggle()
    }

    func aggiornaNota(_ id: String, _ testo: String) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == id }), dati.clienti[i].nota != testo else { return }
        dati.clienti[i].nota = testo
    }

    /// Tinta per un nuovo cliente, a rotazione.
    var prossimaTinta: TintaAvatar {
        let tinte: [TintaAvatar] = [.blu, .rosa, .verde, .viola, .oro]
        return tinte[dati.clienti.count % tinte.count]
    }

    func appuntamentiCliente(_ id: String) -> [Appuntamento] {
        appuntamenti.filter { $0.clienteId == id }.sorted { $0.inizio < $1.inizio }
    }

    func attivitaCliente(_ id: String) -> [Attivita] {
        attivita.filter { $0.clienteId == id }.sorted { $0.scadenza < $1.scadenza }
    }

    // MARK: - Posizioni

    var posizioni: [Posizione] { modoCliente.map { id in dati.posizioni.filter { $0.clienteId == id } } ?? dati.posizioni }

    func salvaPosizione(_ posizione: Posizione) {
        if let i = dati.posizioni.firstIndex(where: { $0.id == posizione.id }) {
            // Il valore che cambia resta nello storico, per il resoconto
            var nuova = posizione
            nuova.registraValorePrecedente(dati.posizioni[i])
            // Seguito delle proposte: date di presentazione e di esito quando cambia l'esito
            let prima = dati.posizioni[i]
            MotoreSeguitoProposte.registraCambio(da: prima, a: &nuova, adesso: Posizione.oggiArrotondato)
            dati.posizioni[i] = nuova
            // Track record: la proposta appena presentata si registra, l'esito nuovo diventa la scelta del cliente
            registraRaccomandazioneSeServe(prima: prima, dopo: nuova)
        } else {
            var nuova = posizione
            MotoreSeguitoProposte.registraCambio(da: nil, a: &nuova, adesso: Posizione.oggiArrotondato)
            dati.posizioni.append(nuova)
            registraRaccomandazioneSeServe(prima: nil, dopo: nuova)
        }
    }

    /// Aggiunge allo storico un valore passato; uno dello stesso giorno viene sostituito.
    func aggiungiRilevazione(_ r: Rilevazione, a id: String) {
        guard let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return }
        let cal = Calendar.current
        // A mezzogiorno e a secondi interi, come il resto dell'archivio
        let giorno = cal.date(bySettingHour: 12, minute: 0, second: 0, of: r.data) ?? r.data
        var elenco = dati.posizioni[i].rilevazioni ?? []
        elenco.removeAll { cal.isDate($0.data, inSameDayAs: giorno) }
        elenco.append(Rilevazione(data: Date(timeIntervalSinceReferenceDate: giorno.timeIntervalSinceReferenceDate.rounded(.down)),
                                  controvalore: r.controvalore, versato: r.versato))
        dati.posizioni[i].rilevazioni = elenco.sorted { $0.data < $1.data }
    }

    /// Toglie dallo storico il valore passato di quel giorno (il valore attuale resta).
    func eliminaRilevazione(_ data: Date, da id: String) {
        guard let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return }
        dati.posizioni[i].rilevazioni?.removeAll { Calendar.current.isDate($0.data, inSameDayAs: data) }
    }

    func eliminaPosizione(_ id: String) {
        dati.posizioni.removeAll { $0.id == id }
        dati.schedeAdeguatezza.removeAll { $0.posizioneId == id }
        // I commenti dei confronti che la usavano
        dati.commenti.removeAll { $0.id.hasPrefix("sostituzione·") && $0.id.components(separatedBy: "·").contains(id) }
    }

    /// Una proposta accettata diventa una posizione in essere, con i dati proposti dal seguito (decorrenza,
    /// primo valore, versato). L'interfaccia apre il modulo dell'esito; questa resta per chi la chiama.
    func attivaProposta(_ id: String) {
        guard let p = dati.posizioni.first(where: { $0.id == id }) else { return }
        chiudiProposta(id, .accettata(datiAccettazione(p, appuntamento: nil)), appuntamentoId: nil)
    }

    /// Apre una posizione nel dettaglio di Posizioni.
    func apriPosizione(_ p: Posizione) {
        portafoglio = false
        clienteAttivoId = p.clienteId
        apri(.posizioni)
        // Dopo il cambio di cliente, che in Posizioni chiude il dettaglio aperto
        DispatchQueue.main.async { self.posizioneInDettaglio = p.id }
    }

    func apriCliente(_ id: String) {
        clienteAttivoId = id
        schedaCliente = .panoramica
        apri(.clienti)
    }

    /// Posizioni in essere che scadono nel giorno indicato (lo scadenzario dell'agenda).
    func scadenzeDelGiorno(_ giorno: Date) -> [Posizione] {
        let cal = Calendar.current
        return posizioni.filter { p in
            guard p.stato == .inEssere, let s = p.scadenza else { return false }
            return cal.isDate(s, inSameDayAs: giorno) && (filtroClienteAgenda == nil || p.clienteId == filtroClienteAgenda)
        }
    }

    // MARK: - Documenti

    func documentiCliente(_ id: String) -> [Documento] {
        dati.documenti.filter { $0.clienteId == id }.sorted { $0.importatoIl > $1.importatoIl }
    }

    func documento(_ id: String?) -> Documento? {
        guard let id else { return nil }
        return dati.documenti.first { $0.id == id }
    }

    func urlDocumento(_ d: Documento) -> URL? {
        d.file.map { Archivio.cartellaDocumenti.appendingPathComponent($0) }
    }

    func urlTesto(_ d: Documento) -> URL? {
        urlDocumento(d).map { $0.deletingPathExtension().appendingPathExtension("txt") }
    }

    /// Testo del documento, pagina per pagina (dal file accanto al documento o dai dati di prova).
    /// Restano in memoria solo i testi usati di recente; la ricerca (`memorizza: false`) legge
    /// gli altri dal disco senza tenerli, così l'archivio intero non finisce in memoria.
    func testoDocumento(_ d: Documento, memorizza: Bool = true) -> [String] {
        if let t = testiDocumenti[d.id] {
            if memorizza { testiDocumenti[d.id] = t }
            return t
        }
        var pagine = DatiDemo.testoDocumento(d.id) ?? []
        if pagine.isEmpty, let url = urlTesto(d), let t = try? String(contentsOf: url, encoding: .utf8) {
            pagine = t.components(separatedBy: LetturaDocumenti.separatorePagine)
        }
        if memorizza { testiDocumenti[d.id] = pagine }
        return pagine
    }

    func aggiornaDocumento(_ id: String, _ cambia: (inout Documento) -> Void) {
        guard let i = dati.documenti.firstIndex(where: { $0.id == id }) else { return }
        cambia(&dati.documenti[i])
    }

    /// Il testo di un documento senza file (documenti di prova delle istantanee e delle prove): resta nella memoria dei
    /// testi come quelli letti dal disco.
    func memorizzaTesto(_ id: String, _ pagine: [String]) { testiDocumenti[id] = pagine }

    /// Copia i file nella cartella Documenti del cliente e li legge.
    func importaDocumenti(_ urls: [URL]) {
        guard persistente else { return }
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per importare documenti.")
            return
        }
        let cliente = clienteAttivoId
        guard self.cliente(cliente) != nil else {
            mostraAvviso("Scegli prima un cliente: ogni documento va nella sua cartella.")
            return
        }
        let fm = FileManager.default
        let cartella = Archivio.cartellaDocumenti.appendingPathComponent(cliente, isDirectory: true)
        try? fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        var ultimo: String?
        for url in urls where LetturaDocumenti.estensioniAccettate.contains(url.pathExtension.lowercased()) {
            var d = Documento(clienteId: cliente, titolo: url.deletingPathExtension().lastPathComponent, tipo: .altro)
            d.importatoIl = Appuntamento.alMinuto(Date())
            let nome = "\(d.id).\(url.pathExtension.lowercased())"
            let destinazione = cartella.appendingPathComponent(nome)
            do {
                try fm.copyItem(at: url, to: destinazione)
            } catch {
                mostraAvviso("Non riesco a copiare \(url.lastPathComponent): \(error.localizedDescription)")
                continue
            }
            d.file = "\(cliente)/\(nome)"
            d.dimensione = (try? fm.attributesOfItem(atPath: destinazione.path)[.size] as? Int64) ?? 0
            dati.documenti.append(d)
            ultimo = d.id
            leggiDocumento(d.id)
        }
        if let ultimo { documentoSelezionato = ultimo }
    }

    private static let codaLettura = DispatchQueue(label: "prisma.lettura-documenti", qos: .userInitiated)

    /// Legge il testo (PDFKit, poi Vision per le scansioni) e cerca i dati; Qwen completa.
    func leggiDocumento(_ id: String) {
        guard !solaLettura, let d = documento(id), let url = urlDocumento(d), let testo = urlTesto(d) else { return }
        documentiInLettura.insert(id)
        // Un documento alla volta: tante scansioni insieme pesano sulla memoria di un Mac da 8 GB
        Self.codaLettura.async {
            let esito = LetturaDocumenti.leggi(url)
            DispatchQueue.main.async {
                // Il documento può essere stato eliminato durante la lettura: niente testo orfano
                guard self.documento(id) != nil else {
                    self.documentiInLettura.remove(id)
                    return
                }
                if let esito {
                    try? esito.pagine.joined(separator: LetturaDocumenti.separatorePagine).write(to: testo, atomically: true, encoding: .utf8)
                }
                guard let esito else {
                    self.aggiornaDocumento(id) { $0.lettura = .illeggibile }
                    self.documentiInLettura.remove(id)
                    self.mostraAvviso("Non riesco a leggere \(d.titolo)")
                    return
                }
                self.testiDocumenti[id] = esito.pagine
                let campi = EstrattoreDocumento.conRegole(esito.pagine)
                self.aggiornaDocumento(id) { x in
                    x.pagine = esito.pagine.count
                    x.pagineOCR = esito.pagineOCR
                    x.lettura = esito.pagine.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .illeggibile : .letto
                    let categoria = MotoreDocumenti.categoriaProbabile(esito.pagine, tipo: x.tipo)
                    // Identità e questionari restano `.altro` per Vera; gli altri prendono il tipo dal testo
                    if x.tipo == .altro, categoria != .identita, categoria != .questionario {
                        x.tipo = EstrattoreDocumento.tipoProbabile(esito.pagine)
                    }
                    // Rileggendo, la categoria scelta dal consulente resta
                    if x.categoria == nil { x.categoria = categoria }
                    // Rileggendo, i dati già confermati (e corretti a mano) restano
                    x.campi = EstrattoreDocumento.unisci(x.campi.filter(\.confermato), campi)
                }
                self.completaConModello(id, pagine: esito.pagine, trovati: campi)
            }
        }
    }

    /// Qwen legge le prime pagine e propone i campi che le regole non hanno trovato.
    private func completaConModello(_ id: String, pagine: [String], trovati: [CampoEstratto]) {
        guard let modello = generativo, trovati.count < CampoDocumento.allCases.count else {
            documentiInLettura.remove(id)
            return
        }
        Task { @MainActor in
            var trovatiModello: [CampoEstratto] = []
            for (n, pagina) in pagine.prefix(6).enumerated() where pagina.count > 80 {
                if let r = try? await modello.genera(istruzioni: EstrattoreDocumento.istruzioniModello,
                                                     richiesta: "PAGINA \(n + 1)\n" + String(pagina.prefix(3_000))) {
                    trovatiModello += EstrattoreDocumento.daRisposta(r, pagina: n + 1)
                }
            }
            // Contro lo stato di adesso: conferme e correzioni fatte durante la lettura restano
            self.aggiornaDocumento(id) { $0.campi = EstrattoreDocumento.unisci($0.campi, trovatiModello) }
            self.documentiInLettura.remove(id)
        }
    }

    func confermaCampo(_ id: String, _ chiave: CampoDocumento, _ si: Bool) {
        aggiornaDocumento(id) { d in
            if let i = d.campi.firstIndex(where: { $0.chiave == chiave }) { d.campi[i].confermato = si }
        }
    }

    func modificaCampo(_ id: String, _ chiave: CampoDocumento, valore: String) {
        aggiornaDocumento(id) { d in
            if let i = d.campi.firstIndex(where: { $0.chiave == chiave }) {
                d.campi[i].valore = valore
                d.campi[i].confermato = true
            }
        }
    }

    func rinominaDocumento(_ id: String, titolo: String, tipo: Documento.Tipo) {
        aggiornaDocumento(id) { $0.titolo = titolo; $0.tipo = tipo }
    }

    private func rimuoviFile(_ d: Documento) {
        // In sola lettura (archivio di una versione più nuova) i file restano: l'archivio vero li usa ancora
        guard persistente, !solaLettura else { return }
        if let u = urlDocumento(d) { try? FileManager.default.removeItem(at: u) }
        if let t = urlTesto(d) { try? FileManager.default.removeItem(at: t) }
    }

    /// Elimina dalla cartella Documenti i file che nessun documento dell'archivio usa più
    /// (con `nelCestino` li sposta nel Cestino del Mac, da dove si possono ancora riprendere).
    /// Restituisce quanti file ha tolto.
    @discardableResult
    func pulisciDocumentiOrfani(nelCestino: Bool = false) -> Int {
        guard persistente, !solaLettura else { return 0 }
        let orfani = Self.fileOrfani(usati: fileUsati(), radice: Archivio.cartellaDocumenti)
        return Self.togli(orfani.file, cartelle: orfani.cartelle, nelCestino: nelCestino)
    }

    /// La stessa pulizia, all'avvio, con il disco in background: i file usati si contano sul thread principale,
    /// cartella e Cestino si toccano fuori. Se nel frattempo i documenti cambiano (un'importazione) si rinuncia:
    /// i file creati dopo l'elenco non ne fanno parte, e quelli di prima sono di nuovo controllati qui.
    func pulisciDocumentiOrfaniInBackground() {
        guard persistente, !solaLettura, documentiInLettura.isEmpty else { return }
        let usati = fileUsati()
        let impronta = dati.documenti.map(\.file)
        let radice = Archivio.cartellaDocumenti
        DispatchQueue.global(qos: .utility).async {
            let orfani = StatoShell.fileOrfani(usati: usati, radice: radice)
            guard !orfani.file.isEmpty || !orfani.cartelle.isEmpty else { return }
            DispatchQueue.main.async {
                guard !self.solaLettura, self.documentiInLettura.isEmpty, self.dati.documenti.map(\.file) == impronta else { return }
                DispatchQueue.global(qos: .utility).async {
                    let tolti = StatoShell.togli(orfani.file, cartelle: orfani.cartelle, nelCestino: true)
                    guard tolti > 0 else { return }
                    DispatchQueue.main.async {
                        self.mostraAvviso("\(tolti) \(tolti == 1 ? "file non più usato spostato" : "file non più usati spostati") nel Cestino")
                    }
                }
            }
        }
    }

    /// I file (e i testi letti) dei documenti dell'archivio.
    private func fileUsati() -> [URL] {
        dati.documenti.flatMap { d in [urlDocumento(d), urlTesto(d)].compactMap { $0 } }
    }

    /// I file della cartella Documenti che nessun documento usa, e le cartelle (le più esterne prima).
    /// Solo disco: va bene anche fuori dal thread principale.
    private static func fileOrfani(usati: [URL], radice: URL) -> (file: [URL], cartelle: [URL]) {
        let usati = Set(usati.map { $0.resolvingSymlinksInPath().path })
        guard let elenco = FileManager.default.enumerator(at: radice.standardizedFileURL,
                                                          includingPropertiesForKeys: [.isRegularFileKey]) else { return ([], []) }
        var file: [URL] = []
        var cartelle: [URL] = []
        for case let u as URL in elenco {
            guard (try? u.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                cartelle.append(u)
                continue
            }
            if !usati.contains(u.resolvingSymlinksInPath().path) { file.append(u) }
        }
        return (file, cartelle)
    }

    /// Toglie i file (nel Cestino o del tutto) e le cartelle rimaste vuote; restituisce quanti file ha tolto.
    private static func togli(_ file: [URL], cartelle: [URL], nelCestino: Bool) -> Int {
        let fm = FileManager.default
        var tolti = 0
        for u in file {
            if nelCestino {
                if (try? fm.trashItem(at: u, resultingItemURL: nil)) != nil { tolti += 1 }
            } else if (try? fm.removeItem(at: u)) != nil {
                tolti += 1
            }
        }
        // Le cartelle dei clienti rimaste vuote (le più interne prima). rmdir non toglie mai una cartella
        // in cui nel frattempo è arrivato un file
        for c in cartelle.reversed() {
            let dentro = (try? fm.contentsOfDirectory(atPath: c.path)) ?? ["?"]
            guard dentro.allSatisfy({ $0 == ".DS_Store" }) else { continue }
            if !dentro.isEmpty { try? fm.removeItem(at: c.appendingPathComponent(".DS_Store")) }
            _ = rmdir(c.path)
        }
        return tolti
    }

    func eliminaDocumento(_ id: String) {
        guard let d = documento(id) else { return }
        rimuoviFile(d)
        dati.documenti.removeAll { $0.id == id }
        // Vera, fase 3: le coperture e i confronti di quel documento vanno con lui
        dati.coperture.removeAll { $0.documentoId == id }
        dati.confrontiDocumenti.removeAll { $0.primaId == id || $0.oraId == id }
        testiDocumenti[id] = nil
        if documentoSelezionato == id { documentoSelezionato = nil }
    }

    // MARK: - Prospetti

    /// Il prospetto da mostrare per il cliente attivo. Una scelta di un altro cliente torna alla prima
    /// valutazione del cliente, o al resoconto delle posizioni se non ne ha.
    var sceltaProspetto: SceltaProspetto {
        let predefinita: SceltaProspetto = valutazioniCliente(clienteAttivoId).first.map { .valutazione($0.id, report: false) } ?? .resoconto(report: false)
        switch prospetto {
        case .posizione(let id)? where posizioni.contains(where: { $0.id == id && $0.clienteId == clienteAttivoId }):
            return .posizione(id)
        case .valutazione(let id, let report)?:
            // Se la valutazione non è di questo cliente, la sua prima; se non ne ha, la pagina vuota con "Nuova valutazione"
            let elenco = valutazioniCliente(clienteAttivoId)
            return .valutazione(elenco.contains { $0.id == id } ? id : (elenco.first?.id ?? ""), report: report)
        case .resoconto(let report)?:
            return .resoconto(report: report)
        case .previdenza(let report)?:
            return .previdenza(report: report)
        case .protezione(let report)?:
            return .protezione(report: report)
        case .liquidita(let report)?:
            return .liquidita(report: report)
        case .checkUp(let report)?:
            return .checkUp(report: report)
        case .resistenza(let report)?:
            return .resistenza(report: report)
        case .costi(let report)?:
            return .costi(report: report)
        case .successione(let report)?:
            return .successione(report: report)
        case .patrimonio(let report)?:
            return .patrimonio(report: report)
        case .fascicolo?:
            return .fascicolo
        case .obiettivo(let id, let report)?:
            let elenco = obiettiviCliente(clienteAttivoId)
            return .obiettivo(elenco.contains { $0.id == id } ? id : (elenco.first?.id ?? ""), report: report)
        case .sostituzione(let a, let b, let report)?:
            let mie = posizioniCliente(clienteAttivoId)
            if a != b, mie.contains(where: { $0.id == a }), mie.contains(where: { $0.id == b }) { return .sostituzione(a, b, report: report) }
            let coppia = MotoreSostituzione.coppia(mie)
            return .sostituzione(coppia?.0 ?? "", coppia?.1 ?? "", report: report)
        case .portafoglio?:
            return .portafoglio
        case .riesame?:
            return .riesame
        case .annoInsieme?:
            return .annoInsieme
        case .confronto(let a, let b)?:
            let voci = ElementoConfronto.elenco(dati, cliente: clienteAttivoId)
            if voci.contains(where: { $0.voce == a }) && voci.contains(where: { $0.voce == b }) { return .confronto(a, b) }
            return predefinita
        default:
            return predefinita
        }
    }

    /// Il testo del commento da stampare nel report (nil nei prospetti e se non c'è).
    private func testoCommento(_ scelta: SceltaProspetto) -> String? {
        scelta.conCommento ? commento(scelta)?.testo : nil
    }

    /// Il documento da mostrare e stampare per una scelta.
    func documentoProspetto(_ scelta: SceltaProspetto) -> DocumentoStampabile? {
        if case .valutazione(let id, let report) = scelta {
            return valutazione(id).flatMap(testiValutazione).map { DocumentoStampabile($0, report: report) }
        }
        if case .sostituzione(let a, let b, let report) = scelta {
            return testiSostituzione(a, b).map { DocumentoStampabile($0, report: report, commento: testoCommento(scelta)) }
        }
        if case .obiettivo(let id, let report) = scelta {
            return testiObiettivo(id).map { DocumentoStampabile($0, report: report, commento: testoCommento(scelta)) }
        }
        if case .checkUp(let report) = scelta {
            // Le ipotesi stimate della completezza: pagina (prospetto) o slide (report) in più
            let k = completezzaCliente(clienteAttivoId)
            return DocumentoStampabile(testiCheckUp(clienteAttivoId), report: report, commento: testoCommento(scelta),
                                       ipotesi: k?.ipotesi(per: .checkUp) ?? [], percentuale: k?.percentuale)
        }
        if case .liquidita(let report) = scelta {
            return DocumentoStampabile(testiLiquidita(clienteAttivoId), report: report, commento: testoCommento(scelta))
        }
        if case .fascicolo = scelta { return documentoFascicolo() }
        if case .annoInsieme = scelta { return testiAnnoInsieme(clienteAttivoId).map { DocumentoStampabile($0) } }
        if case .patrimonio(let report) = scelta {
            return DocumentoStampabile(testiPatrimonio(clienteAttivoId), report: report, commento: testoCommento(scelta))
        }
        if case .successione(let report) = scelta {
            return DocumentoStampabile(testiSuccessione(clienteAttivoId), report: report, commento: testoCommento(scelta))
        }
        if case .costi(let report) = scelta {
            return DocumentoStampabile(testiCosti(clienteAttivoId), report: report, commento: testoCommento(scelta), prodotti: dati.prodotti)
        }
        if case .resistenza(let report) = scelta {
            return DocumentoStampabile(testiResistenza(clienteAttivoId), report: report, commento: testoCommento(scelta))
        }
        if case .protezione(let report) = scelta {
            // Le ipotesi stimate della completezza: pagina (prospetto) o slide (report) in più
            let k = completezzaCliente(clienteAttivoId)
            return DocumentoStampabile(testiProtezione(clienteAttivoId), report: report, commento: testoCommento(scelta),
                                       ipotesi: k?.ipotesi(per: .protezione) ?? [], percentuale: k?.percentuale)
        }
        if case .previdenza(let report) = scelta {
            // Le ipotesi stimate della completezza: pagina (prospetto) o slide (report) in più
            let k = completezzaCliente(clienteAttivoId)
            return DocumentoStampabile(testiPrevidenza(clienteAttivoId), report: report, commento: testoCommento(scelta),
                                       ipotesi: k?.ipotesi(per: .previdenza) ?? [], percentuale: k?.percentuale)
        }
        if case .resoconto(let report) = scelta {
            return DocumentoStampabile(testiResoconto(clienteAttivoId), report: report, commento: testoCommento(scelta))
        }
        return contenutoProspetto(scelta).map { DocumentoStampabile($0) }
    }

    /// I testi e i numeri del check-up del primo incontro di un cliente.
    func testiCheckUp(_ id: String) -> TestiCheckUp {
        TestiCheckUp(MotoreCheckUp.calcola(cliente: self.cliente(id), posizioni: posizioniCliente(id), analisi: analisi360(id), obiettivi: obiettiviCliente(id)))
    }

    /// I testi e i numeri del patrimonio nel tempo di un cliente (lo stesso calcolo del pannello in Posizioni).
    func testiPatrimonio(_ id: String) -> TestiPatrimonio {
        let mie = posizioniCliente(id)
        return TestiPatrimonio(MotorePatrimonio.calcola(mie, obiettivi: obiettiviCliente(id)), posizioni: mie, cliente: cliente(id))
    }

    /// I testi e i numeri del passaggio generazionale di un cliente (lo stesso calcolo del pannello in Posizioni).
    func testiSuccessione(_ id: String) -> TestiSuccessione {
        let c = self.cliente(id)
        let s = c.map { MotoreSuccessione.calcola(cliente: $0, posizioni: posizioniCliente(id)) }
            ?? Successione(voci: [], eredi: [], attivoAsse: 0, debiti: 0, fuoriAsse: 0, immobili: 0, ipocatastali: 0, primaCasa: false, conviventeEscluso: nil, avvisi: [])
        return TestiSuccessione(s, cliente: c)
    }

    /// I testi e i numeri del costo degli investimenti di un cliente (lo stesso calcolo del pannello in Posizioni).
    func testiCosti(_ id: String) -> TestiCosti {
        TestiCosti(MotoreCosti.calcola(posizioniCliente(id), prodotti: dati.prodotti, cliente: id), cliente: self.cliente(id))
    }

    /// I testi e i numeri della prova di resistenza di un cliente (lo stesso calcolo del pannello in Posizioni).
    func testiResistenza(_ id: String) -> TestiResistenza {
        let c = self.cliente(id)
        return TestiResistenza(MotoreResistenza.calcola(posizioniCliente(id), profilo: c?.profilo), cliente: c)
    }

    /// I testi e i numeri del capitale in scadenza e della liquidità di un cliente.
    func testiLiquidita(_ id: String) -> TestiLiquidita {
        let e = MotoreLiquidita.calcola(posizioniCliente(id), obiettivi: obiettiviCliente(id), analisi: analisi360(id).protezione, prodotti: dati.prodotti)
        return TestiLiquidita(e, cliente: self.cliente(id))
    }

    /// I testi e i numeri del piano per un obiettivo, con il quadro degli altri obiettivi del cliente.
    func testiObiettivo(_ id: String) -> TestiObiettivo? {
        guard let o = dati.obiettivi.first(where: { $0.id == id }) else { return nil }
        let mie = posizioniCliente(o.clienteId)
        let altri = obiettiviCliente(o.clienteId).map { ($0, AvanzamentoObiettivo($0, posizioni: mie)) }
        return TestiObiettivo(MotoreObiettivo.calcola(o, posizioni: mie), cliente: self.cliente(o.clienteId), altri: altri)
    }

    /// I testi e i numeri della protezione della famiglia di un cliente (ipotesi dall'Analisi 360).
    func testiProtezione(_ id: String) -> TestiProtezione {
        let intestatario = self.cliente(id)
        let e = MotoreProtezioneFamiglia.calcola(posizioniCliente(id), cliente: intestatario, analisi: analisi360(id).protezione)
        return TestiProtezione(e, cliente: intestatario)
    }

    /// I testi e i numeri del piano previdenziale di un cliente (ipotesi dall'Analisi 360).
    func testiPrevidenza(_ id: String) -> TestiPrevidenza {
        let intestatario = self.cliente(id)
        let e = MotorePrevidenza.calcola(posizioniCliente(id), cliente: intestatario, analisi: analisi360(id).previdenza)
        return TestiPrevidenza(e, cliente: intestatario)
    }

    /// I testi e i numeri della sostituzione di `a` con `b` (o del confronto tra due proposte).
    func testiSostituzione(_ a: String, _ b: String) -> TestiSostituzione? {
        guard a != b, let pa = posizioni.first(where: { $0.id == a }), let pb = posizioni.first(where: { $0.id == b }) else { return nil }
        let intestatario = self.cliente(pa.clienteId)
        let e = MotoreSostituzione.calcola(attuale: pa, alternativa: pb, prodotti: dati.prodotti, anni: orizzonteSostituzione,
                                           orizzonteCliente: intestatario?.profilo.orizzonteAnni)
        return TestiSostituzione(e, cliente: intestatario)
    }

    /// I testi e i numeri del resoconto delle posizioni in essere di un cliente.
    func testiResoconto(_ cliente: String) -> TestiResoconto {
        TestiResoconto(posizioniCliente(cliente), cliente: self.cliente(cliente), prodotti: dati.prodotti)
    }

    func contenutoProspetto(_ scelta: SceltaProspetto) -> ContenutoProspetto? {
        if case .riesame = scelta { return fonteVera(clienteAttivoId).map { CompositoreProspetti.riesame($0, conformita: conformitaCliente(clienteAttivoId), occasioni: occasioniRiesame(clienteAttivoId), memoria: memoriaRiesame(clienteAttivoId)) } }
        return CompositoreProspetti.componi(scelta, dati: dati.istantanea, cliente: clienteAttivoId, orizzonteConfronto: orizzonteConfronto)
    }

    /// Apre Prospetti e report su una scelta precisa (dal dettaglio di una posizione o da Confronti).
    func apriProspetto(_ scelta: SceltaProspetto) {
        prospetto = scelta
        apri(.presentazioni)
    }

    /// Il confronto proposto di partenza: quello aperto in Confronti o la proposta contro la posizione in essere.
    func confrontoPredefinito() -> SceltaProspetto? {
        let voci = ElementoConfronto.elenco(dati, cliente: clienteAttivoId)
        let coppia = ElementoConfronto.coppia(voci, a: confrontoA, b: confrontoB, posizioni: posizioniCliente(clienteAttivoId))
        guard let a = coppia.0, let b = coppia.1 else { return nil }
        return .confronto(a.voce, b.voce)
    }

    /// Salva il PDF nella cartella Documenti del cliente: entra nei backup e si ritrova in Documenti.
    /// `cliente`: di chi è il documento (il tavolo con l'iPad passa il cliente presente); nil = il cliente attivo.
    @discardableResult
    func archiviaProspetto(_ pdf: Data, documento: DocumentoStampabile, cliente perCliente: String? = nil) -> String? {
        let cliente = perCliente ?? clienteAttivoId
        let titolo = "\(documento.genere) · \(documento.titolo)"
        // Lo stesso documento archiviato di nuovo nello stesso giorno sostituisce la copia di prima
        if let vecchio = dati.documenti.first(where: { $0.clienteId == cliente && $0.titolo == titolo && Calendar.current.isDateInToday($0.importatoIl) }) {
            eliminaDocumento(vecchio.id)
        }
        var d = Documento(clienteId: cliente, titolo: titolo, tipo: documento.tipo)
        d.importatoIl = Appuntamento.alMinuto(Date())
        d.lettura = .letto
        let pagine = StampaCarta.testo(pdf)
        d.pagine = pagine.count
        d.dimensione = Int64(pdf.count)
        if persistente {
            let cartella = Archivio.cartellaDocumenti.appendingPathComponent(cliente, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
                try pdf.write(to: cartella.appendingPathComponent("\(d.id).pdf"))
                try? pagine.joined(separator: LetturaDocumenti.separatorePagine)
                    .write(to: cartella.appendingPathComponent("\(d.id).txt"), atomically: true, encoding: .utf8)
            } catch {
                mostraAvviso("Non riesco a salvare il prospetto: \(error.localizedDescription)")
                return nil
            }
            d.file = "\(cliente)/\(d.id).pdf"
        }
        testiDocumenti[d.id] = pagine
        dati.documenti.append(d)
        return d.id
    }

    // MARK: - Valutazioni d'investimento

    func valutazioniCliente(_ id: String) -> [ValutazioneInvestimento] {
        dati.valutazioni.filter { $0.clienteId == id }.sorted { $0.creataIl > $1.creataIl }
    }

    func valutazione(_ id: String?) -> ValutazioneInvestimento? {
        guard let id else { return nil }
        return dati.valutazioni.first { $0.id == id }
    }

    /// I testi e i calcoli di una valutazione (serve un prodotto con le condizioni del contratto).
    func testiValutazione(_ v: ValutazioneInvestimento) -> TestiValutazione? {
        guard let p = prodotto(v.prodottoId), let c = p.condizioni else { return nil }
        return TestiValutazione(v, prodotto: p, condizioni: c)
    }

    /// Prodotti con le condizioni dettagliate, utilizzabili per una valutazione.
    var prodottiValutabili: [Prodotto] { dati.prodotti.filter { $0.condizioni != nil }.sorted { $0.nome < $1.nome } }

    func salvaValutazione(_ v: ValutazioneInvestimento) {
        if let i = dati.valutazioni.firstIndex(where: { $0.id == v.id }) {
            dati.valutazioni[i] = v
        } else {
            dati.valutazioni.append(v)
        }
        prospetto = .valutazione(v.id, report: false)
    }

    func eliminaValutazione(_ id: String) {
        dati.valutazioni.removeAll { $0.id == id }
        if case .valutazione(id, _)? = prospetto { prospetto = nil }
    }

    /// Dal dettaglio di una proposta: apre la sua valutazione o ne prepara una nuova.
    func valutaPosizione(_ p: Posizione) {
        clienteAttivoId = p.clienteId
        if let v = dati.valutazioni.first(where: { $0.posizioneId == p.id }) {
            apriProspetto(.valutazione(v.id, report: false))
        } else if let v = nuovaValutazione(posizione: p) {
            apri(.presentazioni)
            valutazioneInModifica = v
        }
    }

    /// Dalla scheda prodotto: una nuova valutazione per il cliente attivo, da completare nel modulo.
    func valutaProdotto(_ id: String) {
        guard let v = nuovaValutazione(prodotto: id) else { return }
        apri(.presentazioni)
        valutazioneInModifica = v
    }

    /// Una nuova valutazione per il cliente attivo, con ipotesi di partenza da rivedere.
    func nuovaValutazione(prodotto id: String? = nil, posizione: Posizione? = nil) -> ValutazioneInvestimento? {
        guard let p = prodotto(id ?? posizione?.prodottoId) ?? prodottiValutabili.first, let c = p.condizioni else { return nil }
        let cliente = clienteAttivoId
        var v = ValutazioneInvestimento(clienteId: cliente, intestatari: self.cliente(cliente)?.nome ?? "", prodottoId: p.id,
                                        premio: posizione.map { $0.versamentoIniziale > 0 ? $0.versamentoIniziale : 10_000 } ?? 10_000)
        v.posizioneId = posizione?.id
        v.data = Calendar.current.startOfDay(for: Date())
        v.creataIl = Appuntamento.alMinuto(Date())
        v.scenari = ValutazioneInvestimento.ipotesiDiPartenza(c)
        return v
    }

    /// Scheda prodotto con i soli dati confermati.
    func creaProdotto(da id: String, canale: Canale, area: AreaPosizione) {
        guard let d = documento(id) else { return }
        var p = Prodotto(nome: d.confermato(.nomeProdotto) ?? d.titolo, canale: canale, area: area)
        p.emittente = d.confermato(.emittente) ?? ""
        p.tipologia = d.confermato(.tipologia) ?? ""
        p.sri = d.confermato(.sri).flatMap { Int($0.prefix(1)) }
        p.costoIngresso = EstrattoreDocumento.numero(d.confermato(.costoIngresso))
        // Il RIY del KID è un'incidenza complessiva, non il costo corrente: resta nel suo campo, mai come costo annuo
        p.costoAnnuo = EstrattoreDocumento.numero(d.confermato(.costoAnnuo))
        p.incidenzaCostiKID = EstrattoreDocumento.numero(d.confermato(.incidenzaCosti))
        p.periodoRaccomandato = Self.anniDaDocumento(d.confermato(.periodoDetenzione))
        p.fonte = "\(d.titolo) (\(d.tipo.breve), importato il \(Formati.dataBreve.string(from: d.importatoIl)))"
        p.verificatoIl = Calendar.current.startOfDay(for: Date())
        if let anni = d.confermato(.periodoDetenzione) { p.note = "Periodo di detenzione raccomandato: \(anni) anni." }
        // Il rendimento atteso di Prisma è lordo: lo scenario moderato del KID è netto (i costi si conterebbero due volte)
        if let lordo = MotoreConfrontoDossier.rendimentoLordo(d, soloConfermati: true) {
            p.rendimentoAtteso = (lordo.valore * 100).rounded() / 100
            if lordo.fonte == .stima {
                p.note = (p.note + " Rendimento lordo stimato da Prisma dallo scenario moderato del KID (netto).")
                    .trimmingCharacters(in: .whitespaces)
            }
        } else {
            p.rendimentoAtteso = nil
        }
        salvaProdotto(p)
        aggiornaDocumento(id) { $0.prodottoId = p.id }
        mostraAvviso("Scheda prodotto creata: \(p.nome)")
    }

    /// Posizione in essere del cliente con i soli dati confermati.
    func creaPosizione(da id: String, canale: Canale, area: AreaPosizione) {
        guard let d = documento(id) else { return }
        let p = Self.posizioneDaDocumento(d, canale: canale, area: area)
        salvaPosizione(p)
        aggiornaDocumento(id) { $0.posizioneId = p.id }
        apriPosizione(p)
    }

    /// La posizione in essere con i soli dati confermati del documento (senza salvarla). Il premio prende la frequenza
    /// scritta sulla sua riga (`MotoreConfrontoDossier.frequenzaPremio`: «90,00 € al mese» è mensile, non annuale);
    /// un premio unico va nel versamento iniziale; se la riga non dice nulla resta annuale, da confermare nella nota.
    static func posizioneDaDocumento(_ d: Documento, canale: Canale, area: AreaPosizione) -> Posizione {
        var p = Posizione(clienteId: d.clienteId, canale: canale, stato: .inEssere, area: area, nome: d.confermato(.nomeProdotto) ?? d.titolo)
        p.emittente = d.confermato(.emittente) ?? (canale == .alleanza ? "Alleanza Assicurazioni" : "")
        p.tipologia = d.confermato(.tipologia) ?? ""
        p.numeroContratto = d.confermato(.numeroContratto) ?? ""
        p.contraente = d.confermato(.contraente) ?? ""
        p.assicurato = d.confermato(.assicurato) ?? ""
        p.beneficiari = d.confermato(.beneficiari) ?? ""
        p.decorrenza = EstrattoreDocumento.data(d.confermato(.decorrenza))
        p.scadenza = EstrattoreDocumento.data(d.confermato(.scadenza))
        var frequenzaDaConfermare = false
        if let premio = EstrattoreDocumento.numero(d.confermato(.premio)) {
            let riga = d.campi.first { $0.chiave == .premio && $0.confermato }?.estratto ?? ""
            let letta = MotoreConfrontoDossier.frequenzaPremio(riga)
            if letta == .unica {
                p.versamentoIniziale = premio
                p.premio = 0
                p.frequenza = .unica
            } else {
                p.premio = premio
                p.frequenza = letta ?? .annuale
                frequenzaDaConfermare = letta == nil
            }
        }
        p.capitaleAssicurato = EstrattoreDocumento.numero(d.confermato(.capitaleAssicurato))
        p.controvalore = EstrattoreDocumento.numero(d.confermato(.controvalore))
        // Il valore di un estratto conto con la sua data e il versato: lo storico parte da lì
        if let v = ValoriDaDocumento.valore(d) {
            p.dataValore = v.data
            p.totaleVersato = v.versato
        }
        p.costoAnnuo = EstrattoreDocumento.numero(d.confermato(.costoAnnuo))
        p.costoIngresso = EstrattoreDocumento.numero(d.confermato(.costoIngresso))
        p.costoUscita = EstrattoreDocumento.numero(d.confermato(.costoUscita))
        p.incidenzaCostiKID = EstrattoreDocumento.numero(d.confermato(.incidenzaCosti))
        p.periodoRaccomandato = Self.anniDaDocumento(d.confermato(.periodoDetenzione))
        p.sri = d.confermato(.sri).flatMap { Int($0.prefix(1)) }
        p.note = "Dati dal documento «\(d.titolo)», da completare."
            + (frequenzaDaConfermare ? " Il documento non dice ogni quanto si paga il premio: annuale, da confermare." : "")
        return p
    }

    /// Gli anni del periodo di detenzione raccomandato letti da un documento («5» o «5 anni»), tra 1 e 60.
    static func anniDaDocumento(_ testo: String?) -> Int? {
        guard let testo else { return nil }
        let cifre = testo.trimmingCharacters(in: .whitespaces).prefix(while: { $0.isASCII && $0.isNumber })
        guard let anni = Int(String(cifre)), anni >= 1, anni <= 60 else { return nil }
        return anni
    }

    /// Porta nella posizione il valore confermato di un estratto conto e collega il documento.
    func registraValore(daDocumento id: String, posizione pid: String) {
        guard !solaLettura, let d = documento(id), let v = ValoriDaDocumento.valore(d),
              let i = dati.posizioni.firstIndex(where: { $0.id == pid }) else { return }
        let esito = ValoriDaDocumento.applica(v, a: &dati.posizioni[i])
        aggiornaDocumento(id) { $0.posizioneId = pid }
        let quando = Formati.dataEstesa.string(from: v.data)
        mostraAvviso(esito == .attuale ? "Valore attuale di «\(dati.posizioni[i].nome)» aggiornato al \(quando)"
                                       : "Valore del \(quando) aggiunto allo storico di «\(dati.posizioni[i].nome)»")
    }

    // MARK: - Prodotti

    var prodotti: [Prodotto] { dati.prodotti.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending } }

    func prodotto(_ id: String?) -> Prodotto? {
        guard let id else { return nil }
        return dati.prodotti.first { $0.id == id }
    }

    func salvaProdotto(_ p: Prodotto) {
        if let i = dati.prodotti.firstIndex(where: { $0.id == p.id }) { dati.prodotti[i] = p } else { dati.prodotti.append(p) }
        prodottoSelezionato = p.id
    }

    func eliminaProdotto(_ id: String) {
        dati.prodotti.removeAll { $0.id == id }
        for i in dati.posizioni.indices where dati.posizioni[i].prodottoId == id { dati.posizioni[i].prodottoId = nil }
        if prodottoSelezionato == id { prodottoSelezionato = nil }
    }

    /// Posizioni e proposte (di tutti i clienti) nate da una scheda.
    func posizioniDelProdotto(_ id: String) -> [Posizione] {
        posizioni.filter { $0.prodottoId == id }
    }

    /// Crea una proposta per il cliente attivo con le condizioni della scheda e la apre in Posizioni.
    func proponi(_ p: Prodotto) {
        let proposta = p.proposta(per: clienteAttivoId)
        salvaPosizione(proposta)
        apriPosizione(proposta)
        mostraAvviso("Proposta creata per \(clienteAttivo?.nome ?? "il cliente"): completa importi e durata")
    }

    func simula(_ p: Prodotto) {
        var s = Simulazione(clienteId: clienteAttivoId, titolo: p.nome)
        s.capitale = 10_000
        s.versamentoMensile = 100
        s.rendimento = p.rendimentoAtteso ?? IpotesiCalcolo.rendimentoPredefinito
        s.costoIngresso = p.costoIngresso ?? 0
        s.costoAnnuo = p.costoAnnuo ?? 0
        s.aliquota = p.aliquotaFiscale ?? IpotesiCalcolo.aliquotaPredefinita
        // Multiramo a due parti: il simulatore è a comparto unico, quindi gli equivalenti pesati sulle quote
        // (gestione separata e fondi, ognuno con il suo rendimento), come per una posizione
        let proposta = p.proposta(per: clienteAttivoId)
        if proposta.multiramoDivisa {
            let q = ParametriProiezione(posizione: proposta)
            s.rendimento = q.rendimentoEquivalente
            s.costoAnnuo = q.costoAnnuoEquivalente
            s.aliquota = q.aliquotaEquivalente
        }
        s.canale = p.canale
        bozzaSimulazione = s
        schedaSimulazioni = .simulatore
        apri(.simulazioni)
    }

    // MARK: - Obiettivi

    func obiettiviCliente(_ id: String) -> [Obiettivo] {
        dati.obiettivi.filter { $0.clienteId == id }.sorted {
            $0.priorita != $1.priorita ? $0.priorita > $1.priorita : $0.scadenza < $1.scadenza
        }
    }

    func salvaObiettivo(_ o: Obiettivo) {
        if let i = dati.obiettivi.firstIndex(where: { $0.id == o.id }) { dati.obiettivi[i] = o } else { dati.obiettivi.append(o) }
        obiettivoSelezionato = o.id
    }

    func eliminaObiettivo(_ id: String) {
        dati.obiettivi.removeAll { $0.id == id }
        dati.commenti.removeAll { $0.id == "obiettivo·\(id)" }
        if obiettivoSelezionato == id { obiettivoSelezionato = nil }
    }

    /// Porta l'obiettivo nel simulatore: capitale già da parte e il versamento necessario.
    func simula(_ o: Obiettivo) {
        let a = AvanzamentoObiettivo(o, posizioni: posizioniCliente(o.clienteId))
        var s = Simulazione(clienteId: o.clienteId, titolo: o.titolo)
        s.capitale = a.accantonato
        s.versamentoMensile = ((a.versamentoNecessario ?? 0) / 10).rounded(.up) * 10
        s.anni = max(1, Int((Double(o.mesiMancanti) / 12).rounded(.up)))
        s.rendimento = o.rendimento
        s.aliquota = 0
        s.inflazione = 0
        clienteAttivoId = o.clienteId
        bozzaSimulazione = s
        schedaSimulazioni = .simulatore
        apri(.simulazioni)
    }

    // MARK: - Incontri

    func incontriCliente(_ id: String) -> [Incontro] {
        dati.incontri.filter { $0.clienteId == id }.sorted { $0.data > $1.data }
    }

    func incontro(_ id: String?) -> Incontro? {
        guard let id else { return nil }
        return dati.incontri.first { $0.id == id }
    }

    func salvaIncontro(_ i: Incontro) {
        var x = i
        x.aggiornatoIl = Appuntamento.alMinuto(Date())
        let concluso = x.stato == .concluso && dati.incontri.first(where: { $0.id == x.id })?.stato != .concluso
        if let k = dati.incontri.firstIndex(where: { $0.id == x.id }) {
            dati.incontri[k] = x
        } else {
            dati.incontri.append(x)
        }
        // «Le promesse» (fase 3 di Vera): alla chiusura dell'incontro gli impegni presi entrano nell'elenco
        if concluso { raccogliPromesse(cliente: x.clienteId) }
    }

    func eliminaIncontro(_ id: String) {
        dati.incontri.removeAll { $0.id == id }
        if incontroAperto == id { incontroAperto = nil }
    }

    /// Nuovo incontro: dal prossimo appuntamento del cliente, con i temi delle sue priorità.
    func nuovoIncontro(cliente id: String, appuntamento: Appuntamento? = nil) {
        let a = appuntamento ?? prossimiAppuntamenti.first { $0.clienteId == id }
        var i = Incontro(clienteId: id, titolo: a?.titolo ?? "Incontro di consulenza", data: a?.inizio ?? Appuntamento.alMinuto(Date()),
                         appuntamentoId: a?.id)
        if let c = cliente(id) {
            let priorita = MotoreBisogni.priorita(bisogniRilevati(id), profilo: c.bisogni).map(\.areaAnalisi)
            var temi: [AreaAnalisi] = []
            for t in priorita where !temi.contains(t) { temi.append(t) }
            if !temi.isEmpty { i.temi = temi }
        }
        salvaIncontro(i)
        incontroAperto = i.id
        schedaIncontro = .preparazione
    }

    /// Apre l'incontro legato a un appuntamento (lo crea se manca).
    func apriIncontro(per a: Appuntamento) {
        clienteAttivoId = a.clienteId
        if let i = dati.incontri.first(where: { $0.appuntamentoId == a.id }) {
            incontroAperto = i.id
            schedaIncontro = i.stato == .concluso ? .passi : .preparazione
        } else {
            nuovoIncontro(cliente: a.clienteId, appuntamento: a)
        }
        apri(.incontri)
    }

    /// Legge gli appunti: regole di Prisma subito, Qwen (se è pronto) si aggiunge.
    func estraiProposte(_ i: Incontro) {
        let altro = [i.progetti, i.esperienza, i.appunti, i.decisioni].filter { !$0.isEmpty }.joined(separator: "\n")
        let regole = EstrattoreIncontro.conRegole(altro, preoccupazioni: i.preoccupazioni)
        proposteIncontro[i.id] = regole
        proposteScelte = Set(regole.map(\.id))
        guard persistente, let modello = generativo, !i.vuoto else { return }
        estrazioneInCorso = true
        let testo = i.testoAscolto
        Task { @MainActor in
            if let risposta = try? await modello.genera(istruzioni: EstrattoreIncontro.istruzioniModello,
                                                         richiesta: "APPUNTI DELL'INCONTRO\n" + testo) {
                let modello = EstrattoreIncontro.daRisposta(risposta)
                let unite = EstrattoreIncontro.unisci(regole, modello)
                self.proposteIncontro[i.id] = unite
                self.proposteScelte.formUnion(modello.map(\.id))
            }
            self.estrazioneInCorso = false
        }
    }

    /// Chiude l'incontro: le proposte scelte entrano nel profilo, nascono attività e seguito in agenda.
    func chiudiIncontro(_ id: String) {
        guard var i = incontro(id) else { return }
        let scelte = (proposteIncontro[id] ?? []).filter { proposteScelte.contains($0.id) }
        aggiornaBisogni(i.clienteId) { p in
            for s in scelte {
                switch s.tipo {
                case .bisogno(let area, let importanza):
                    var v = p.valutazione(area)
                    if importanza > v.importanza { v.importanza = importanza }
                    if v.orizzonte == nil { v.orizzonte = .medio }
                    p.imposta(v)
                case .evento(let tipo, let anno):
                    if !p.eventi.contains(where: { $0.tipo == tipo && $0.anno == anno }) {
                        p.eventi.append(EventoVita(tipo: tipo, anno: anno, nota: String(s.fonte.prefix(120))))
                    }
                case .attivita:
                    break
                }
            }
        }
        let scadenza = i.scadenzaAttivita ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        for s in scelte {
            if case .attivita(let titolo) = s.tipo {
                var t = Attivita.nuova(clienteId: i.clienteId, scadenza: scadenza)
                t.titolo = titolo
                t.appuntamentoId = i.appuntamentoId
                t.note = "Dall'incontro «\(i.titolo)»"
                dati.attivita.append(t)
            }
        }
        let attivita = i.prossimaAttivita.trimmingCharacters(in: .whitespacesAndNewlines)
        if !attivita.isEmpty {
            var t = Attivita.nuova(clienteId: i.clienteId, scadenza: scadenza)
            t.titolo = attivita
            t.appuntamentoId = i.appuntamentoId
            t.priorita = .alta
            t.note = i.decisioni
            dati.attivita.append(t)
            i.attivitaCreataId = t.id
        }
        if let quando = i.prossimoIncontro {
            var a = Appuntamento.nuovo(clienteId: i.clienteId, giorno: quando)
            a.inizio = Appuntamento.alMinuto(quando)
            a.titolo = "Seguito · \(i.titolo)"
            a.note = i.decisioni
            a.tipo = .revisione
            dati.appuntamenti.append(a)
            i.appuntamentoCreatoId = a.id
        }
        if let k = dati.appuntamenti.firstIndex(where: { $0.id == i.appuntamentoId }) {
            dati.appuntamenti[k].stato = .concluso
            // Seguito delle proposte: Incontri chiede l'esito della proposta presentata
            segnaConclusione(dati.appuntamenti[k].id, origine: .incontri)
        }
        i.stato = .concluso
        // Riesame con memoria: l'incontro di riesame concluso salva la fotografia delle cifre chiave
        if incontroDiRiesame(i) { fotografaRiesame(i.clienteId, origine: .incontro, avviso: false) }
        salvaIncontro(i)
        proposteIncontro[id] = nil
        mostraAvviso("Incontro archiviato: profilo, attività e agenda aggiornati")
    }

    // MARK: - Profilo dei bisogni

    /// In cache (DerivatiDati) finché non cambiano i dati dei calcoli, il giorno o la modalità cliente.
    func bisogniRilevati(_ id: String) -> [BisognoRilevato] {
        let v = voceCliente(id)
        if let b = v.bisogni { return b }
        guard let c = cliente(id) else { return [] }
        let b = MotoreBisogni.rileva(cliente: c, posizioni: posizioniCliente(id), analisi: analisi360(id))
        v.bisogni = b
        return b
    }

    /// Modifica il profilo dei bisogni del cliente e ne segna la data.
    func aggiornaBisogni(_ id: String, _ cambia: (inout ProfiloBisogni) -> Void) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == id }) else { return }
        var p = dati.clienti[i].bisogni
        cambia(&p)
        p.aggiornatoIl = Appuntamento.alMinuto(Date())
        dati.clienti[i].bisogni = p
    }

    // MARK: - Strumenti di analisi

    func simulazioniCliente(_ id: String) -> [Simulazione] {
        dati.simulazioni.filter { $0.clienteId == id }.sorted { $0.creataIl > $1.creataIl }
    }

    func salvaSimulazione(_ s: Simulazione) {
        if let i = dati.simulazioni.firstIndex(where: { $0.id == s.id }) {
            dati.simulazioni[i] = s
        } else {
            dati.simulazioni.append(s)
        }
    }

    func eliminaSimulazione(_ id: String) {
        dati.simulazioni.removeAll { $0.id == id }
        scenariConfrontati.remove(id)
        if confrontoA == .simulazione(id) { confrontoA = nil }
        if confrontoB == .simulazione(id) { confrontoB = nil }
    }

    /// Apre il simulatore con le ipotesi di una posizione.
    func simula(_ p: Posizione) {
        clienteAttivoId = p.clienteId
        bozzaSimulazione = Simulazione(posizione: p, orizzonteCliente: cliente(p.clienteId)?.profilo.orizzonteAnni)
        schedaSimulazioni = .simulatore
        apri(.simulazioni)
    }

    /// Apre Confronti con una posizione da una parte; dall'altra la proposta (o la posizione) più vicina.
    func confronta(_ p: Posizione) {
        clienteAttivoId = p.clienteId
        let altre = posizioniCliente(p.clienteId).filter { $0.id != p.id && $0.area.proiettabile && $0.stato != .chiusa }
        let opposte = altre.filter { $0.stato != p.stato }
        let altra = opposte.first { $0.area == p.area } ?? altre.first { $0.area == p.area } ?? opposte.first ?? altre.first
        confrontoA = .posizione(p.id)
        confrontoB = altra.map { .posizione($0.id) }
        orizzonteConfronto = nil
        apri(.confronti)
    }

    /// Analisi 360 del cliente: quella salvata o, se manca, una prima stesura dalle posizioni.
    func analisi360(_ id: String) -> Analisi360 {
        if let salvata = dati.analisi[id] { return salvata }
        // La prima stesura si costruisce una volta sola per dati dei calcoli, giorno e modalità cliente
        let v = voceCliente(id)
        if let bozza = v.analisiBozza { return bozza }
        let bozza = Analisi360(cliente: cliente(id), posizioni: posizioniCliente(id))
        v.analisiBozza = bozza
        return bozza
    }

    func analisiSalvata(_ id: String) -> Bool { dati.analisi[id] != nil }

    func salvaAnalisi(_ id: String, _ a: Analisi360) {
        var x = a
        x.aggiornataIl = Appuntamento.alMinuto(Date())
        dati.analisi[id] = x
    }

    /// Riparte dai dati delle posizioni (l'analisi salvata viene tolta).
    func ricalcolaAnalisi(_ id: String) {
        dati.analisi[id] = nil
    }

    // MARK: - Vera

    /// Messaggi conservati per cliente.
    static let massimoMessaggi = 60

    /// Qwen sul Mac, pronto o no: nome, descrizione e stato per la striscia di Vera.
    var qwen: MotoreLocale { MotoriVera.qwen(dati.impostazioni.vera, locale: disponibilitaLocale) }
    /// Qwen se è pronto; nil se Ollama è spento o manca il modello.
    var generativo: (MotoreVera & MotoreGenerativo)? { MotoriVera.generativo(dati.impostazioni.vera, locale: disponibilitaLocale) }

    /// Vera risponde con Qwen. Se l'ultima verifica non l'ha trovato pronto, prima chiede di nuovo a Ollama
    /// (magari è stato appena aperto); se ancora non c'è, Vera lo dice e non risponde.
    func conQwen(cliente id: String, _ poi: @escaping ((MotoreVera & MotoreGenerativo)) -> Void) {
        if let m = generativo {
            poi(m)
            return
        }
        let vera = dati.impostazioni.vera
        veraInCorso = true
        Task { @MainActor in
            let d = await MotoreLocale.verificaDispositivo(vera)
            if self.disponibilitaLocale != d { self.disponibilitaLocale = d }
            self.veraInCorso = false
            if let m = self.generativo { poi(m) } else { self.qwenNonPronto(cliente: id) }
        }
    }

    /// Il messaggio di Vera quando Qwen non c'è: il motivo e cosa fare.
    func qwenNonPronto(cliente id: String) {
        let motivo = disponibilitaLocale.motivo ?? "Qwen non risponde."
        aggiungiMessaggio(MessaggioVera(autore: .vera, testo: motivo + " Vera risponde solo con Qwen: quando è pronto, rifai la domanda.",
                                       titolo: "Qwen non è pronto", motore: "Prisma"), cliente: id)
    }

    /// Chiede a Ollama, sul Mac, se Qwen è pronto (all'avvio, aprendo Vera e dalle impostazioni).
    func verificaMotoreLocale() {
        guard persistente else { return }
        let vera = dati.impostazioni.vera
        Task {
            let d = await MotoreLocale.verificaDispositivo(vera)
            DispatchQueue.main.async { if self.disponibilitaLocale != d { self.disponibilitaLocale = d } }
        }
    }

    /// All'avvio, qualche secondo dopo la finestra: se serve apre Ollama e carica il modello (solo sul Mac).
    func preparaVera() {
        guard persistente else { return }
        #if os(macOS)
        guard dati.impostazioni.vera.prontaAllAvvio else { return verificaMotoreLocale() }
        DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaPreparazioneVera) { [weak self] in
            guard let self else { return }
            let vera = self.dati.impostazioni.vera
            Task.detached(priority: .utility) {
                let d = await AvvioModello.prepara(vera)
                await MainActor.run { if self.disponibilitaLocale != d { self.disponibilitaLocale = d } }
            }
        }
        #else
        verificaMotoreLocale()
        #endif
    }

    static let attesaPreparazioneVera: TimeInterval = 3

    /// Dove si trova il consulente: per la riga di contesto di Vera.
    func ambienteVera(cliente id: String) -> AmbienteVera {
        AmbienteVera(oggi: Date(), appAperte: finestre.map { $0.app.titolo }, cliente: cliente(id)?.nome)
    }

    func conversazione(_ id: String) -> [MessaggioVera] {
        dati.impostazioni.vera.conservaConversazioni ? (dati.conversazioni[id] ?? []) : (conversazioniTemporanee[id] ?? [])
    }

    func aggiungiMessaggio(_ m: MessaggioVera, cliente id: String, parla: Bool = true) {
        var elenco = conversazione(id)
        elenco.append(m)
        elenco = Array(elenco.suffix(Self.massimoMessaggi))
        if dati.impostazioni.vera.conservaConversazioni {
            dati.conversazioni[id] = elenco
        } else {
            conversazioniTemporanee[id] = elenco
        }
        if m.autore == .vera, parla { parlaRisposta(m) }
    }

    /// La modalità che la testata di Vera mostra: quella scelta, altrimenti quella dell'ultima risposta (lavoro se
    /// non ce n'è ancora). Il portafoglio parla sempre con le cifre di Prisma: lavoro.
    var modalitaVeraMostrata: ModalitaVera {
        if veraPortafoglio { return .lavoro }
        if let m = modalitaVeraScelta { return m }
        return conversazione(clienteAttivoId).last { $0.autore == .vera && $0.modalita != nil }?.modalita ?? .lavoro
    }

    func nuovaConversazione() {
        let id = veraPortafoglio ? VeraPortafoglio.chiave : clienteAttivoId
        modalitaVeraScelta = nil
        // Una risposta ancora in arrivo si ferma qui, e lo scenario lasciato a metà
        scenarioInSospeso = nil
        compitoVera?.cancel()
        compitoVera = nil
        // Il compito fermato non torna a rimettere Vera libera: lo si fa qui
        veraInCorso = false
        dati.conversazioni[id] = nil
        conversazioniTemporanee[id] = nil
        // Il riassunto del filo lungo va con la conversazione
        if memoriaVera.filo(id) != nil { memoriaVera.aggiornaFilo(id, nil) }
    }

    /// Una domanda a Vera sul portafoglio (tutti i clienti). Le cifre sono quelle della vista Portafoglio;
    /// Qwen le racconta senza cambiarle (se cambia una cifra restano quelle di Prisma).
    @discardableResult
    func chiediVeraPortafoglio(_ domanda: String, spunto: SpuntoPortafoglio? = nil, breve: Bool = false, scenari: Bool = true, smista: Bool = true) -> Bool {
        let testo = domanda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty, !veraInCorso else { return false }
        // La domanda parte da tastiera o da uno spunto: la dettatura del Mac si spegne (anche per i comandi)
        if dettaturaAttiva { chiudiDettatura() }
        // Comandi, «sì»/«no» alla scheda, domande su tutti i clienti, «Fallo tu» (FalloTuShell.swift)
        if spunto == nil, smista, smistaVera(testo, chiave: VeraPortafoglio.chiave) { return true }
        // «E se Marco va in pensione a 63 anni?»: lo scenario di un cliente nominato lo calcola Prisma (ScenariVeraShell.swift)
        if spunto == nil, scenari, chiediScenarioVera(testo, chiave: VeraPortafoglio.chiave, breve: breve) { return true }
        let id = VeraPortafoglio.chiave
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: id)
        domandaVera = ""
        let argomento = spunto ?? SpuntoPortafoglio.da(testo)
        let bozza = VeraPortafoglio.risposta(argomento, domanda: testo, dati: dati.istantanea)
        if rispostePreparate {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: bozza.testo, titolo: bozza.titolo, motore: MotoriVera.sintesi.nome), cliente: id)
            return true
        }
        let scheda = VeraPortafoglio.scheda(dati.istantanea)
        let istruzioni = (IstruzioniVera.testo("chat") ?? "") + "\nQui parli del portafoglio del consulente (tutti i clienti), non di un singolo cliente."
            + (breve ? "\n\n" + IstruzioniVera.mini : "")
        let richiesta = "SCHEDA DEL PORTAFOGLIO (calcolata da Prisma)\n\(scheda)\n\nBOZZA PREPARATA DA PRISMA (numeri esatti: non cambiarli e non aggiungerne)\n\(bozza.testo)\n\nDOMANDA DEL CONSULENTE: \(testo)"
        conQwen(cliente: id) { modello in
            self.veraInCorso = true
            Task { @MainActor in
                do {
                    let t = try await modello.genera(istruzioni: istruzioni, richiesta: richiesta)
                    let pulito = t.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    // Ogni cifra della risposta deve venire dalla scheda o dalla bozza: altrimenti restano le cifre di Prisma
                    let fedele = !pulito.isEmpty && CommentoVera.numeriConservati(bozza: scheda + "\n" + bozza.testo, testo: pulito)
                    var m = MessaggioVera(autore: .vera, testo: fedele ? pulito : bozza.testo, titolo: bozza.titolo,
                                          motore: fedele ? modello.nome : MotoriVera.sintesi.nome)
                    // «Mai a caso»: le fonti delle cifre scritte da Qwen (FontiVera.swift)
                    if fedele {
                        let f = FontiVera.fonti(pulito, fonte: nil, richiesta: richiesta)
                        if !f.isEmpty { m.fonti = f }
                    }
                    self.aggiungiMessaggio(m, cliente: id)
                } catch {
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: modello.nome), cliente: id)
                }
                self.veraInCorso = false
            }
        }
        return true
    }

    /// Ciò che Vera sa del cliente: dati del dossier e risultati dei motori di Prisma.
    func fonteVera(_ id: String) -> FonteVera? {
        guard let c = cliente(id) else { return nil }
        return FonteVera(oggi: Date(), nomeUtente: nomeUtente, cliente: c, posizioni: posizioniCliente(id),
                        appuntamenti: appuntamentiCliente(id), attivita: attivitaCliente(id),
                        analisi: analisi360(id), analisiSalvata: analisiSalvata(id), simulazioni: simulazioniCliente(id),
                        incontri: incontriCliente(id), obiettivi: obiettiviCliente(id), prodotti: dati.prodotti, documenti: documentiCliente(id),
                        note: noteCliente(id).filter { !$0.vuota }, confronto: confrontoVera(id), anniConfronto: orizzonteSostituzione)
    }

    /// Il confronto aperto in Prospetti e report, se riguarda questo cliente.
    private func confrontoVera(_ id: String) -> (attuale: String, alternativa: String)? {
        guard case .sostituzione(let a, let b, _)? = prospetto,
              posizioni.contains(where: { $0.id == a && $0.clienteId == id }) else { return nil }
        return (a, b)
    }

    /// Fa spiegare a Vera un documento del cliente: dati con la pagina, confronto con il dossier,
    /// cosa resta da verificare. Qwen la rende discorsiva sulle stesse cifre.
    func spiegaDocumentoConVera(_ docId: String) {
        guard !veraInCorso, let d = documento(docId) else { return }
        clienteAttivoId = d.clienteId
        let id = d.clienteId
        guard let fonte = fonteVera(id) else { return }
        apri(.vera)
        let domanda = "Spiegami il documento «\(d.titolo)»"
        let bozza = MotoriVera.sintesi.documento(d, fonte: fonte)
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: id)
        if rispostePreparate {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: bozza.testo, titolo: bozza.titolo, motore: MotoriVera.sintesi.nome), cliente: id)
            return
        }
        // Al modello: la bozza con i dati esatti e un estratto delle prime pagine, entro la sua finestra
        let estratto = String(testoDocumento(d).joined(separator: "\n").prefix(ContestoVera.limiteCalcoli))
        let richiesta = "DOMANDA DEL CONSULENTE\n\(domanda)\n\nBOZZA PREPARATA DA PRISMA (dati estratti con la pagina: non cambiarli e non aggiungerne)\n"
            + String(bozza.testo.prefix(ContestoVera.limiteCalcoli))
            + "\n\nESTRATTO DEL DOCUMENTO\n\(estratto)\n\nSpiega il documento al consulente in modo ordinato, con le pagine, e segnala cosa verificare."
        conQwen(cliente: id) { modello in
            self.veraInCorso = true
            Task { @MainActor in
                do {
                    let r = try await modello.genera(istruzioni: IstruzioniVera.chat, richiesta: richiesta).trimmingCharacters(in: .whitespacesAndNewlines)
                    // Cifre diverse da quelle del documento: restano i dati estratti da Prisma, con le pagine
                    let fedele = !r.isEmpty && CommentoVera.numeriConservati(bozza: bozza.testo + "\n" + estratto, testo: r)
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: fedele ? r : bozza.testo, titolo: bozza.titolo,
                                                        motore: fedele ? modello.nome : MotoriVera.sintesi.nome), cliente: id)
                } catch {
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: modello.nome), cliente: id)
                }
                self.veraInCorso = false
            }
        }
    }

    // MARK: - Commento del consulente nei report

    func commento(_ scelta: SceltaProspetto) -> CommentoReport? {
        guard let chiave = scelta.chiaveCommento(cliente: clienteAttivoId) else { return nil }
        return dati.commenti.first { $0.id == chiave }
    }

    func salvaCommento(_ scelta: SceltaProspetto, testo: String, bozzaDi: String? = nil) {
        guard let chiave = scelta.chiaveCommento(cliente: clienteAttivoId) else { return }
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        dati.commenti.removeAll { $0.id == chiave }
        guard !pulito.isEmpty else { return }
        dati.commenti.append(CommentoReport(id: chiave, clienteId: clienteAttivoId, testo: String(pulito.prefix(CommentoVera.limite)),
                                            bozzaDi: bozzaDi, aggiornatoIl: Appuntamento.alMinuto(Date())))
    }

    /// La bozza del commento composta dai testi del documento (stesse frasi e cifre del report).
    func bozzaCommento(_ scelta: SceltaProspetto) -> String? {
        let id = clienteAttivoId
        let nome = cliente(id)?.nome ?? ""
        switch scelta {
        case .checkUp:
            let t = testiCheckUp(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio la prima fotografia della tua situazione che abbiamo costruito insieme: cosa è in ordine e da dove conviene partire.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .resoconto:
            let t = testiResoconto(id)
            return CommentoVera.bozza(nome: nome, apertura: "ecco il punto sulle tue posizioni: cosa hai, come stanno andando, quanto costano e quanto incasseresti oggi al netto delle imposte.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .previdenza:
            let t = testiPrevidenza(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio il quadro della tua pensione: quanto potrebbe mancare, quanto aggiungono i tuoi piani e quanto ti restituisce il fisco sui versamenti.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .protezione:
            let t = testiProtezione(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio il quadro della protezione della tua famiglia: cosa è già coperto e cosa ancora no.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .patrimonio:
            let t = testiPatrimonio(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio il percorso del tuo patrimonio nei prossimi anni: dove ti porta la strada di oggi e dove potresti arrivare con le proposte che abbiamo visto.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .successione:
            let t = testiSuccessione(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio il quadro di come passerebbe il tuo patrimonio alla tua famiglia: cosa arriva subito, cosa con la successione e cosa conviene sistemare oggi.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .costi:
            let t = testiCosti(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio il quadro dei costi dei tuoi investimenti: quanto paghi, quanto pesa nel tempo e cosa ricevi in cambio.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .resistenza:
            let t = testiResistenza(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio la prova di resistenza dei tuoi risparmi: cosa potrebbe succedere in tre anni difficili e se è una perdita che puoi sopportare.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .liquidita:
            let t = testiLiquidita(id)
            return CommentoVera.bozza(nome: nome, apertura: "ti lascio qualche idea su come far lavorare il capitale che arriva e la liquidità che hai, secondo quando ti servirà.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .obiettivo(let oid, _):
            guard let t = testiObiettivo(oid) else { return nil }
            return CommentoVera.bozza(nome: nome, apertura: "ecco il punto sul tuo obiettivo «\(t.o.titolo)»: dove sei, dove arrivi e cosa serve per raggiungerlo.",
                                     punti: t.sintesi, passo: t.prossimiPassi.first)
        case .sostituzione(let a, let b, _):
            guard let t = testiSostituzione(a, b) else { return nil }
            let punti = [("Il verdetto", t.titoloVerdetto + "."), ("Le cifre", t.sottotitoloVerdetto)].filter { !$0.1.isEmpty }
            return CommentoVera.bozza(nome: nome, apertura: t.e.sostituzione ? "ti lascio il confronto tra restare in \(t.a.nome) e passare a \(t.b.nome), con quello che costa uscire e quello che rende ciascuna strada."
                                                                            : "ti lascio il confronto tra \(t.a.nome) e \(t.b.nome), al netto di costi e imposte.",
                                     punti: punti, passo: t.prossimiPassi.first)
        case .posizione, .confronto, .valutazione, .portafoglio, .riesame, .fascicolo, .annoInsieme:
            return nil
        }
    }

    /// Fa scrivere a Vera il commento del report aperto (il consulente poi lo rilegge e lo modifica).
    func scriviCommentoConVera(_ scelta: SceltaProspetto) {
        guard !veraInCorso, let bozza = bozzaCommento(scelta) else { return }
        let id = clienteAttivoId
        if rispostePreparate {
            salvaCommento(scelta, testo: bozza, bozzaDi: MotoriVera.sintesi.nome)
            return
        }
        guard let modello = generativo else {
            verificaMotoreLocale()
            mostraAvviso((disponibilitaLocale.motivo ?? "Qwen non risponde.") + " Il commento lo scrive Vera con Qwen: quando è pronto, riprova.")
            return
        }
        veraInCorso = true
        Task { @MainActor in
            let r = await CommentoVera.scrivi(bozza: bozza, modello: modello)
            if self.clienteAttivoId == id { self.salvaCommento(scelta, testo: r.testo, bozzaDi: r.motore) }
            self.veraInCorso = false
        }
    }

    /// Fa spiegare a Vera il documento aperto in Prospetti e report.
    func chiediVeraDelDocumento(_ scelta: SceltaProspetto) {
        guard let s = scelta.spuntoVera else { return }
        apri(.vera)
        chiediVera(s.domanda, spunto: s)
    }

    /// Manda una domanda a Vera per il cliente attivo.
    @discardableResult
    func chiediVera(_ domanda: String, spunto: SpuntoVera? = nil, breve: Bool = false, scenari: Bool = true, smista: Bool = true) -> Bool {
        let testo = domanda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty, !veraInCorso else { return false }
        // La domanda parte da tastiera o da uno spunto: la dettatura del Mac si spegne (anche per i comandi)
        if dettaturaAttiva { chiudiDettatura() }
        // Comandi, «sì»/«no» alla scheda, domande su tutti i clienti, «Fallo tu» (FalloTuShell.swift)
        if spunto == nil, smista, smistaVera(testo, chiave: clienteAttivoId) { return true }
        // «E se Marco va in pensione a 63 anni?»: lo scenario lo calcola Prisma, Vera lo racconta (ScenariVeraShell.swift)
        if spunto == nil, scenari, chiediScenarioVera(testo, chiave: clienteAttivoId, breve: breve) { return true }
        let id = clienteAttivoId
        guard let fonte = fonteVera(id) else { return false }
        let storia = conversazione(id)
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: id)
        domandaVera = ""
        let richiesta = RichiestaVera(domanda: testo, spunto: spunto ?? SpuntoVera.da(testo), fonte: fonte, storia: storia)
        if rispostePreparate {
            let r = MotoriVera.sintesi.componi(richiesta)
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: r.testo, titolo: r.titolo, motore: MotoriVera.sintesi.nome, proposte: r.proposte), cliente: id)
            return true
        }
        // Le azioni proposte restano quelle calcolate da Prisma, anche quando il testo lo scrive Qwen
        let proposte = richiesta.spunto == .proposte ? MotoriVera.sintesi.componi(richiesta).proposte : nil
        var ambiente = ambienteVera(cliente: id)
        ambiente.breve = breve
        // La modalità scelta nella testata di Vera (la mini finestra decide da sé, con le sue cifre)
        if !breve { ambiente.modalita = modalitaVeraScelta }
        // Fase 2: i ricordi pertinenti e il filo delle battute uscite dalla finestra (VeraFaseDueShell.swift)
        ambiente.ricordi = ricordiPerVera(cliente: id)
        var piano = NucleoVera.piano(richiesta, impostazioni: dati.impostazioni.vera, ambiente: ambiente)
        var uscite = NucleoVera.uscite(storia, piano: piano)
        // Il riassunto allunga l'ultimo messaggio: possono uscire altre battute, che vanno riassunte anche loro
        for _ in 0..<3 {
            guard let r = riassuntoVera(chiave: id, uscite: uscite) else { break }
            ambiente.riassunto = r
            piano = NucleoVera.piano(richiesta, impostazioni: dati.impostazioni.vera, ambiente: ambiente)
            let nuove = NucleoVera.uscite(storia, piano: piano)
            if nuove.count == uscite.count { break }
            uscite = nuove
        }
        let usciteIniziali = uscite
        let ricordiProposti = schedaRicordi(da: testo, chiave: id)
        let pianoIniziale = piano
        let ambienteIniziale = ambiente
        conQwen(cliente: id) { _ in
            // La risposta arriva a pezzi e si vede mentre Vera la scrive (FlussoVera, bolla in arrivo)
            let motore = self.qwen
            self.veraInCorso = true
            let generazione = self.flussoVera.inizia(pianoIniziale.scelta, motore: motore.nome)
            self.compitoVera = Task { @MainActor in
                var piano = pianoIniziale
                var ambiente = ambienteIniziale
                var uscite = usciteIniziali
                do {
                    // In lavoro, i passaggi dei documenti e delle note trovati con la ricerca (fase 2)
                    if piano.scelta.conScheda, !breve {
                        let brani = await self.braniPerVera(testo, cliente: id)
                        if !brani.isEmpty {
                            ambiente.brani = brani
                            piano = NucleoVera.piano(richiesta, impostazioni: self.dati.impostazioni.vera, ambiente: ambiente)
                            let dopo = NucleoVera.uscite(storia, piano: piano)
                            if dopo.count > uscite.count, let r = self.riassuntoVera(chiave: id, uscite: dopo) {
                                uscite = dopo
                                ambiente.riassunto = r
                                piano = NucleoVera.piano(richiesta, impostazioni: self.dati.impostazioni.vera, ambiente: ambiente)
                            }
                        }
                    }
                    // I pezzi arrivano fuori dal thread principale: la bolla si aggiorna sul principale
                    let r = try await motore.scrivi(piano) { p in
                        DispatchQueue.main.async { self.flussoVera.aggiorna(p, generazione: generazione) }
                    }
                    var m = MessaggioVera(autore: .vera, testo: r.testo, motore: motore.nome, proposte: proposte)
                    m.modalita = piano.scelta.modalita
                    // «Mai a caso»: in lavoro ogni cifra ha la sua fonte, o resta «non trovata» (FontiVera.swift)
                    if piano.scelta.conScheda {
                        let f = FontiVera.fonti(r.testo, fonte: fonte, richiesta: piano.messaggi.last?.testo ?? "")
                        if !f.isEmpty { m.fonti = f }
                    }
                    // «La memoria»: i ricordi che Vera propone dalla tua domanda, salvati solo dopo «Ricorda»
                    m.conferma = ricordiProposti
                    self.aggiungiMessaggio(m, cliente: id)
                    // «Il filo lungo»: le battute uscite si riassumono in background
                    self.aggiornaFiloVera(chiave: id, uscite: uscite, motore: motore)
                } catch is CancellationError {
                    // Nuova conversazione: la risposta interrotta non resta
                } catch {
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: motore.nome, proposte: proposte), cliente: id)
                }
                self.flussoVera.chiudi()
                self.veraInCorso = false
                self.compitoVera = nil
            }
        }
        return true
    }

    // MARK: - Confronto tra modelli

    /// Le stesse domande di prova ai modelli scelti in Impostazioni › Vera, sui dati di prova: il rapporto
    /// (una pagina con le risposte e i tempi affiancati) si apre a confronto finito.
    func confrontaModelli() {
        #if os(macOS)
        guard avanzamentoConfronto == nil else { return }
        let modelli = ConfrontoModelli.elenco(dati.impostazioni.vera.modelliConfronto)
        guard !modelli.isEmpty else { return mostraAvviso("Scrivi i modelli da confrontare, separati da virgole.") }
        // I dati di prova di Prisma, mai quelli dei clienti veri
        guard let fonte = StatoShell(persistente: false).fonteVera(ConfrontoModelli.clienteProva) else { return }
        let vera = dati.impostazioni.vera
        avanzamentoConfronto = "Preparo il confronto…"
        Task { @MainActor in
            let r = await ConfrontoModelli.esegui(modelli: modelli, vera: vera, fonte: fonte) { passo in
                Task { @MainActor in self.avanzamentoConfronto = passo }
            }
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("Confronto modelli di Vera.html")
            do {
                try ConfrontoModelli.html(r).write(to: file, atomically: true, encoding: .utf8)
                self.rapportoConfronto = file
                NSWorkspace.shared.open(file)
            } catch {
                self.mostraAvviso("Il rapporto del confronto non si è potuto salvare: \(error.localizedDescription)")
            }
            self.avanzamentoConfronto = nil
        }
        #else
        mostraAvviso(StatoShell.soloSulMacPerOra)
        #endif
    }

    // MARK: - Proposte di Vera

    /// Un'azione proposta da Vera diventa un'attività del cliente (entro una settimana).
    func attivitaDaProposta(_ p: PropostaVera, messaggio: String) {
        var t = Attivita.nuova(clienteId: clienteAttivoId,
                               scadenza: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        t.titolo = p.titolo
        t.note = "Proposta da Vera: \(p.perche)"
        dati.attivita.append(t)
        aggiornaProposta(p.id, messaggio: messaggio) { $0.attivitaId = t.id }
        mostraAvviso("Attività aggiunta: \(t.titolo)")
    }

    /// Un'azione proposta da Vera diventa una bozza di proposta in Posizioni, da completare.
    func posizioneDaProposta(_ p: PropostaVera, messaggio: String) {
        if let id = p.posizioneId, let esistente = posizioni.first(where: { $0.id == id }) {
            apriPosizione(esistente)
            return
        }
        guard let area = p.area else { return }
        let canali = cliente(clienteAttivoId)?.canali ?? []
        let canale = canali.contains(.alleanza) || canali.isEmpty ? Canale.alleanza : canali[0]
        var nuova = Posizione(clienteId: clienteAttivoId, canale: canale, stato: .proposta, area: area, nome: p.titolo)
        nuova.esito = .bozza
        nuova.rischio = p.rischio
        nuova.capitaleAssicurato = p.capitale
        if let v = p.versamentoMensile {
            nuova.premio = v
            nuova.frequenza = .mensile
        }
        if let i = p.importo, p.versamentoMensile == nil { nuova.versamentoIniziale = i }
        nuova.note = "Preparata con Vera: \(p.perche) Scegli prodotto e canale e completa i dati."
        salvaPosizione(nuova)
        aggiornaProposta(p.id, messaggio: messaggio) { $0.posizioneId = nuova.id }
        apriPosizione(nuova)
    }

    private func aggiornaProposta(_ id: String, messaggio: String, _ modifica: (inout PropostaVera) -> Void) {
        let cliente = clienteAttivoId
        func aggiorna(_ elenco: inout [MessaggioVera]) {
            guard let m = elenco.firstIndex(where: { $0.id == messaggio }),
                  let i = elenco[m].proposte?.firstIndex(where: { $0.id == id }) else { return }
            modifica(&elenco[m].proposte![i])
        }
        if dati.impostazioni.vera.conservaConversazioni {
            var elenco = dati.conversazioni[cliente] ?? []
            aggiorna(&elenco)
            dati.conversazioni[cliente] = elenco
        } else {
            var elenco = conversazioniTemporanee[cliente] ?? []
            aggiorna(&elenco)
            conversazioniTemporanee[cliente] = elenco
        }
    }

    /// Trasforma una risposta di Vera in un'attività per il cliente.
    func attivitaDaVera(_ m: MessaggioVera) {
        var t = Attivita.nuova(clienteId: clienteAttivoId,
                               scadenza: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        t.titolo = m.titolo ?? String(m.testo.prefix(80))
        t.note = m.testo
        dati.attivita.append(t)
        mostraAvviso("Attività aggiunta: \(t.titolo)")
    }

    /// Aggiunge una risposta di Vera alla nota del cliente.
    func notaDaVera(_ m: MessaggioVera) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == clienteAttivoId }) else { return }
        let aggiunta = (m.titolo.map { $0 + "\n" } ?? "") + m.testo
        dati.clienti[i].nota = dati.clienti[i].nota.isEmpty ? aggiunta : dati.clienti[i].nota + "\n\n" + aggiunta
        mostraAvviso("Aggiunto alla nota di \(dati.clienti[i].nome)")
    }

    // MARK: - Agenda

    /// Appuntamenti del giorno, filtrati per cliente, in ordine d'orario.
    func appuntamentiDelGiorno(_ giorno: Date) -> [Appuntamento] {
        let cal = Calendar.current
        return appuntamenti
            .filter { cal.isDate($0.inizio, inSameDayAs: giorno) && (filtroClienteAgenda == nil || $0.clienteId == filtroClienteAgenda) }
            .sorted { $0.inizio < $1.inizio }
    }

    /// Appuntamenti (filtrati per cliente) e scadenze dei giorni indicati, raggruppati per giorno
    /// in un solo passaggio: la settimana o il mese dell'agenda non rileggono l'archivio per ogni casella.
    /// Il body dell'Agenda lo chiede a ogni disegno: tenuto da parte in DerivatiDati per intervallo, filtro cliente e
    /// strato delle occasioni, finché non cambiano i dati dei calcoli, il giorno o la modalità cliente.
    func giorniAgenda(_ giorni: [Date]) -> GiorniAgenda {
        let cal = Calendar.current
        guard let primo = giorni.min(), let ultimo = giorni.max() else { return GiorniAgenda() }
        let d = derivatiValidi()
        let k = DerivatiDati.ChiaveGiorniAgenda(inizio: cal.startOfDay(for: primo), fine: cal.startOfDay(for: ultimo),
                                                filtro: filtroClienteAgenda, occasioni: dati.impostazioni.occasioni.inAgenda)
        if let indice = d.indiciAgenda[k] { return indice }
        let indice = calcolaGiorniAgenda(primo: primo, ultimo: ultimo)
        if d.indiciAgenda.count >= DerivatiDati.vociMassimeAgenda { d.indiciAgenda.removeAll() }
        d.indiciAgenda[k] = indice
        return indice
    }

    /// Il raggruppamento dei giorni dell'Agenda, senza memoria (da `giorniAgenda`).
    private func calcolaGiorniAgenda(primo: Date, ultimo: Date) -> GiorniAgenda {
        let cal = Calendar.current
        var indice = GiorniAgenda()
        let inizio = cal.startOfDay(for: primo)
        let fine = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: ultimo)) ?? inizio
        let filtro = filtroClienteAgenda
        for a in appuntamenti where a.inizio >= inizio && a.inizio < fine && (filtro == nil || a.clienteId == filtro) {
            indice.perGiorno[cal.startOfDay(for: a.inizio), default: []].append(a)
        }
        for k in indice.perGiorno.keys { indice.perGiorno[k]?.sort { $0.inizio < $1.inizio } }
        for p in posizioni where p.stato == .inEssere && (filtro == nil || p.clienteId == filtro) {
            guard let s = p.scadenza, s >= inizio, s < fine else { continue }
            indice.scadenzePerGiorno[cal.startOfDay(for: s), default: []].append(p)
        }
        // Le occasioni, se lo strato è acceso: un passaggio solo, dalla memoria (AgendaOccasioni.swift)
        if dati.impostazioni.occasioni.inAgenda {
            for o in occasioni(da: inizio, a: fine) where filtro == nil || o.clienteId == filtro {
                indice.occasioniPerGiorno[cal.startOfDay(for: o.data), default: []].append(o)
            }
        }
        // Le attività per giorno di scadenza (Attività è accorpata nell'Agenda): prima le da fare, poi per priorità
        for t in attivita where t.scadenza >= inizio && t.scadenza < fine && (filtro == nil || t.clienteId == filtro) {
            indice.attivitaPerGiorno[cal.startOfDay(for: t.scadenza), default: []].append(t)
        }
        for k in indice.attivitaPerGiorno.keys { indice.attivitaPerGiorno[k]?.sort(by: StatoShell.ordineAttivita) }
        return indice
    }

    func appuntamento(_ id: String?) -> Appuntamento? {
        guard let id else { return nil }
        return appuntamenti.first { $0.id == id }
    }

    /// Mostra in agenda il giorno di un appuntamento e lo seleziona.
    func mostraInAgenda(_ a: Appuntamento) {
        giornoAgenda = Calendar.current.startOfDay(for: a.inizio)
        appuntamentoSelezionato = a.id
        occasioneSelezionata = nil
        // L'elenco delle occasioni non mostra gli appuntamenti: si torna al mese
        if vistaAgenda == .occasioni { vistaAgenda = .mese }
        if filtroClienteAgenda != nil && filtroClienteAgenda != a.clienteId { filtroClienteAgenda = nil }
        apri(.agenda)
    }

    /// La bozza dell'appuntamento per richiamare un cliente: una telefonata il prossimo giorno
    /// lavorativo, con il motivo e l'ultimo contatto nelle note. Si completa nel modulo dell'agenda.
    func bozzaRicontatto(_ d: Portafoglio.DaRicontattare, oggi: Date = Date()) -> Appuntamento {
        let cal = Calendar.current
        var giorno = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: oggi)) ?? oggi
        while cal.isDateInWeekend(giorno) { giorno = cal.date(byAdding: .day, value: 1, to: giorno) ?? giorno }
        var a = Appuntamento.nuovo(clienteId: d.cliente.id, giorno: giorno)
        a.titolo = d.motivo.map { "Ci risentiamo: \($0)" } ?? "Ci risentiamo"
        a.tipo = .telefonata
        a.luogo = "Telefonata"
        a.durataMinuti = 20
        a.note = [d.motivo.map { "Motivo: \($0)." },
                  d.ultimoContatto.map { "Ultimo contatto il \(Formati.dataEstesa.string(from: $0))." } ?? "Nessun incontro registrato in Prisma."]
            .compactMap { $0 }.joined(separator: " ")
        return a
    }

    /// La bozza dell'incontro di riesame: un'ora nel primo spazio libero degli orari di lavoro (da domani),
    /// con canale e ordine del giorno nelle note. Si completa nel modulo dell'agenda.
    func bozzaRiesame(_ clienteId: String, oggi: Date = Date()) -> Appuntamento? {
        pianificaRiesame(clienteId, oggi: oggi)?.appuntamento
    }

    func salvaAppuntamento(_ a: Appuntamento) {
        var x = a
        x.titolo = x.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        x.luogo = x.luogo.trimmingCharacters(in: .whitespacesAndNewlines)
        // Lo stato di prima: «Incontro concluso» acceso nel modulo chiede l'esito della proposta
        let prima = dati.appuntamenti.first { $0.id == x.id }?.stato
        if let i = dati.appuntamenti.firstIndex(where: { $0.id == x.id }) {
            dati.appuntamenti[i] = x
        } else {
            dati.appuntamenti.append(x)
        }
        if prima == .pianificato && x.stato == .concluso { segnaConclusione(x.id) }
        giornoAgenda = Calendar.current.startOfDay(for: x.inizio)
        appuntamentoSelezionato = x.id
        occasioneSelezionata = nil
        // L'appuntamento salvato (anche quello preparato da un'occasione) si vede nel suo mese
        if vistaAgenda == .occasioni { vistaAgenda = .mese }
        if filtroClienteAgenda != nil && filtroClienteAgenda != x.clienteId { filtroClienteAgenda = x.clienteId }
    }

    /// Elimina un appuntamento; le attività collegate restano, senza collegamento.
    func eliminaAppuntamento(_ id: String) {
        dati.appuntamenti.removeAll { $0.id == id }
        for i in dati.attivita.indices where dati.attivita[i].appuntamentoId == id {
            dati.attivita[i].appuntamentoId = nil
        }
        if appuntamentoSelezionato == id { appuntamentoSelezionato = nil }
    }

    func alternaConcluso(_ id: String) {
        guard let i = dati.appuntamenti.firstIndex(where: { $0.id == id }) else { return }
        dati.appuntamenti[i].stato = dati.appuntamenti[i].stato == .concluso ? .pianificato : .concluso
        // Seguito delle proposte: la proposta presentata e l'eventuale ripresa completata
        if dati.appuntamenti[i].stato == .concluso { segnaConclusione(id) }
        // Riesame con memoria: un riesame già avvenuto, segnato concluso, salva la fotografia
        let a = dati.appuntamenti[i]
        if a.stato == .concluso, a.tipo == .revisione, a.inizio <= Date() { fotografaRiesame(a.clienteId, origine: .appuntamento) }
    }

    // MARK: - Attività

    func alternaCompletata(_ id: String) {
        guard let i = dati.attivita.firstIndex(where: { $0.id == id }) else { return }
        dati.attivita[i].completata.toggle()
    }

    func salvaAttivita(_ a: Attivita) {
        var x = a
        x.titolo = x.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        if let i = dati.attivita.firstIndex(where: { $0.id == x.id }) {
            dati.attivita[i] = x
        } else {
            dati.attivita.append(x)
        }
        attivitaSelezionata = x.id
        if filtroClienteAttivita != nil && filtroClienteAttivita != x.clienteId { filtroClienteAttivita = x.clienteId }
        if filtroPrioritaAttivita != nil && filtroPrioritaAttivita != x.priorita { filtroPrioritaAttivita = nil }
        if filtroStatoAttivita == .completate && !x.completata { filtroStatoAttivita = .aperte }
    }

    func eliminaAttivita(_ id: String) {
        dati.attivita.removeAll { $0.id == id }
        if attivitaSelezionata == id { attivitaSelezionata = nil }
    }

    func attivitaCollegate(_ appuntamentoId: String) -> [Attivita] {
        attivita.filter { $0.appuntamentoId == appuntamentoId }.sorted { $0.scadenza < $1.scadenza }
    }

    // MARK: - Notifiche

    private func avviaNotifiche() {
        ricalcolaNotifiche()
        modificheDati
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.ricalcolaNotifiche() }
            .store(in: &abbonamenti)
        avviaTimerNotifiche()
    }

    /// Gli appuntamenti finiscono e i giorni cambiano anche senza toccare i dati: un ricalcolo al minuto,
    /// con la tolleranza che lascia a macOS raggruppare i risvegli.
    private func avviaTimerNotifiche() {
        timerNotifiche?.invalidate()
        aggiornaOrologioVista()
        let timer = Timer(timeInterval: StatoShell.intervalloNotifiche, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.aggiornaOrologioVista()
                self?.ricalcolaNotifiche()
            }
        }
        timer.tolerance = StatoShell.tolleranzaNotifiche
        RunLoop.main.add(timer, forMode: .default)
        timerNotifiche = timer
    }

    /// Porta `orologioVista` al giorno e all'ora di `adesso`; non tocca nulla (e non ridisegna nessuno) se sono gli stessi.
    func aggiornaOrologioVista(_ adesso: Date = Date()) {
        let nuovo = OrologioVista.di(adesso)
        if nuovo != orologioVista { orologioVista = nuovo }
    }

    func ricalcolaNotifiche() {
        let nuove = MotoreNotifiche.calcola(self)
        guard nuove != notifiche else { return }
        let primaNuove = notificheNuove
        notifiche = nuove
        // Il numero sulla campanella è cresciuto: l'evento «notifica nuova» (EventiShell.swift)
        annunciaNotificheNuove(prima: primaNuove)
    }

    /// Promemoria del Mac (vedi PromemoriaMac.swift): solo dentro Prisma.app con l'archivio sul disco.
    /// All'avvio legge il permesso senza chiederlo; poi ricalcola dopo le modifiche, al cambio di giorno
    /// e tornando a Prisma.
    private func avviaPromemoria() {
        guard persistente, PromemoriaMac.disponibili else { return }
        PromemoriaMac.condiviso.collega(self)
        if dati.impostazioni.promemoria.attivi {
            aggiornaPromemoria()
        } else {
            // Spenti: niente promemoria rimasti da una sessione di prima
            PromemoriaMac.condiviso.spegni()
        }
        aggiornaPermessoPromemoria()
        modificheDati
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.aggiornaPromemoria() }
            .store(in: &abbonamenti)
        // Dopo lo stop del Mac li ricalcola la ripresa dei lavori (RipresaSistema.swift)
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Il giorno delle cache si rifà alla prossima richiesta (anche con i lavori in pausa)
                self.riverificaGiornoDerivati()
                guard !self.lavoriInPausa else { return }
                self.aggiornaPromemoria()
            }
            .store(in: &abbonamenti)
        // Un altro fuso orario: anche «oggi» delle cache va rifatto
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.riverificaGiornoDerivati() }
            .store(in: &abbonamenti)
        // Tornando a Prisma (⌘Tab) al massimo una volta ogni mezzo minuto; il calcolo è in background
        #if os(macOS)
        let tornaAttiva = NSApplication.didBecomeActiveNotification
        #elseif os(iOS)
        let tornaAttiva = UIApplication.didBecomeActiveNotification
        #endif
        NotificationCenter.default.publisher(for: tornaAttiva)
            .receive(on: DispatchQueue.main)
            .throttle(for: .seconds(StatoShell.intervalloRitornoAttivo), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self, !self.lavoriInPausa else { return }
                self.aggiornaPermessoPromemoria()
                self.aggiornaPromemoria()
            }
            .store(in: &abbonamenti)
    }

    // MARK: - Salvataggio

    /// Salva l'archivio 0,8 s dopo l'ultima modifica, in background (codifica e scrittura non fermano le
    /// animazioni), e alla chiusura dell'app. Dati non cambiati dall'ultimo salvataggio non si riscrivono.
    private func avviaSalvataggio() {
        modificheDati
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.scrivi() }
            .store(in: &abbonamenti)
        #if os(macOS)
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                // La finestra sparisce subito; poi si finisce di salvare (niente, se i dati non sono cambiati)
                NSApplication.shared.windows.forEach { $0.orderOut(nil) }
                self?.salvaOra()
            }
            .store(in: &abbonamenti)
        #elseif os(iOS)
        // Su iPhone e iPad la chiusura non si annuncia: si salva quando Prisma va in background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.salvaOra() }
            .store(in: &abbonamenti)
        #endif
    }

    /// Salva adesso e aspetta: quando torna, l'archivio sul disco è aggiornato. Lo usano backup,
    /// ripristino, riapertura e chiusura.
    func salvaOra() {
        guard persistente, !salvataggioSospeso else { return }
        scrivi()
        salvataggio.attendi()
    }

    /// Accoda il salvataggio dei dati di adesso (niente, se questa generazione è già sul disco o in coda).
    private func scrivi() {
        guard persistente, !salvataggioSospeso else { return }
        // L'istantanea è un valore: la copia va alla coda senza rischi, e la coda non legge mai `self.dati`
        salvataggio.accoda(dati.istantanea, generazione: versioneDati) { [weak self] errore in
            self?.mostraAvviso("Salvataggio non riuscito: \(errore.localizedDescription)")
        }
    }

    // MARK: - Lavori a tempo e stop del Mac

    /// Il primo controllo del backup automatico dopo l'avvio (lontano dalla pulizia dei documenti).
    static let primoControlloBackup: Double = 45
    /// La pulizia dei documenti non più usati, dopo l'avvio.
    static let attesaPulizia: Double = 5
    /// Il backup automatico si controlla circa una volta l'ora, quando il Mac è libero.
    static let intervalloBackup: Double = 3600
    static let tolleranzaBackup: Double = 900
    /// Notifiche ricalcolate una volta al minuto.
    static let intervalloNotifiche: Double = 60
    static let tolleranzaNotifiche: Double = 10
    /// Tornando a Prisma i promemoria si ricalcolano al massimo ogni 30 s.
    static let intervalloRitornoAttivo = 30
    /// Dopo il risveglio del Mac i controlli aspettano un minuto: il risveglio resta libero.
    static let attesaDopoRisveglio: Double = 60

    /// Prima dello stop del Mac (o con lo schermo spento): timer fermi, controlli rimandati, dati cambiati
    /// accodati per il disco.
    func sospendiLavoriATempo() {
        ripresaLavori?.cancel()
        ripresaLavori = nil
        scrivi()
        guard !lavoriInPausa else { return }
        lavoriInPausa = true
        timerNotifiche?.invalidate()
        timerNotifiche = nil
    }

    /// Dopo il risveglio: tra `attesa` secondi ripartono notifiche, promemoria e controllo del backup.
    func riprendiLavoriATempo(dopo attesa: Double) {
        guard lavoriInPausa else { return }
        ripresaLavori?.cancel()
        let lavoro = DispatchWorkItem { [weak self] in
            guard let self, self.lavoriInPausa else { return }
            self.ripresaLavori = nil
            self.lavoriInPausa = false
            self.avviaTimerNotifiche()
            self.ricalcolaNotifiche()
            self.aggiornaPromemoria()
            self.controllaBackupAutomatico()
        }
        ripresaLavori = lavoro
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa, execute: lavoro)
    }

    // MARK: - Backup

    var cartellaBackup: URL {
        dati.impostazioni.backup.cartella.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? Archivio.cartellaBackupPredefinita
    }

    /// true se i backup stanno ancora sullo stesso Mac dell'archivio.
    var cartellaBackupPredefinita: Bool { dati.impostazioni.backup.cartella == nil }

    func scegliCartellaBackup(_ url: URL) {
        // Dentro la cartella dell'archivio ogni backup conterrebbe i precedenti e il ripristino li cancellerebbe
        let archivio = Archivio.cartella.standardizedFileURL.path
        let scelta = url.standardizedFileURL.path
        guard scelta != archivio, !scelta.hasPrefix(archivio + "/") else {
            mostraAvviso("Scegli una cartella fuori dalla cartella di Prisma, meglio su iCloud Drive o su un disco esterno.")
            return
        }
        dati.impostazioni.backup.cartella = url.path
        aggiornaElencoBackup()
    }

    func aggiornaElencoBackup() {
        guard persistente else { return }
        let cartella = cartellaBackup
        DispatchQueue.global(qos: .utility).async {
            let elenco = GestoreBackup.elenca(cartella)
            DispatchQueue.main.async { self.elencoBackup = elenco }
        }
    }

    // MARK: - Password dei backup

    /// La password con cui proteggere i backup (nil = backup non protetti). Con la protezione
    /// attiva e la password non disponibile lancia `.passwordNonDisponibile`: niente backup in chiaro.
    /// - riprova: false per i backup automatici (il Portachiavi non si richiede a ogni controllo).
    func passwordPerBackup(riprova: Bool = true) throws -> String? {
        guard dati.impostazioni.backup.cifrato else { return nil }
        guard let password = passwordBackupNota(riprova: riprova) else { throw ErroreBackup.passwordNonDisponibile }
        return password
    }

    /// La password dei backup se è nota: in memoria, altrimenti dal Portachiavi (mai nelle prove
    /// e nelle istantanee).
    private func passwordBackupNota(riprova: Bool) -> String? {
        if let password = passwordBackupInMemoria { return password }
        guard persistente, riprova || !portachiaviLetto else { return nil }
        portachiaviLetto = true
        passwordBackupInMemoria = PortachiaviBackup.leggi()
        return passwordBackupInMemoria
    }

    /// Imposta o cambia la password dei backup: vale dai prossimi backup.
    /// false se è troppo corta o se il Portachiavi non l'ha salvata.
    @discardableResult
    func impostaPasswordBackup(_ password: String) -> Bool {
        guard password.count >= ImpostazioniBackup.lunghezzaMinimaPassword else { return false }
        if persistente, !PortachiaviBackup.salva(password) { return false }
        let cambio = dati.impostazioni.backup.cifrato
        passwordBackupInMemoria = password
        portachiaviLetto = true
        dati.impostazioni.backup.protetto = true
        if dati.impostazioni.backup.ultimoErrore == ErroreBackup.passwordNonDisponibile.localizedDescription {
            dati.impostazioni.backup.ultimoErrore = nil
        }
        mostraAvviso(cambio ? "Password dei backup cambiata: vale dai prossimi backup."
                            : "Backup protetti: da ora si aprono solo con la password.")
        // La chiave della memoria di Vera nel backup segue la password nuova
        memoriaVera.riavvolgiChiave(password: password)
        return true
    }

    /// Toglie la protezione: i prossimi backup sono .zip in chiaro; quelli protetti restano protetti.
    func togliPasswordBackup() {
        if persistente { PortachiaviBackup.elimina() }
        memoriaVera.riavvolgiChiave(password: nil)
        passwordBackupInMemoria = nil
        dati.impostazioni.backup.protetto = false
        if dati.impostazioni.backup.ultimoErrore == ErroreBackup.passwordNonDisponibile.localizedDescription {
            dati.impostazioni.backup.ultimoErrore = nil
        }
        mostraAvviso("Password tolta: i prossimi backup non sono protetti. Quelli già protetti si aprono con la loro password.")
    }

    /// Apre Impostazioni › Archivio con la richiesta della password dei backup.
    private func chiediPasswordBackupInImpostazioni() {
        schedaImpostazioni = .archivio
        apri(.impostazioni)
        // Dopo l'apertura della finestra, perché la richiesta abbia dove comparire
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.chiediPasswordBackup = true }
    }

    /// Un'operazione che prima salva un backup di sicurezza si ferma se il backup protetto non si può fare.
    private func annullaSenzaPassword(_ errore: Error, _ operazione: String) {
        mostraAvviso("\(operazione): \(errore.localizedDescription)")
        chiediPasswordBackupInImpostazioni()
    }

    /// Chiede la password di un backup protetto da ripristinare (dopo che la conferma si è chiusa).
    private func chiediPasswordRipristino(_ url: URL, messaggio: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.ripristinoDaSbloccare = RichiestaPasswordBackup(url: url, messaggio: messaggio)
        }
    }

    /// Crea un backup completo della cartella dell'archivio.
    func creaBackup(automatico: Bool = false) {
        guard persistente, !backupInCorso else { return }
        // Con la protezione attiva il backup si fa solo con la password, mai in chiaro
        let password: String?
        do {
            password = try passwordPerBackup(riprova: !automatico)
        } catch {
            let giaSegnalato = dati.impostazioni.backup.ultimoErrore == error.localizedDescription
            dati.impostazioni.backup.ultimoTentativo = Date()
            dati.impostazioni.backup.ultimoErrore = error.localizedDescription
            if !automatico || !giaSegnalato { mostraAvviso("Backup non fatto: \(error.localizedDescription)") }
            if !automatico { chiediPasswordBackupInImpostazioni() }
            return
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        dati.impostazioni.backup.ultimoTentativo = Date()
        DispatchQueue.global(qos: .utility).async {
            do {
                let url = try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione,
                                                 nota: automatico ? GestoreBackup.notaAutomatico : nil, creaCartella: creaCartella,
                                                 password: password)
                DispatchQueue.main.async {
                    self.backupInCorso = false
                    self.dati.impostazioni.backup.ultimo = Date()
                    self.dati.impostazioni.backup.ultimoErrore = nil
                    self.aggiornaElencoBackup()
                    self.mostraAvviso("Backup creato: \(url.lastPathComponent)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.backupInCorso = false
                    self.dati.impostazioni.backup.ultimoErrore = error.localizedDescription
                    self.mostraAvviso("Backup non riuscito: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Ripristina un backup. Prima salva una copia di sicurezza dello stato attuale.
    /// Un backup protetto si apre con `password scritta` (dalla richiesta) o con la password dei
    /// backup; se nessuna lo apre si chiede la password.
    func ripristina(_ zip: URL, password scritta: String? = nil) {
        guard persistente, !backupInCorso else { return }
        guard !ripristinoBloccato else { mostraAvviso("Archivio in sola lettura: apri l'ultima versione di Prisma per ripristinare."); return }
        // Riconosciuto dal contenuto: anche un backup protetto rinominato
        let protetto = CifraturaBackup.cifrato(zip)
        let daPortachiavi = protetto && scritta == nil
        let chiave: String? = protetto ? (scritta ?? passwordBackupNota(riprova: true)) : nil
        if protetto, chiave == nil {
            chiediPasswordRipristino(zip, messaggio: "«\(zip.lastPathComponent)» è protetto: scrivi la password con cui è stato fatto.")
            return
        }
        // La copia di sicurezza di prima del ripristino segue la protezione di oggi
        let perSicurezza: String?
        do {
            perSicurezza = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, "Ripristino annullato")
            return
        }
        salvaOra()
        salvataggioSospeso = true
        // Nessuna scrittura in coda deve arrivare sopra la cartella ripristinata
        salvataggio.attendi()
        StatoMemoriaVera.attendiScritture()
        StatoBiblioteca.attendiScritture()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        // Le impostazioni di backup e il nome restano quelli di oggi, non quelli del backup
        let backupDiOggi = dati.impostazioni.backup
        let nome = (dati.impostazioni.nomeUtente, dati.impostazioni.inizialiUtente)
        // Anche lo spazio di Prisma ovunque resta quello di questo dispositivo (ruolo, id, cartella, ricevute)
        let ovunqueDiOggi = dati.impostazioni.ovunque
        DispatchQueue.global(qos: .userInitiated).async {
            var estratta: URL?
            do {
                let estratto = try GestoreBackup.estrai(zip, password: chiave)
                estratta = estratto.cartella
                try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: "prima del ripristino",
                                       creaCartella: creaCartella, proteggi: zip, password: perSicurezza)
                try GestoreBackup.sostituisci(cartellaDati: Archivio.cartella, con: estratto.cartella)
                Archivio.segnaCopieGestite()
                DispatchQueue.main.async {
                    self.aggiornaCopieNonLeggibili()
                    var d = estratto.dati
                    d.impostazioni.backup = backupDiOggi
                    d.impostazioni.nomeUtente = nome.0
                    d.impostazioni.inizialiUtente = nome.1
                    d.impostazioni.ovunque = ovunqueDiOggi
                    if ovunqueDiOggi.ruolo == .dispositivo {
                        // iPhone e iPad: l'istantanea del Mac va riaccolta sopra l'archivio ripristinato, anche se il Mac
                        // non ne scrive una nuova (con la generazione di oggi sembrerebbe già vista)
                        d.impostazioni.ovunque.generazione = 0
                        d.impostazioni.ovunque.improntaIstantanea = nil
                    }
                    self.dati.carica(d)
                    // Prisma ovunque su iPhone e iPad: l'archivio ripristinato è la base nuova del giornale (le differenze
                    // con quello di prima non sono modifiche da mandare al Mac)
                    self.ovunque.base = d
                    self.testiDocumenti = MemoriaTesti()
                    self.documentoSelezionato = nil
                    self.azzeraNote()
                    // La memoria di Vera e la Biblioteca si rileggono dalla cartella ripristinata (fase 2)
                    self.memoriaVera.ricarica()
                    self.biblioteca.ricarica()
                    self.trovaPagina.azzera()
                    self.solaLettura = false
                    self.salvataggioSospeso = false
                    self.salvaOra()
                    self.backupInCorso = false
                    self.aggiornaElencoBackup()
                    self.mostraAvviso("Ripristino completato. Lo stato precedente è salvato in un backup.")
                }
            } catch {
                if let estratta { GestoreBackup.pulisciEstrazione(estratta) }
                DispatchQueue.main.async {
                    self.salvataggioSospeso = self.solaLettura
                    self.backupInCorso = false
                    if (error as? ErroreBackup)?.passwordSbagliata == true {
                        self.chiediPasswordRipristino(zip, messaggio: daPortachiavi
                            ? "La password dei backup salvata su questo Mac non apre «\(zip.lastPathComponent)»: forse è stato fatto con una password di prima. Scrivila qui."
                            : "La password non è corretta: riprova.")
                    } else {
                        self.mostraAvviso("Ripristino non riuscito: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Copie di archivi non leggibili da sistemare (i backup automatici sono fermi).
    private(set) var copieNonLeggibili = 0

    /// Il consulente ha controllato: i dati di oggi vanno bene, i backup automatici ripartono.
    func riprendiBackupAutomatici() {
        Archivio.segnaCopieGestite()
        aggiornaCopieNonLeggibili()
        controllaBackupAutomatico()
    }

    func aggiornaCopieNonLeggibili() {
        guard persistente else { return }
        copieNonLeggibili = Archivio.copieNonLeggibili.count
    }

    /// Gli identificativi dei clienti di prova.
    /// I 5 clienti del template e i 30 clienti fittizi: si tolgono insieme.
    static let clientiDiProva: Set<String> = Set(DatiDemo.clienti().map(\.id)).union(ClientiFittizi.ids)
    var haDatiDiProva: Bool { dati.clienti.contains { Self.clientiDiProva.contains($0.id) } }

    /// Toglie i 5 clienti di prova con tutti i loro dati (e le schede prodotto di esempio non usate),
    /// lasciando i clienti veri. Prima salva un backup.
    func togliDatiDiProva() {
        guard persistente, !backupInCorso, !solaLettura else { return }
        let password: String?
        do {
            password = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, "Operazione annullata")
            return
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        DispatchQueue.global(qos: .userInitiated).async {
            let esito = Result { try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: "prima di togliere i dati di prova",
                                                        creaCartella: creaCartella, password: password) }
            DispatchQueue.main.async {
                self.backupInCorso = false
                switch esito {
                case .success:
                    self.rimuoviDatiDiProva()
                    self.aggiornaElencoBackup()
                    self.mostraAvviso("Clienti di prova tolti. Lo stato precedente è salvato in un backup.")
                case .failure(let e):
                    self.mostraAvviso("Operazione annullata, backup non riuscito: \(e.localizedDescription)")
                }
            }
        }
    }

    /// Importa in rubrica i clienti scelti (da vCard o CSV). Prima salva un backup dello stato attuale.
    func importaClienti(_ elenco: [ClienteImportato]) {
        guard !elenco.isEmpty, !solaLettura else { return }
        guard persistente else {
            aggiungiImportati(elenco)
            return
        }
        guard !backupInCorso else { return }
        let password: String?
        do {
            password = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, "Operazione annullata")
            return
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        DispatchQueue.global(qos: .userInitiated).async {
            let esito = Result { try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: "prima dell'importazione dei clienti",
                                                        creaCartella: creaCartella, password: password) }
            DispatchQueue.main.async {
                self.backupInCorso = false
                switch esito {
                case .success:
                    self.aggiungiImportati(elenco)
                    self.aggiornaElencoBackup()
                    self.mostraAvviso("\(elenco.count) \(elenco.count == 1 ? "cliente importato" : "clienti importati"). Lo stato precedente è salvato in un backup."
                                      + (self.haDatiDiProva ? " I clienti di prova si tolgono da Impostazioni → Archivio." : ""))
                case .failure(let e):
                    self.mostraAvviso("Importazione annullata, backup non riuscito: \(e.localizedDescription)")
                }
            }
        }
    }

    /// Importa in Posizioni quelle scelte (da CSV, Excel o righe incollate), con i clienti nuovi da creare
    /// in rubrica (chiave: il segnaposto in `clienteId`). Prima salva un backup dello stato attuale.
    func importaPosizioni(_ elenco: [Posizione], nuoviClienti: [String: ClienteImportato] = [:]) {
        guard !elenco.isEmpty, !solaLettura else { return }
        guard persistente else {
            aggiungiPosizioniImportate(elenco, nuoviClienti: nuoviClienti)
            return
        }
        guard !backupInCorso else { return }
        let password: String?
        do {
            password = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, "Operazione annullata")
            return
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        DispatchQueue.global(qos: .userInitiated).async {
            let esito = Result { try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: "prima dell'importazione delle posizioni",
                                                        creaCartella: creaCartella, password: password) }
            DispatchQueue.main.async {
                self.backupInCorso = false
                switch esito {
                case .success:
                    let creati = self.aggiungiPosizioniImportate(elenco, nuoviClienti: nuoviClienti)
                    self.aggiornaElencoBackup()
                    let clienti = Set(elenco.map(\.clienteId)).count
                    let nuovi = creati == 0 ? "" : creati == 1 ? " Un cliente nuovo aggiunto in rubrica." : " \(creati) clienti nuovi aggiunti in rubrica."
                    self.mostraAvviso("\(elenco.count) \(elenco.count == 1 ? "posizione importata" : "posizioni importate") per \(clienti) \(clienti == 1 ? "cliente" : "clienti")."
                                      + nuovi + " Lo stato precedente è salvato in un backup.")
                case .failure(let e):
                    self.mostraAvviso("Importazione annullata, backup non riuscito: \(e.localizedDescription)")
                }
            }
        }
    }

    /// La parte senza backup (usata anche dalle prove): crea i clienti nuovi e dà alle loro posizioni il loro id.
    /// Restituisce quanti clienti ha creato.
    @discardableResult
    func aggiungiPosizioniImportate(_ elenco: [Posizione], nuoviClienti: [String: ClienteImportato]) -> Int {
        var ids: [String: String] = [:]
        for (chiave, nuovo) in nuoviClienti.sorted(by: { $0.value.nome < $1.value.nome })
        where elenco.contains(where: { $0.clienteId == chiave }) {
            let c = nuovo.cliente(tinta: prossimaTinta)
            dati.clienti.append(c)
            ids[chiave] = c.id
        }
        dati.posizioni.append(contentsOf: elenco.compactMap { p in
            guard p.clienteId.hasPrefix("nuovo:") else { return p }
            guard let id = ids[p.clienteId] else { return nil }
            var q = p
            q.clienteId = id
            return q
        })
        return ids.count
    }

    /// Esegue `operazione` dopo un backup di sicurezza (come l'importazione); senza archivio la esegue subito.
    /// Restituisce false se non è partita (backup in corso, password mancante).
    @discardableResult
    func dopoUnBackup(nota: String, annullata: String, _ operazione: @escaping (_ conBackup: Bool) -> Void) -> Bool {
        guard persistente else {
            operazione(false)
            return true
        }
        guard !backupInCorso else { return false }
        let password: String?
        do {
            password = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, annullata)
            return false
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        DispatchQueue.global(qos: .userInitiated).async {
            let esito = Result { try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: nota,
                                                        creaCartella: creaCartella, password: password) }
            DispatchQueue.main.async {
                self.backupInCorso = false
                switch esito {
                case .success:
                    operazione(true)
                    self.aggiornaElencoBackup()
                case .failure(let e):
                    self.mostraAvviso(TestiAggiornaValori.annullato(e.localizedDescription))
                }
            }
        }
        return true
    }

    /// La parte senza backup (usata anche dalle prove): ogni cliente con la sua tinta, il primo in primo piano.
    func aggiungiImportati(_ elenco: [ClienteImportato]) {
        for x in elenco {
            dati.clienti.append(x.cliente(tinta: prossimaTinta))
        }
        if let primo = elenco.first, let c = dati.clienti.last(where: { $0.nome == primo.nome }) { dati.clienteAttivoId = c.id }
    }

    /// La parte senza backup (usata anche dalle prove).
    func rimuoviDatiDiProva() {
        for id in Self.clientiDiProva { eliminaCliente(id) }
        let esempi = Set((DatiDemo.prodotti() + [DatiDemo.orizzonteValore()]).map(\.id))
        let usati = Set(dati.posizioni.compactMap(\.prodottoId) + dati.valutazioni.map(\.prodottoId))
        dati.prodotti.removeAll { esempi.contains($0.id) && !usati.contains($0.id) }
        if dati.clienti.first(where: { $0.id == dati.clienteAttivoId }) == nil {
            dati.clienteAttivoId = dati.clienti.first?.id ?? ""
        }
        // I fac-simile della Biblioteca se ne vanno con i clienti di prova («Luce» giro 6)
        togliEsempiBiblioteca()
    }

    /// Torna ai dati di prova (con backup di sicurezza dello stato attuale): i 5 clienti del template,
    /// oppure con `completi` anche i 30 clienti fittizi.
    func ripristinaDatiDiProva(completi: Bool = false) {
        guard persistente, !backupInCorso, !solaLettura else { return }
        let password: String?
        do {
            password = try passwordPerBackup()
        } catch {
            annullaSenzaPassword(error, "Operazione annullata")
            return
        }
        salvaOra()
        backupInCorso = true
        let destinazione = cartellaBackup
        let escluse = cartelleEscluseBackup
        let creaCartella = cartellaBackupPredefinita
        DispatchQueue.global(qos: .userInitiated).async {
            let esito = Result { try GestoreBackup.crea(sorgente: Archivio.cartella, escludi: escluse, destinazione: destinazione, nota: "prima dei dati di prova",
                                                        creaCartella: creaCartella, password: password) }
            DispatchQueue.main.async {
                self.backupInCorso = false
                switch esito {
                case .success:
                    var demo = completi ? ClientiFittizi.completi() : DatiPrisma.demo()
                    let tolleranzaProva = demo.impostazioni.tolleranzaRadar
                    demo.impostazioni = self.dati.impostazioni
                    // La tolleranza del radar di prova, se l'utente non ne ha scritta una
                    if demo.impostazioni.tolleranzaRadar == nil { demo.impostazioni.tolleranzaRadar = tolleranzaProva }
                    self.dati.carica(demo)
                    self.azzeraNote()
                    // I sei fac-simile della Biblioteca arrivano con i clienti di prova («Luce» giro 6)
                    self.caricaEsempiBiblioteca()
                    // I file dei clienti veri restano nel backup appena fatto, non nell'archivio
                    self.pulisciDocumentiOrfani()
                    self.aggiornaElencoBackup()
                    self.mostraAvviso((completi ? "\(demo.clienti.count) clienti di prova caricati." : "Dati di prova ripristinati.")
                                      + " Lo stato precedente è salvato in un backup.")
                case .failure(let e):
                    self.mostraAvviso("Operazione annullata, backup non riuscito: \(e.localizedDescription)")
                }
            }
        }
    }

    #if os(macOS)
    /// Backup automatico settimanale: un controllo poco dopo l'avvio, poi circa ogni ora quando il Mac è
    /// libero (lo decide macOS, che raggruppa i lavori e non li fa cadere tutti sul risveglio).
    private func avviaBackupAutomatico() {
        DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.primoControlloBackup) { [weak self] in
            guard let self, !self.lavoriInPausa else { return }
            self.controllaBackupAutomatico()
        }
        let attivita = NSBackgroundActivityScheduler(identifier: "local.prisma.backup-automatico")
        attivita.repeats = true
        attivita.interval = StatoShell.intervalloBackup
        attivita.tolerance = StatoShell.tolleranzaBackup
        attivita.qualityOfService = .utility
        attivita.schedule { [weak self] fatto in
            DispatchQueue.main.async {
                guard let self else {
                    fatto(.finished)
                    return
                }
                // Durante lo stop del Mac si rimanda: lo rifà la ripresa dei lavori
                guard !self.lavoriInPausa else {
                    fatto(.deferred)
                    return
                }
                self.controllaBackupAutomatico()
                fatto(.finished)
            }
        }
        attivitaBackup = attivita
    }
    #endif

    private func controllaBackupAutomatico() {
        #if os(macOS)
        let b = dati.impostazioni.backup
        // Con un archivio non leggibile da sistemare i backup automatici non sostituiscono quelli buoni
        // (il conto si aggiorna all'avvio, dopo un ripristino e quando il consulente le segna come gestite)
        guard persistente, b.automatico, !solaLettura, copieNonLeggibili == 0, !backupInCorso,
              let prossimo = b.prossimo, prossimo <= Date() else { return }
        // Backup protetti: il Portachiavi si legge (una volta per sessione) fuori dal thread principale
        if b.cifrato, passwordBackupInMemoria == nil, !portachiaviLetto {
            portachiaviLetto = true
            DispatchQueue.global(qos: .utility).async {
                let password = PortachiaviBackup.leggi()
                DispatchQueue.main.async {
                    if self.passwordBackupInMemoria == nil { self.passwordBackupInMemoria = password }
                    self.creaBackup(automatico: true)
                }
            }
            return
        }
        creaBackup(automatico: true)
        #elseif os(iOS)
        // Su iPhone e iPad niente backup automatico (anche se le impostazioni arrivate dal Mac lo chiedono):
        // la fonte dei dati è il Mac
        #endif
    }

    // MARK: - Avvisi

    func mostraAvviso(_ testo: String, daVera: Bool = false) {
        lavoroAvviso?.cancel()
        avvisoDiVera = daVera
        withAnimation(Animazioni.avviso) { avviso = testo }
        let lavoro = DispatchWorkItem { [weak self] in
            withAnimation(Animazioni.avviso) { self?.avviso = nil }
        }
        lavoroAvviso = lavoro
        DispatchQueue.main.asyncAfter(deadline: .now() + Animazioni.durataAvviso, execute: lavoro)
    }

    func alternaSchermoIntero() {
        #if os(macOS)
        (NSApp.keyWindow ?? NSApp.windows.first)?.toggleFullScreen(nil)
        #elseif os(iOS)
        // Su iPhone e iPad Prisma è già a tutto schermo
        #endif
    }
}

/// Le pagine delle Impostazioni, nell'ordine della barra laterale (Strumenti in fondo, separata).
/// Icone in `DesignSystem/TemaImpostazioni.swift`.
enum SchedaImpostazioni: String, CaseIterable, Hashable, Identifiable {
    case panoramica, profilo, aspetto
    /// Prisma ovunque: la copia cifrata per iPhone e iPad in una cartella di iCloud Drive (giro 8, ImpostazioniOvunque.swift).
    case ovunque
    /// Orari di lavoro, festività, seguito delle proposte.
    case lavoro
    /// Promemoria del Mac e occasioni.
    case promemoria
    case conformita
    /// Documenti da consegnare per canale e PDF per i clienti.
    case proposte
    /// Metri di confronto dei rendimenti (dalla versione 24 dell'archivio; prima «Riferimenti»).
    case rendimenti
    case vera, archivio, scorciatoie
    /// Aliquote provvigionali Alleanza e obiettivi dell'anno per Studio (dalla versione 26 dell'archivio).
    case studio
    /// Mercato (giro 7): l'interruttore «Dati di mercato», le serie, le soglie degli avvisi, i dati importati.
    case mercato
    /// I portafogli modello e la tolleranza del radar di Posizioni («Luce» giro 2, ImpostazioniModelli.swift).
    case portafogliModello
    /// La soglia delle pratiche ferme di Pratiche › Dopo la firma («Luce» giro 3, ImpostazioniPraticheVista.swift).
    case pratiche
    /// Dati di prova, confronto dei modelli, prove di promemoria e voce.
    case strumenti

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .panoramica: return "Panoramica"
        case .profilo: return "Profilo"
        case .aspetto: return "Aspetto"
        case .ovunque: return "iPhone e iPad"
        case .lavoro: return "Agenda e lavoro"
        case .promemoria: return "Promemoria e occasioni"
        case .conformita: return "Conformità"
        case .proposte: return "Proposte e PDF"
        case .rendimenti: return "Rendimenti di confronto"
        case .vera: return "Vera"
        case .archivio: return "Archivio e backup"
        case .scorciatoie: return "Scorciatoie"
        case .studio: return "Studio"
        case .mercato: return "Mercato"
        case .portafogliModello: return "Portafogli modello"
        case .pratiche: return "Pratiche"
        case .strumenti: return "Strumenti"
        }
    }

    /// Le pagine delle preferenze (la barra laterale); Strumenti sta a parte, in fondo.
    static let preferenze: [SchedaImpostazioni] = allCases.filter { $0 != .strumenti }
}

enum SchedaCliente: String, CaseIterable, Hashable {
    case panoramica, bisogni
    /// Le app accorpate in Clienti: Obiettivi e Documenti del cliente.
    case obiettivi, documenti
    case anagrafica, famiglia, profilo, inRegola, note
    /// Cronologia delle fotografie dei riesami (dalla versione 24 dell'archivio).
    case riesami
    /// Il patrimonio nel tempo, tre anni indietro e due avanti (tema Apple, §4.2.4).
    case nelTempo
    /// Il patrimonio da oggi a 90 anni con gli eventi trascinabili (Orizzonte, giro 4; specifica §7).
    case lineaVita
    /// L'azienda dei clienti imprenditori («Luce» giro 7, Design/template-luce-specifica.md §9.3): nel segmentato solo per
    /// chi ha almeno un'azienda registrata, altrimenti in «Altro» per aggiungerla.
    case azienda

    var titolo: String {
        switch self {
        case .panoramica: return "Panoramica"
        case .bisogni: return "Bisogni"
        case .obiettivi: return "Obiettivi"
        case .documenti: return "Documenti"
        case .anagrafica: return "Anagrafica"
        case .famiglia: return "Famiglia"
        case .profilo: return "Profilo"
        case .inRegola: return "In regola"
        case .note: return "Note"
        case .riesami: return "Riesami"
        case .nelTempo: return "Nel tempo"
        case .lineaVita: return "Linea della vita"
        case .azienda: return "L'azienda"
        }
    }
}
