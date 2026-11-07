import Foundation

/// Le app di Prisma, nell'ordine del dock.
///
/// Quindici app hanno un'icona propria nel dock (versione «Luce», Design/template-luce-specifica.md §1.2): Clienti,
/// Posizioni, Analisi 360, Incontri, Agenda, Territorio, Messaggi, Pratiche, Prospetti, Sala, Biblioteca, Mercato,
/// Studio, Ruby, Impostazioni, dopo la Scrivania (Orizzonte ne aveva undici: entrano Territorio, Pratiche, Sala e
/// Biblioteca). Cinque sono «accorpate» dentro un'altra (`ospite`): Obiettivi e Documenti vivono in Clienti,
/// Confronti e Simulazioni in Analisi 360, Attività nell'Agenda. Tre restano app a sé ma fuori dal dock
/// (`fuoriDalDock`): Prodotti, Note e Ricerca si aprono dal menu Vai («Altre app»), dalla ricerca ⌘K e dalla Guida
/// (la Ricerca è anche il pannello «Cerca ⌘K» della barra). I casi restano (archivio, spazi di lavoro, promemoria,
/// iPhone e iPad) e `StatoShell.apri(_:)` porta le accorpate all'ospite con la scheda giusta.
///
/// Il fulcro di Prisma è e resta Posizioni: l'analisi delle posizioni dei clienti
/// (in essere e in proposta) e delle possibilità di investimento, risparmio,
/// previdenza e assicurazione. Per questo viene subito dopo Clienti.
enum AppPrisma: String, CaseIterable, Identifiable, Codable {
    case clienti, posizioni, analisi360, incontri, obiettivi, confronti, simulazioni
    // Compatibilità: negli archivi, nei backup e nei giornali di «Prisma ovunque» il valore salvato resta «eve» (il vecchio nome).
    // «Luce»: Territorio dopo l'Agenda, Pratiche dopo Messaggi, Sala e Biblioteca dopo i Prospetti (ordine del dock)
    case agenda, attivita, documenti, territorio, messaggi, pratiche, presentazioni, sala, biblioteca, mercato, studio
    case ruby = "eve", impostazioni
    // Fuori dal dock (con una finestra propria sul Mac)
    case prodotti, note, ricerca

    var id: String { rawValue }

    /// L'app che ospita questa (nil per le app con una finestra propria).
    var ospite: AppPrisma? {
        switch self {
        case .obiettivi, .documenti: return .clienti
        case .confronti, .simulazioni: return .analisi360
        case .attivita: return .agenda
        default: return nil
        }
    }

    /// Le app con una finestra propria che non hanno l'icona nel dock (dal giro 1 di «Orizzonte»): si aprono dal
    /// menu Vai, dalla ricerca ⌘K e dalla Guida; su iPhone e iPad da «Tutte le app».
    var fuoriDalDock: Bool {
        switch self {
        case .prodotti, .note, .ricerca: return true
        default: return false
        }
    }

    /// Vero per le app con icona propria nel dock.
    var nelDock: Bool { ospite == nil && !fuoriDalDock }

    /// Le app del dock, nell'ordine di `allCases`.
    static var delDock: [AppPrisma] { allCases.filter(\.nelDock) }

    /// Le app con una finestra propria fuori dal dock (Prodotti, Note, Ricerca), nell'ordine di `allCases`.
    static var altreApp: [AppPrisma] { allCases.filter { $0.ospite == nil && $0.fuoriDalDock } }

    /// Le app che si aprono come app a sé: sul Mac quelle con una finestra propria (il dock e le altre app),
    /// su iPhone e iPad (che non accorpano) tutte.
    static var aSe: [AppPrisma] {
        #if os(macOS)
        return allCases.filter { $0.ospite == nil }
        #else
        return allCases
        #endif
    }

    var titolo: String {
        switch self {
        case .clienti: return "Clienti"
        case .analisi360: return "Analisi 360"
        case .incontri: return "Incontri"
        case .posizioni: return "Posizioni"
        case .obiettivi: return "Obiettivi"
        case .confronti: return "Confronti"
        case .prodotti: return "Prodotti"
        case .simulazioni: return "Simulazioni"
        case .agenda: return "Agenda"
        case .attivita: return "Attività"
        case .note: return "Note"
        case .documenti: return "Documenti"
        case .presentazioni: return "Prospetti e report"
        case .messaggi: return "Messaggi"
        case .mercato: return "Mercato"
        case .studio: return "Studio"
        case .ruby: return "Ruby"
        case .ricerca: return "Ricerca"
        case .impostazioni: return "Impostazioni"
        case .territorio: return "Territorio"
        case .pratiche: return "Pratiche"
        case .sala: return "Sala"
        case .biblioteca: return "Biblioteca"
        }
    }

    /// Il nome breve sotto l'icona del dock.
    var nomeDock: String {
        switch self {
        case .presentazioni: return "Prospetti"
        case .impostazioni: return "Impostazioni"
        default: return titolo
        }
    }

    var sottotitolo: String {
        switch self {
        case .clienti: return "Le persone, prima di tutto"
        case .analisi360: return "Previdenza, protezione, investimenti, risparmio"
        case .incontri: return "Dall'ascolto ai prossimi passi"
        case .posizioni: return "In essere e in proposta"
        case .obiettivi: return "Un nome al futuro"
        case .confronti: return "Le ipotesi una accanto all'altra"
        case .prodotti: return "Condizioni, costi e fonti"
        case .simulazioni: return "Il tempo e le possibilità"
        case .agenda: return "Spazio alle relazioni"
        case .attivita: return "Un passo alla volta"
        case .note: return "Le parole da ricordare"
        case .documenti: return "Tutto al proprio posto"
        case .presentazioni: return "Il dettaglio per te, l'essenziale per il cliente"
        case .messaggi: return "Ruby prepara, tu spedisci"
        case .mercato: return "Quote, tassi e chi è toccato"
        case .studio: return "Il tuo lavoro, come un portafoglio"
        case .ruby: return "Un filo tra le tue app"
        case .ricerca: return "Ritrova ciò che conta"
        case .impostazioni: return "Il tuo modo di lavorare"
        case .territorio: return "Dove sono i tuoi clienti"
        case .pratiche: return "Dalla proposta al sinistro"
        case .sala: return "Da vivere insieme al cliente"
        case .biblioteca: return "La pagina giusta, subito"
        }
    }

    /// Occhiello dell'intestazione dentro la finestra.
    var occhiello: String {
        switch self {
        case .clienti: return "Rubrica Prisma"
        case .analisi360: return "Il centro della consulenza"
        case .incontri: return "Il tempo della relazione"
        case .posizioni: return "Il cuore della consulenza"
        case .obiettivi: return "Il quaderno dei progetti"
        case .confronti: return "Ipotesi trasparenti"
        case .prodotti: return "Schede e fonti verificabili"
        case .simulazioni: return "Il laboratorio delle ipotesi"
        case .agenda: return "Prisma · Agenda personale"
        case .attivita: return "Prisma · Promemoria"
        case .note: return "Taccuino personale"
        case .documenti: return "Archivio Prisma"
        case .presentazioni: return "Una prospettiva condivisa"
        case .messaggi: return "Ruby prepara, tu spedisci"
        // Nella testata l'occhiello lo scrive il motore del mercato (OcchielloMercato: «Aggiornato oggi alle 18:00»,
        // «Mai aggiornato»); questo resta per chi legge l'occhiello fisso dell'app
        case .mercato: return "Tassi, indici e quote, con la loro fonte"
        case .studio: return "Il tuo lavoro, come un portafoglio"
        case .ruby: return "Assistente personale"
        case .ricerca: return "Ritrova il filo"
        case .impostazioni: return "Il tuo sistema"
        case .territorio: return "I clienti nella tua zona"
        case .pratiche: return "Dalla proposta al sinistro"
        case .sala: return "Le esperienze da vivere con il cliente"
        case .biblioteca: return "Condizioni, circolari e normativa"
        }
    }

    /// Titolo dell'intestazione dentro la finestra.
    var titoloIntestazione: String {
        switch self {
        case .clienti: return "Le tue relazioni."
        case .impostazioni: return "Sentiti a casa."
        case .note: return "Un'idea alla volta."
        case .studio: return "Il tuo studio."
        case .messaggi: return "Prisma scrive per te."
        case .mercato: return "Prisma conosce il mercato."
        case .territorio: return "Il tuo territorio."
        case .pratiche: return "Le pratiche."
        case .sala: return "La sala."
        case .biblioteca: return "La tua biblioteca."
        default: return titolo
        }
    }

    /// Nome del file in Risorse/Icone (senza estensione).
    var icona: String {
        switch self {
        case .clienti: return "Clienti"
        case .analisi360: return "Analisi_360"
        case .incontri: return "Incontri"
        case .posizioni: return "Analisi"
        case .obiettivi: return "Obiettivi"
        case .confronti: return "Confronti"
        case .prodotti: return "Prodotti"
        case .simulazioni: return "Simulazioni"
        case .agenda: return "Agenda_base"
        case .attivita: return "Attivita"
        case .note: return "Note"
        case .documenti: return "Documenti"
        case .presentazioni: return "Presentazioni"
        case .messaggi: return "Messaggi"
        case .mercato: return "Mercato"
        case .studio: return "Studio"
        case .ruby: return "Ruby"
        case .ricerca: return "Ricerca"
        case .impostazioni: return "Impostazioni"
        // Le quattro icone di «Luce» (Design/Icone/genera-icone.js, dal template della versione)
        case .territorio: return "Territorio"
        case .pratiche: return "Pratiche"
        case .sala: return "Sala"
        case .biblioteca: return "Biblioteca"
        }
    }

    /// Fase in cui l'app viene sviluppata (per il messaggio delle app ancora vuote).
    var inArrivo: String {
        switch self {
        case .clienti: return "La rubrica e il dossier dei clienti arrivano con il modulo Clienti."
        case .agenda, .attivita: return "Appuntamenti, attività e scadenze delle posizioni."
        case .incontri: return "Preparazione, ascolto, appunti e decisioni, prossimi passi."
        case .posizioni:
            return "Il cuore di Prisma: le posizioni dei clienti, in essere e in proposta, con il canale Alleanza / indipendente sempre in vista."
        case .analisi360, .prodotti, .confronti, .simulazioni, .obiettivi:
            return "Fa parte del modulo Posizioni, il cuore di Prisma, con il canale Alleanza / indipendente sempre in vista."
        case .ruby: return "Ruby arriva con il suo modulo: lettura dei documenti, estrazione dei dati e risposte in chat, tutto sul Mac."
        case .documenti: return "KID, polizze ed estratti conto letti sul Mac, con i dati da confermare."
        case .presentazioni: return "Prospetti dettagliati per il consulente e report essenziali per il cliente, in PDF."
        case .messaggi:
            return "Ruby preparerà i messaggi ai clienti (scadenze, riesami, auguri) dai dati di Prisma, sul Mac: li leggerai, li correggerai e li spedirai tu."
        case .mercato:
            return "Quote dei fondi, tassi e indici aggiornati, con gli avvisi e i clienti toccati da ogni movimento."
        case .studio: return "Il cruscotto del tuo lavoro: ricavi, obiettivi dell'anno, proposte e incassi."
        case .note: return "Appunti, dettagli e prossimi passi, collegati alle persone."
        case .ricerca: return "Clienti, posizioni, documenti, agenda e attività in un'unica ricerca (⌘K)."
        case .impostazioni: return "Profilo, backup manuale e settimanale, ripristino e impostazioni di Ruby."
        // «Luce»: le quattro app nuove, il cui contenuto arriva nei giri successivi
        case .territorio:
            return "I clienti come luci sulla mappa della tua zona, la crescita negli anni e il giro di domani: arriva con un prossimo aggiornamento, tutto calcolato sul Mac."
        case .pratiche:
            return "La proposta che si costruisce dal bisogno, i moduli, le pratiche dopo la firma e i sinistri: arriva con un prossimo aggiornamento."
        case .sala:
            return "Le esperienze da vivere con il cliente arrivano con i prossimi aggiornamenti."
        case .biblioteca:
            return "Condizioni, circolari e normativa che carichi tu, con la pagina giusta trovata sul Mac: arriva con un prossimo aggiornamento."
        }
    }
}
