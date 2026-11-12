#if os(macOS)
import AppKit
#endif
import SwiftUI

// Il gesto del trackpad per la Vera della scrivania: due dita da destra a sinistra aprono Vera seguendo il dito,
// da sinistra a destra la richiudono; al rilascio decidono soglia e velocità (StatoShell.concludiGestoVera).
// Un DragGesture sul Mac risponde solo al clic e trascina, non allo scorrimento a due dita: serve un monitor
// locale degli eventi .scrollWheel. Si prende l'evento solo se è orizzontale e lo si usa; il resto passa.
// Anche Esc torna ai widget. Mai nelle istantanee e nelle prove (stato non persistente).

extension View {
    /// Accende il gesto della Vera della scrivania (solo Mac).
    func gestoVeraScrivania() -> some View {
        modifier(ModificatoreGestoVera())
    }
}

private struct ModificatoreGestoVera: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var modoIstantanea
    #if os(macOS)
    @State private var monitor = MonitorGestoVera()
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .onAppear { if !modoIstantanea && stato.persistente { monitor.avvia(stato) } }
            .onDisappear { monitor.ferma() }
        #else
        content
        #endif
    }
}

#if os(macOS)
/// Il monitor degli scorrimenti e di Esc. Vive con la shell; segue un gesto alla volta.
final class MonitorGestoVera {
    private weak var stato: StatoShell?
    private var monitor: Any?

    private enum Fase {
        /// Nessun gesto, o un gesto che non è nostro.
        case riposo
        /// Le dita si muovono: ancora non si sa se in orizzontale.
        case valuta
        /// Il gesto è nostro: la pagina segue il dito.
        case segue
        /// Il gesto è verticale (o non si può): passa tutto.
        case ignora
    }

    private var fase = Fase.riposo
    /// Spostamento del dito dall'inizio del gesto (negativo = verso sinistra).
    private var dito: CGFloat = 0
    private var verticale: CGFloat = 0
    /// Gli ultimi campioni (istante, dito) per la velocità al rilascio.
    private var campioni: [(tempo: TimeInterval, dito: CGFloat)] = []
    /// Dopo un gesto preso anche l'inerzia che segue è nostra (non deve scorrere i widget).
    private var consumaInerzia = false

    func avvia(_ s: StatoShell) {
        stato = s
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .keyDown]) { [weak self] e in
            guard let self else { return e }
            return e.type == .keyDown ? self.tasto(e) : self.scorri(e)
        }
    }

    func ferma() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }

    deinit { ferma() }

    /// Esc con Vera aperta sulla scrivania libera: si torna ai widget.
    private func tasto(_ e: NSEvent) -> NSEvent? {
        guard e.keyCode == 53, let s = stato, !(e.window is NSPanel), s.veraScrivaniaAperta, s.scrivaniaPerVera else { return e }
        s.nascondiVeraScrivania()
        return nil
    }

    private func scorri(_ e: NSEvent) -> NSEvent? {
        guard let s = stato else { return e }
        // L'inerzia dopo il rilascio
        if !e.momentumPhase.isEmpty {
            guard consumaInerzia else { return e }
            if e.momentumPhase.contains(.ended) || e.momentumPhase.contains(.cancelled) { consumaInerzia = false }
            return nil
        }
        // Solo il trackpad (con le fasi del gesto); la rotella del mouse passa. La mini Vera è un pannello a parte
        guard e.hasPreciseScrollingDeltas, !e.phase.isEmpty, !(e.window is NSPanel) else { return e }
        let larghezza = max(s.sistema.misura.width, 1)
        // Con lo scorrimento naturale i delta seguono già le dita; senza, vanno al contrario
        let segno: CGFloat = e.isDirectionInvertedFromDevice ? 1 : -1
        let dx = e.scrollingDeltaX * segno
        let dy = e.scrollingDeltaY * segno

        if e.phase.contains(.began) {
            consumaInerzia = false
            dito = 0
            verticale = 0
            campioni = []
            fase = s.scrivaniaPerVera ? .valuta : .ignora
        }
        if e.phase.contains(.changed) || e.phase.contains(.began) {
            switch fase {
            case .valuta:
                dito += dx
                verticale += dy
                guard hypot(dito, verticale) >= Tema.Misura.VeraScrivania.sogliaAvvio else { return e }
                let partenza = s.sistema.paginaVera
                let orizzontale = abs(dito) > abs(verticale) * Tema.Misura.VeraScrivania.rapportoOrizzontale
                // Verso Vera dalla scrivania, verso la scrivania da Vera
                let versoGiusto = (dito < 0 && partenza < 0.5) || (dito > 0 && partenza >= 0.5)
                guard orizzontale, versoGiusto else {
                    fase = .ignora
                    return e
                }
                fase = .segue
                let g = s.sistema.gestoVera
                g.partenza = partenza
                // La pagina parte da qui: lo spazio per decidere la direzione non diventa uno scatto
                g.avvio = dito
                g.attivo = true
                campiona(e.timestamp)
                g.segui(dito: dito, larghezza: larghezza)
                return nil
            case .segue:
                // La scrivania non è più libera (blocco, una finestra, un pannello): la pagina torna dov'era
                guard s.scrivaniaPerVera else {
                    s.concludiGestoVera(velocita: 0, annullato: true)
                    fase = .ignora
                    return nil
                }
                dito += dx
                campiona(e.timestamp)
                s.sistema.gestoVera.segui(dito: dito, larghezza: larghezza)
                return nil
            case .riposo, .ignora:
                return e
            }
        }
        if e.phase.contains(.ended) || e.phase.contains(.cancelled) {
            let mio = fase == .segue
            fase = .riposo
            guard mio else { return e }
            campiona(e.timestamp)
            // Velocità del dito in pagine al secondo (+ verso Vera, cioè dito verso sinistra)
            s.concludiGestoVera(velocita: -velocitaDito() / larghezza, annullato: e.phase.contains(.cancelled))
            consumaInerzia = e.phase.contains(.ended)
            return nil
        }
        return fase == .segue ? nil : e
    }

    private func campiona(_ t: TimeInterval) {
        campioni.append((t, dito))
        let limite = t - Tema.Moto.VeraScrivania.finestraVelocita
        campioni.removeAll { $0.tempo < limite }
    }

    /// Punti al secondo negli ultimi istanti del gesto (0 se il dito si era fermato).
    private func velocitaDito() -> CGFloat {
        guard let primo = campioni.first, let ultimo = campioni.last, ultimo.tempo - primo.tempo > 0.001 else { return 0 }
        return (ultimo.dito - primo.dito) / CGFloat(ultimo.tempo - primo.tempo)
    }
}
#endif
