import Combine
import Observation
import SwiftUI

// Proprietario: G1 (movimento delle finestre). Creato dalle fondamenta (G0).

/// Finestre interne, pannelli e blocco: lo osservano solo shell, dock, barra e pannelli,
/// così aprire o cambiare app non ricalcola il contenuto delle app aperte né i widget.
/// StatoShell lo tiene in `sistema` e ne inoltra le proprietà con i nomi di sempre.
@Observable final class StatoFinestre {
    typealias Finestra = StatoShell.Finestra

    /// Quante volte è cambiata una proprietà osservata (la prova della fluidità, colonna «avvisi StatoFinestre»; prima
    /// erano gli `objectWillChange`).
    @ObservationIgnored var avvisi = 0
    /// Il blocco che sta per cambiare, con il valore nuovo (al posto di `$bloccato`: menu Vai, copilota dell'incontro).
    /// Come `$bloccato`, all'iscrizione dà subito il valore di adesso.
    @ObservationIgnored let bloccatoCambiera = CurrentValueSubject<Bool, Never>(false)
    /// L'elenco delle finestre è cambiato (al posto di `$elenco`: le app nella finestra di vetro di iPhone e iPad).
    /// Come `$elenco`, avvisa anche all'iscrizione.
    @ObservationIgnored let elencoCambiato = CurrentValueSubject<Void, Never>(())

    /// Finestre aperte; l'ultima è quella in primo piano.
    var elenco: [Finestra] = [] {
        didSet { avvisi &+= 1; elencoCambiato.send() }
    }
    /// La schermata di benvenuto copre le finestre (il lucchetto in alto).
    var bloccato = false {
        willSet { bloccatoCambiera.send(newValue) }
        didSet { avvisi &+= 1 }
    }
    var pannelloAppAperte = false { didSet { avvisi &+= 1 } }
    /// Il pannello degli spazi di lavoro è aperto.
    var pannelloSpazi = false { didSet { avvisi &+= 1 } }
    var pannelloNotifiche = false { didSet { avvisi &+= 1 } }
    /// Il pannello «Le novità» (✦ Novità nella barra, versione «Orizzonte»): sopra le notifiche, sotto il blocco.
    var pannelloNovita = false { didSet { avvisi &+= 1 } }
    /// La sovrapposizione a tutto palco della versione «Luce» (SovrapposizioneLuce.swift): una sola alla volta.
    var sovrapposizione: SovrapposizioneLuce? = nil { didSet { avvisi &+= 1 } }
    /// Il pannello di ricerca (⌘K, come Spotlight) è aperto: sta sopra tutto, non è una finestra.
    var pannelloRicerca = false { didSet { avvisi &+= 1 } }
    /// Il pannello «Guida di Prisma» aperto, con la sua pagina (nil = chiuso). Lo osservano solo la shell e il pannello.
    var guida: PaginaGuida? = nil { didSet { avvisi &+= 1 } }
    /// Finestre appena aperte che aspettano il giro dopo per animarsi (G1).
    var inArrivo: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// FLIP in corso: cornice di partenza e progresso (G1).
    var flip: [AppPrisma: PassaggioCornice] = [:] { didSet { avvisi &+= 1 } }
    /// Finestre del tutto coperte da una finestra ingrandita, a transizione finita: non si disegnano (G1).
    var coperte: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// Finestre ridotte nel dock a genio finito: i loro controlli sono spenti (i tasti non ci finiscono).
    var spente: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// Finestre coperte dalla loro istantanea durante un effetto di Core Animation (genio, chiusura: MotoreGenio):
    /// si disegnano a opacità 0, di colpo, e non ricevono clic. Con il vetro di Apple la finestra viva non si
    /// può deformare né sfumare senza fantasmi: si muove la sua istantanea.
    var nascoste: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// App il cui genio è in corso: il dock resta in vista anche se dovrebbe essere nascosto (come macOS con
    /// il dock nascosto, che lo mostra durante la riduzione), così il genio va in un'icona che si vede.
    var dockPerEffetti: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// Finestre chiuse che rientrano nella loro icona del dock: restano nell'elenco finché il volo non finisce.
    var rientrano: Set<AppPrisma> = [] { didSet { avvisi &+= 1 } }
    /// Dove sono le icone del dock e da dove escono le finestre (non pubblicato: VoloFinestra.swift).
    let iconeDock = RegistroIconeDock()
    /// Finestre chiuse che si tolgono al giro dopo (prima si nascondono, così escono senza transizione): non pubblicato.
    @ObservationIgnored var inChiusura: Set<AppPrisma> = []
    /// Da dove si apre ogni app (coordinate `ShellView.spazioShell`): non pubblicato, si legge all'apertura.
    /// Riducendo un'app vale il centro della sua icona nel dock, dove va il «genio».
    @ObservationIgnored var origini: [AppPrisma: CGPoint] = [:]
    /// La scrivania sta sotto una finestra ingrandita, a transizione finita: non si disegna (resta montata).
    var scrivaniaNascosta = false { didSet { avvisi &+= 1 } }
    /// La pagina della scrivania (VeraScrivania.swift): 0 = i widget, 1 = Vera. A riposo vale 0 o 1; il dito
    /// la sposta in `gestoVera`, che osservano solo le due pagine (seguire il gesto non ridisegna la shell).
    var paginaVera: CGFloat = 0 { didSet { avvisi &+= 1 } }
    let gestoVera = GestoPaginaVera()
    /// Il blocco a transizione finita: l'acqua non riparte né si ferma a metà dell'animazione, e la scrivania
    /// nascosta si prepara all'entrata dello sblocco.
    var bloccatoStabile = false { didSet { avvisi &+= 1 } }
    /// Misura della shell (non pubblicata): serve a sapere dov'è l'icona di un'app nel dock.
    @ObservationIgnored var misura: CGSize = .zero
    // Contatori delle transizioni (non pubblicati): un lavoro rimandato vale solo se nel frattempo non ne è partita un'altra
    @ObservationIgnored var giroCoperte = 0
    @ObservationIgnored var giroBlocco = 0
    @ObservationIgnored var giroScrivania = 0
    @ObservationIgnored var giroPresentazione = 0

    var visibili: [Finestra] { elenco.filter { !$0.ridotta } }
    /// App in primo piano (nil = scrivania).
    /// Una finestra chiusa che rientra nell'icona (`rientrano`) non è più in primo piano: lo diventa subito quella sotto.
    var appAttiva: AppPrisma? { visibili.last(where: { !rientrano.contains($0.app) })?.app }
    func aperta(_ app: AppPrisma) -> Bool { elenco.contains { $0.app == app } }
}

/// Un passaggio FLIP: la cornice da cui parte la finestra (coordinate dell'area delle finestre) e a che punto è.
struct PassaggioCornice: Equatable {
    var da: CGRect
    var progresso: CGFloat
}

/// Solo ciò che cambia titoli e abilitazioni del menu Vai: il menu non osserva StatoShell.
/// Resta un ObservableObject: lo osserva solo ComandiPrisma, un `Commands`, dove `@ObservedObject` è la strada sicura.
final class StatoMenu: ObservableObject {
    @Published private(set) var bloccato = false
    @Published private(set) var inModoCliente = false
    @Published private(set) var inPresentazione = false
    @Published private(set) var conversazioneAVoce = false

    /// Copia i valori solo se cambiano: il menu si ricostruisce il meno possibile.
    func aggiorna(bloccato: Bool, inModoCliente: Bool, inPresentazione: Bool, conversazioneAVoce: Bool) {
        if self.bloccato != bloccato { self.bloccato = bloccato }
        if self.inModoCliente != inModoCliente { self.inModoCliente = inModoCliente }
        if self.inPresentazione != inPresentazione { self.inPresentazione = inPresentazione }
        if self.conversazioneAVoce != conversazioneAVoce { self.conversazioneAVoce = conversazioneAVoce }
    }
}
