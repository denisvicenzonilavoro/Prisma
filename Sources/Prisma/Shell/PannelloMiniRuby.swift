#if os(macOS)
import AppKit
import Carbon
import Combine
import SwiftUI

/// Il pannello della mini finestra di Ruby: non attiva Prisma (resta l'app che stai usando), galleggia sopra le altre
/// finestre e sta in alto a destra, sotto la barra di Prisma (o sotto la barra dei menu se Prisma non si vede).
/// Trasparente: la superficie di vetro e la sua ombra le disegna SwiftUI (VistaMiniRuby).
final class PannelloMiniRuby: NSPanel {
    /// Esc.
    var esc: () -> Void = {}

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
        isMovableByWindowBackground = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
    }

    // Il campo per scrivere riceve la tastiera anche con Prisma in secondo piano (come Spotlight)
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        esc()
    }

    /// La finestra di Prisma (non i pannelli), se c'è.
    static func finestraPrisma() -> NSWindow? {
        NSApp.windows.first { !($0 is NSPanel) && $0.contentView != nil && $0.canBecomeMain && $0.frame.width > 400 }
    }
}

/// Apre e chiude il pannello seguendo `StatoMiniRuby`, ne regola l'altezza e ascolta ⌥ Spazio.
final class ControlloMiniRuby {
    static let condiviso = ControlloMiniRuby()

    private weak var stato: StatoShell?
    private var pannello: PannelloMiniRuby?
    private var abbonamenti = Set<AnyCancellable>()
    private var timerTenuto: Timer?

    /// All'avvio di Prisma: la scorciatoia globale e il pannello pronto a comparire.
    func avvia(stato: StatoShell) {
        guard self.stato == nil else { return }
        self.stato = stato
        let mini = stato.miniRuby
        mini.$visibile
            .removeDuplicates()
            .sink { [weak self] v in self?.mostra(v) }
            .store(in: &abbonamenti)
        // Durante la presentazione al cliente Ruby si ritira
        stato.$presentazione
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak stato] p in if p { stato?.chiudiMiniRuby() } }
            .store(in: &abbonamenti)
        let tasto = ScorciatoiaGlobale.condivisa
        tasto.premuto = { [weak self] in self?.premuto() }
        tasto.rilasciato = { [weak self] in self?.rilasciato() }
        if !tasto.registra() {
            DiagnosticaVoce.annota("⌥ Spazio è già usato da un'altra app: Ruby si chiama dalla sfera nella barra")
        }
    }

    // MARK: - ⌥ Spazio

    private func premuto() {
        guard let stato else { return }
        _ = stato.miniRuby.gesto.premi(Date())
        timerTenuto?.invalidate()
        timerTenuto = Timer.scheduledTimer(withTimeInterval: Tema.Moto.MiniRuby.sogliaTenuto, repeats: false) { [weak self] _ in
            guard let self, let stato = self.stato else { return }
            if stato.miniRuby.gesto.tieni(Date()) == .iniziaAParlare { stato.apriMiniRuby(.ascolta) }
        }
    }

    private func rilasciato() {
        guard let stato else { return }
        timerTenuto?.invalidate()
        timerTenuto = nil
        let mini = stato.miniRuby
        switch mini.gesto.rilascia(Date()) {
        case .finisciDiParlare:
            stato.fineAscoltoMiniRuby()
        case .scrivi:
            // Già aperta per scrivere e ancora vuota: un altro ⌥ Spazio la chiude
            if mini.visibile, mini.fase == .scrivi, mini.testo.isEmpty {
                stato.chiudiMiniRuby()
            } else {
                stato.apriMiniRuby(.scrivi)
            }
        case .nessuno, .iniziaAParlare:
            break
        }
    }

    // MARK: - Pannello

    private func mostra(_ visibile: Bool) {
        guard let stato else { return }
        if visibile {
            let p = pannello ?? crea(stato)
            p.appearance = NSApp.appearance
            posiziona(p)
            p.alphaValue = 1
            p.orderFrontRegardless()
            p.makeKey()
        } else if let p = pannello {
            DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.MiniRuby.durataUscita) {
                if !stato.miniRuby.visibile { p.orderOut(nil) }
            }
        }
    }

    private func crea(_ stato: StatoShell) -> PannelloMiniRuby {
        let p = PannelloMiniRuby()
        p.esc = { [weak stato] in stato?.chiudiMiniRuby() }
        let vista = VistaMiniRuby()
            .environmentObject(stato)
            .environmentObject(stato.miniRuby)
        let host = NSHostingView(rootView: vista)
        // La misura del pannello la decide il controllo, non il contenuto
        host.sizingOptions = []
        p.contentView = host
        pannello = p
        return p
    }

    /// In alto a destra: sotto la barra di Prisma se la sua finestra si vede, altrimenti sotto la barra dei menu.
    /// Il pannello arriva fino in fondo allo schermo: la superficie è alta quanto serve (la scheda della risposta
    /// non scorre se c'è posto) e sotto di lei il pannello è trasparente (i clic passano alle finestre dietro).
    private func posiziona(_ p: NSPanel) {
        let m = Tema.Misura.MiniRuby.self
        let larghezza = m.larghezzaScheda + 2 * m.margineOmbraLati
        let destra: CGFloat, alto: CGFloat
        let finestra = PannelloMiniRuby.finestraPrisma()
        let schermo = (finestra?.screen ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        if let f = finestra, f.isVisible, !f.isMiniaturized, f.occlusionState.contains(.visible) {
            destra = f.frame.maxX - m.distanzaDestra
            alto = f.frame.maxY - Tema.Misura.barra - m.distanzaBarra
        } else {
            destra = schermo.maxX - m.distanzaDestra
            alto = schermo.maxY - m.distanzaBarra
        }
        let disponibile = max(m.altezzaMinima, alto - schermo.minY - m.margineSchermo - m.margineOmbraSotto)
        if let mini = stato?.miniRuby, mini.altezzaMassima != disponibile { mini.altezzaMassima = disponibile }
        let altezza = disponibile + m.margineOmbraSopra + m.margineOmbraSotto
        let cornice = NSRect(x: destra + m.margineOmbraLati - larghezza, y: alto + m.margineOmbraSopra - altezza,
                             width: larghezza, height: altezza)
        if p.frame != cornice { p.setFrame(cornice, display: true) }
    }
}

/// ⌥ Spazio da qualsiasi app (RegisterEventHotKey di Carbon): avvisa quando il tasto va giù e quando torna su.
final class ScorciatoiaGlobale {
    static let condivisa = ScorciatoiaGlobale()

    var premuto: () -> Void = {}
    var rilasciato: () -> Void = {}
    private var tasto: EventHotKeyRef?
    private var gestore: EventHandlerRef?

    /// true se la scorciatoia è registrata (false se un'altra app usa già ⌥ Spazio).
    func registra() -> Bool {
        guard tasto == nil else { return true }
        var tipi = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                    EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))]
        let esitoGestore = InstallEventHandler(GetApplicationEventTarget(), { _, evento, _ -> OSStatus in
            guard let evento else { return OSStatus(eventNotHandledErr) }
            let giu = GetEventKind(evento) == UInt32(kEventHotKeyPressed)
            DispatchQueue.main.async {
                if giu { ScorciatoiaGlobale.condivisa.premuto() } else { ScorciatoiaGlobale.condivisa.rilasciato() }
            }
            return noErr
        }, tipi.count, &tipi, nil, &gestore)
        guard esitoGestore == noErr else { return false }
        // «PRSM»: la firma della scorciatoia di Prisma
        let id = EventHotKeyID(signature: OSType(0x5052_534D), id: 1)
        let esito = RegisterEventHotKey(UInt32(kVK_Space), UInt32(optionKey), id, GetApplicationEventTarget(), 0, &tasto)
        return esito == noErr
    }
}
#endif
