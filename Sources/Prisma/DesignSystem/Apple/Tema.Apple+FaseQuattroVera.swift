import SwiftUI

// Gettoni della fase 4 di Vera (Vera/BRIEF.md, Design/template-vera.html): le routine (3), l'agenda che si organizza (4),
// il tagliando dei dati (5), il sussurro (7), il mercato per i tuoi clienti (14), scrive come te (15), tre livelli (17)
// e ragiona a passi (20). Il rubino di Vera del template (--ruby, #C2264B chiaro e #FF5C83 scuro) torna in quasi tutte:
// ogni funzione ha i suoi nomi, così una si può ritoccare senza toccare le altre. I semafori riusano i colori del tema.

extension Tema.Apple {
    // MARK: - Le routine (funzione 3, Shell/VisteRoutineVera.swift)

    static let routineRubino = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
    static let routineAlone = Color.dinamico(chiaro: Color(r: 194, g: 38, b: 75, a: 0.35), scuro: Color(r: 255, g: 92, b: 131, a: 0.35))
    static let routineFatto = Colore.verde
    static let routineDaConfermare = Colore.accento
    static let routineAttesa = Colore.arancio
    static let routineImpossibile = Colore.rosso
    static let routinePuntino = Colore.inchiostro3
    static let routineTratteggio = Colore.inchiostro3
    /// Il pallino del passo, il suo filo da vuoto e la scala da cui entra quando si spunta.
    static let routinePallino: CGFloat = 18
    static let routineFiloPuntino: CGFloat = 1.5
    static let routineScalaSpunta: CGFloat = 0.4
    /// La spunta entra con la molla in 0,45 s; un passo ogni 0,62 s (il template).
    static let routineDurataSpunta: Double = 0.45
    static let routineRitmoPassi: Double = 0.62
    static let routineSpazioPasso: CGFloat = 5
    /// La sfera di Vera nella tile del risultato (`sf(18)` del template) e l'alone della tile.
    static let routineSfera: CGFloat = 18
    static let routineSpessoreAlone: CGFloat = 1.5
    /// La pagina delle routine: entra in 0,42 s (con «Riduci movimento» una dissolvenza di 0,15 s).
    static let routineDissolvenzaCalma: Double = 0.15
    static let routineDurataPagina: Double = 0.42
    static let routineSpazioColonne: CGFloat = 18
    static let routineColonna: CGFloat = 330
    static let routineOpacitaSpenta: Double = 0.55
    static let routineSpessoreScelta: CGFloat = 2
    static let routineFiloTratteggio: CGFloat = 1.2
    static let routineTrattino: [CGFloat] = [5, 4]
    static let routinePaddingDettaglio: CGFloat = 20

    // MARK: - L'agenda che si organizza (funzione 4, Shell/VisteAgendaOrganizzaVera.swift)

    /// Gli orari proposti nel colore di Vera (--ruby del template): tratteggio, titolo, bordo dell'orario scelto.
    static let agendaProposta = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
    static let agendaPropostaFondo = Color.dinamico(chiaro: Color(r: 194, g: 38, b: 75, a: 0.07), scuro: Color(r: 255, g: 92, b: 131, a: 0.10))
    static let agendaPropostaScelta = Color.dinamico(chiaro: Color(r: 194, g: 38, b: 75, a: 0.16), scuro: Color(r: 255, g: 92, b: 131, a: 0.22))

    /// La griglia di «L'agenda che si organizza» (template `.wk`, `.wkH`, `.ev`, `.ev.prop`), compattata per la bolla di Vera.
    enum AgendaOrganizza {
        /// Le ore di ripiego se gli orari di lavoro non hanno fasce valide.
        static let oraInizio = 9
        static let oraFine = 18
        static let altezzaOra: CGFloat = 30
        static let colonnaOre: CGFloat = 38
        static let altezzaIntestazione: CGFloat = 22
        static let spessoreFilo: CGFloat = 1
        static let sopraOra: CGFloat = 2
        static let spazioBlocco: CGFloat = 2
        static let altezzaMinima: CGFloat = 14
        /// Sotto questa altezza il blocco mostra solo il titolo.
        static let sogliaSotto: CGFloat = 28
        static let raggioBlocco: CGFloat = 8
        static let filoBlocco: CGFloat = 3
        static let trattoProposta: CGFloat = 1.5
        static let trattino: [CGFloat] = [5, 4]
        static let spessoreOmbra: CGFloat = 1
        static let trattinoOmbra: [CGFloat] = [3, 3]
        static let opacitaSbiadito: Double = 0.45
        static let alfaFondo: Double = Colore.Impegno.alfaFondo
        static let paddingBlocco = Misura.padding(3, 6)
        static let paddingGriglia = Misura.padding(10, 12)
        static let spazio: CGFloat = 8
        static let spazioRighe: CGFloat = 1
        static let giorno = Carattere(dimensione: 11.5, peso: .semibold)
        static let ora = Carattere(dimensione: 10, peso: .regular)
        static let titoloBlocco = Carattere(dimensione: 11.5, peso: .semibold)
        static let sottoBlocco = Carattere(dimensione: 10.5, peso: .regular)
        static let coloreGiorno = Colore.inchiostro2
        static let coloreOggi = Colore.rosso
        static let coloreOra = Colore.inchiostro3
        static let filo = Colore.separatore
        static let testoBlocco = Colore.inchiostro
        static let coloreSotto = Colore.inchiostro2
        static let occupato = Colore.Impegno.attivita
    }

    // MARK: - Il tagliando dei dati (funzione 5, Shell/VisteTagliandoVera.swift): il semaforo e l'anello della salute

    static let tagliandoRosso = Color(hex: "#E5484D")
    static let tagliandoArancio = Color(hex: "#E08A00")
    static let tagliandoVerde = Color(hex: "#2FA35A")
    static let tagliandoNeutro = Color.dinamico(chiaro: Color(r: 0, g: 0, b: 0, a: 0.34), scuro: Color(r: 255, g: 255, b: 255, a: 0.38))
    static let tagliandoFondoRiga = Color.dinamico(chiaro: Color(hex: "#FFFFFF"), scuro: Color(hex: "#283642"))
    static let tagliandoBordoRiga = Color.dinamico(chiaro: Color(r: 0, g: 0, b: 0, a: 0.08), scuro: Color(r: 255, g: 255, b: 255, a: 0.09))
    static let tagliandoVelo = Color.dinamico(chiaro: Color(r: 220, g: 232, b: 240, a: 0.40), scuro: Color(r: 5, g: 12, b: 18, a: 0.50))

    /// Misure e caratteri del tagliando dei dati (Design/template-vera.html, «Il tagliando dei dati»): card della salute
    /// di 330 con l'anello di 190 spesso 16 e il 46 bold al centro, righe `.sev` con il filo di 4.
    enum Tagliando {
        // La pagina sopra la chat di Vera
        static let marginePagina: CGFloat = 24
        static let larghezzaPagina: CGFloat = 900
        static let altezzaMassimaPagina: CGFloat = 620
        static let paddingPagina = Misura.padding(20, 22)
        static let superficiePagina = Superficie.dettaglio
        static let raggioPagina: CGFloat = Raggio.dettaglioAperto
        static let spazioIntestazione: CGFloat = 12
        static let iconaIntestazione: CGFloat = 26
        static let titoloPagina = Carattere(dimensione: 17, peso: .bold)
        static let spazioColonne: CGFloat = 18
        static let durataCambio = 0.35
        // Salute dell'archivio
        static let larghezzaSalute: CGFloat = 330
        static let paddingSalute = Misura.padding(22, 22)
        static let superficieSalute = Superficie.cardPiatta
        static let etichetta = Carattere.etichetta
        static let anello: CGFloat = 190
        static let spessoreAnello: CGFloat = 16
        static let sopraAnello: CGFloat = 18
        static let sottoAnello: CGFloat = 12
        static let spazioCentroAnello: CGFloat = 2
        static let percentuale = Carattere.valoreCursore
        static let schede = Carattere.secondario
        static let quando = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.45)
        static let riepilogo = Carattere(dimensione: 13.5, peso: .bold)
        static let sopraSistema: CGFloat = 18
        static let nota = Carattere.secondario
        /// L'anello è verde da 80, arancio da 60, rosso sotto.
        static let sogliaVerde = 80
        static let sogliaArancio = 60
        // Le voci
        static let spazioRighe: CGFloat = 8
        static let spazioRiga: CGFloat = 12
        static let spazioTitoloDettaglio: CGFloat = 2
        static let paddingRiga = Misura.padding(11, 14)
        static let raggioRiga: CGFloat = Raggio.voce
        static let filo: CGFloat = 4
        static let titoloRiga = Carattere(dimensione: 13.5, peso: .bold)
        static let dettaglioRiga = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
        static let opacitaFatta: Double = 0.55
        static let rientroGruppo: CGFloat = 14
        static let pillola = Carattere(dimensione: 11.5, peso: .semibold)
        static let paddingPillola = Misura.padding(3, 9)
        static let opacitaFondoPillola: Double = 0.13
        // In chat e nella colonna di Vera
        static let sopraScheda: CGFloat = 10
        static let anelloChat: CGFloat = 64
        static let spessoreAnelloChat: CGFloat = 7
        static let percentualeChat = Carattere.centroAnello(17)
        static let vociChat = 4
        static let anelloColonna: CGFloat = 44
        static let spessoreAnelloColonna: CGFloat = 5
        static let percentualeColonna = Carattere.centroAnello(13)
        // Impostazioni › Vera
        static let menuOra: CGFloat = 110
    }

    // MARK: - Il sussurro (funzione 7, Shell/VisteSussurroVera.swift; Design/template-vera.html «Il sussurro»)

    /// Il pallino del tono: rosso (prima di tutto), arancio (presto), blu (da sapere).
    static let sussurroRosso = Colore.rosso
    static let sussurroArancio = Colore.arancio
    static let sussurroBlu = Colore.accento
    /// «Vera ti sussurra» (--ruby del template) e il filo intorno alla card (rgba(194,38,75,.3)).
    static let sussurroRubino = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
    static let sussurroBordo = Color.dinamico(chiaro: Color(hex: "#C2264B4D"), scuro: Color(hex: "#FF5C834D"))
    /// La sfera di Vera nella testata della card (34 nel template).
    static let sussurroSfera: CGFloat = 34
    /// Il filo color rubino intorno alla card.
    static let sussurroFiloBordo: CGFloat = 1.5
    static let sussurroSpazioTestata: CGFloat = 10
    /// Fra «Vera ti sussurra» e «tre cose da sapere adesso».
    static let sussurroSpazioTitoli: CGFloat = 1
    static let sussurroSopraVoci: CGFloat = 12
    static let sussurroSpazioVoci: CGFloat = 8
    static let sussurroPaddingVoce = Misura.padding(10, 12)
    static let sussurroSpazioRiga: CGFloat = 10
    /// Il pallino del tono (9 nel template), allineato alla prima riga del testo.
    static let sussurroPallino: CGFloat = 9
    static let sussurroSopraPallino: CGFloat = 6
    static let sussurroSopraFonte: CGFloat = 2
    static let sussurroSopraPulsante: CGFloat = 7
    static let sussurroSpazioPulsanti: CGFloat = 6
    static let sussurroSopraScheda: CGFloat = 8
    static let sussurroTitolo = Carattere(dimensione: 14, peso: .bold)
    static let sussurroSottotitolo = Carattere(dimensione: 12.5, peso: .regular)
    static let sussurroTesto = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.45)
    static let sussurroFonte = Carattere(dimensione: 11.5, peso: .regular)

    // MARK: - Il mercato per i tuoi clienti (funzione 14, Shell/VisteMercatoClientiVera.swift)

    /// Le pillole delle azioni: «Chiama … oggi», scadenze e rate, «Bozze pronte ✓», le altre, «Manda due righe».
    static let mercatoRosso = Color.dinamico(chiaro: Color(hex: "#E5484D"), scuro: Color(hex: "#FF6369"))
    static let mercatoArancio = Color.dinamico(chiaro: Color(hex: "#E08A00"), scuro: Color(hex: "#FFA826"))
    static let mercatoVerde = Color.dinamico(chiaro: Color(hex: "#2FA35A"), scuro: Color(hex: "#3DD47A"))
    static let mercatoBlu = Color.dinamico(chiaro: Color(hex: "#007AFF"), scuro: Color(hex: "#4C9DFF"))
    static let mercatoGrigio = Color.dinamico(chiaro: Color(hex: "#6B7785"), scuro: Color(hex: "#9AA6B2"))

    /// «Il mercato per i tuoi clienti» (template-vera.html «// 14»): righe con avatar, motivo e pillola dell'azione; la
    /// scena di Mercato con la scheda dell'evento (380 nel template, qui 340 dentro il foglio) e l'elenco.
    enum MercatoClientiVera {
        // Scena
        static let larghezzaScena: CGFloat = 900
        static let altezzaScena: CGFloat = 600
        static let paddingScena: CGFloat = 22
        static let spazioScena: CGFloat = 14
        static let spazioColonne: CGFloat = 18
        static let titoloScena = Carattere(dimensione: 22, peso: .bold, tracking: -0.5)
        // Scheda dell'evento
        static let larghezzaEvento: CGFloat = 340
        static let paddingEvento: CGFloat = 22
        static let titoloEvento = Carattere(dimensione: 24, peso: .bold, tracking: -0.5, interlinea: 1.15)
        static let sintesi = Carattere(dimensione: 14, peso: .regular, interlinea: 1.55)
        static let sopraTitoloEvento: CGFloat = 12
        static let sopraSintesi: CGFloat = 8
        static let sopraFonte: CGFloat = 14
        static let iconaFonte: CGFloat = 14
        static let spazioFonte: CGFloat = 6
        // Elenco
        static let paddingElenco = Misura.padding(18, 20)
        static let intestazioneElenco = Carattere.h2
        static let sopraElenco: CGFloat = 6
        static let spazioRighe: CGFloat = 8
        static let paddingRiga = Misura.padding(10, 12)
        static let spazioRiga: CGFloat = 12
        static let avatar: CGFloat = 36
        static let avatarChat: CGFloat = 30
        static let nome = Carattere(dimensione: 13.5, peso: .semibold)
        static let motivo = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
        static let spazioNomeMotivo: CGFloat = 2
        // Pillole e note
        static let pillola = Carattere(dimensione: 11.5, peso: .semibold)
        static let paddingPillola = Misura.padding(3, 9)
        static let opacitaFondoPillola: Double = 0.13
        static let nota = Carattere(dimensione: 12, peso: .regular)
        // Sotto la bolla di Vera
        static let sopraScheda: CGFloat = 10
        static let sopraPiede: CGFloat = 4
    }

    // MARK: - Scrive come te (funzione 15, Shell/VisteStileVera.swift; il resto viene da Tema.Apple.FaseTreVera)

    /// Il rubino di Vera: occhiello «IL TUO STILE», spunta delle regole accese, pillola «Nel tuo stile».
    static let stileVera = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))

    // MARK: - Tre livelli (funzione 17, Shell/VisteTreLivelliVera.swift)

    /// Etichette «Per te · tecnica», «Per Marco · semplice» (--ruby del template).
    static let trelivelliRubino = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
    /// Barre della pagina, sempre su carta bianca (colori fissi): quanto serve, quanto c'è, quanto manca.
    static let trelivelliBarraServe = Color(hex: "#14202B")
    static let trelivelliBarraPubblica = Color(hex: "#7FA5D9")
    static let trelivelliBarraManca = Color(hex: "#C2264B")

    /// La scheda «Tre livelli» in chat e la pagina su carta (Design/template-vera.html, «// 17 · TRE LIVELLI»: `.paper`,
    /// `.pl`, `h3`, `.sec`, `.tx`, `.foot`).
    enum TreLivelli {
        static let spazio: CGFloat = 12
        static let spazioRighe: CGFloat = 8
        static let spazioPunto: CGFloat = 8
        static let spazioNote: CGFloat = 4
        static let sopraNote: CGFloat = 6
        static let paddingScheda = Misura.padding(18, 20)
        static let etichettaLivello = Carattere(dimensione: 11.5, peso: .semibold, tracking: 0.6, maiuscolo: true)
        static let rigaTecnica = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.6)
        static let testoCliente = Carattere(dimensione: 16, peso: .regular, interlinea: 1.6)
        static let larghezzaTestoCliente: CGFloat = 720
        // La pagina su carta (sempre chiara)
        static let larghezzaCarta: CGFloat = 430
        static let altezzaMinimaCarta: CGFloat = 470
        static let paddingCarta = EdgeInsets(top: 30, leading: 34, bottom: 18, trailing: 34)
        static let raggioCarta: CGFloat = 4
        static let occhielloCarta = Carattere(dimensione: 10.5, peso: .bold, tracking: 1.3, maiuscolo: true)
        static let titoloCarta = Carattere(dimensione: 24, peso: .bold, tracking: -0.6, interlinea: 1.15)
        static let sottoOcchiello: CGFloat = 5
        static let sezioneCarta = Carattere(dimensione: 11, peso: .bold, tracking: 0.5, maiuscolo: true)
        static let sopraSezioneCarta: CGFloat = 16
        static let testoCarta = Carattere(dimensione: 13, peso: .regular, interlinea: 1.65)
        static let spazioRigheCarta: CGFloat = 2
        static let sopraRigheCarta: CGFloat = 6
        static let sopraBarre: CGFloat = 8
        static let spazioBarre: CGFloat = 6
        static let spazioRigaBarra: CGFloat = 8
        static let etichettaBarra = Carattere(dimensione: 11.5, peso: .regular)
        static let valoreBarra = Carattere(dimensione: 11.5, peso: .bold, tabellare: true)
        static let larghezzaEtichettaBarra: CGFloat = 140
        static let larghezzaValoreBarra: CGFloat = 76
        static let altezzaBarra: CGFloat = 14
        static let raggioBarra: CGFloat = 4
        static let filetto: CGFloat = 1
        static let sopraPiede: CGFloat = 7
        static let piedeCarta = Carattere(dimensione: 9.5, peso: .regular, interlinea: 1.4)
    }

    // MARK: - Ragiona a passi (funzione 20, Shell/VistePassiVera.swift; Design/template-vera.html «20 · Ragiona a passi»)

    static let passiConsiglia = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#F2577D"))
    static let passiFatto = Color.dinamico(chiaro: Color(hex: "#2FA35A"), scuro: Color(hex: "#3DBE6C"))
    static let passiBinario = Color.dinamico(chiaro: Color(r: 0, g: 0, b: 0, a: 0.08), scuro: Color(r: 255, g: 255, b: 255, a: 0.12))
    static let passiProtezione = Color.dinamico(chiaro: Color(hex: "#E5484D"), scuro: Color(hex: "#FF6369"))
    static let passiObiettivo = Color.dinamico(chiaro: Color(hex: "#0A84FF"), scuro: Color(hex: "#409CFF"))
    static let passiObiettivoDue = Color.dinamico(chiaro: Color(hex: "#8B5CF6"), scuro: Color(hex: "#A78BFA"))
    static let passiObiettivoTre = Color.dinamico(chiaro: Color(hex: "#30B15C"), scuro: Color(hex: "#4CC97A"))
    static let passiVincolo = Color.dinamico(chiaro: Color(hex: "#E08A00"), scuro: Color(hex: "#F0A43A"))

    /// Misure, caratteri e tempi della scheda «Ragiona a passi»: `.prep` e `.opt` del template. Si chiama RagionaPassi
    /// per non coprire l'enum `PassiVera` del motore.
    enum RagionaPassi {
        static let spazio: CGFloat = 12
        static let spazioPiccolo: CGFloat = 8
        static let nota = Carattere(dimensione: 12, peso: .regular)
        // Il piano
        static let paddingScheda = Misura.padding(16, 18)
        static let sfera: CGFloat = 20
        static let titoloScheda = Carattere(dimensione: 14, peso: .bold)
        static let sottoTitolo: CGFloat = 4
        static let spazioRiga: CGFloat = 12
        static let paddingPasso = Misura.padding(10, 0)
        static let sottoTitoloPasso: CGFloat = 2
        static let titoloPasso = Carattere(dimensione: 13.5, peso: .semibold)
        static let esitoPasso = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
        static let motorePasso = Carattere(dimensione: 11, peso: .semibold)
        static let opacitaDaFare = 0.4
        static let filo: CGFloat = 1
        static let pallino: CGFloat = 22
        static let bordoPallino: CGFloat = 2
        static let sopraPallino: CGFloat = 1
        static let scalaPallinoFatto: CGFloat = 1.06
        static let scalaPallinoVuoto: CGFloat = 0.6
        static let spunta = Carattere(dimensione: 10, peso: .heavy)
        // Le divisioni
        static let spazioColonne: CGFloat = 12
        static let spazioColonna: CGFloat = 8
        static let paddingColonna = Misura.padding(14, 14)
        static let titoloColonna = Carattere(dimensione: 15, peso: .bold)
        static let anelloConsigliata: CGFloat = 2
        static let opacitaColonnaPrima = 0.25
        static let sottoEtichetta: CGFloat = 3
        static let etichettaBarra = Carattere(dimensione: 12, peso: .regular)
        static let altezzaBarra: CGFloat = 10
        static let cifraBarra = Carattere(dimensione: 13, peso: .bold, tabellare: true)
        static let larghezzaCifra: CGFloat = 52
        static let sopraEsiti: CGFloat = 4
        static let spazioEsiti: CGFloat = 4
        static let esito = Carattere(dimensione: 13, peso: .regular, interlinea: 1.45)
        static let esitoForte = Carattere(dimensione: 13.5, peso: .semibold, interlinea: 1.45)
        static let puntoEsito: CGFloat = 7
        // Movimento (template: un passo ogni 0,6 s dopo 0,38 s, colonne ogni 0,22 s); niente Timer: ritardi delle animazioni
        static let ritardoPrimo = 0.38
        static let ritardoPasso = 0.6
        static let durataPasso = 0.35
        static let ritardoColonna = 0.22
        static let durataColonna = 0.5
        /// Oltre questo tempo dalla creazione il piano compare già fermo (conversazione riaperta).
        static let finestraAnimazione: TimeInterval = 20
    }
}
