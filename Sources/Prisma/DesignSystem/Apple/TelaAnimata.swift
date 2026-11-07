import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// La tela animata della versione «Luce» (Design/template-luce-specifica.md §1.4.1 punto 4.3, §1.4.3): un disegno che
// cambia a ogni fotogramma (coriandoli dei traguardi, onda della nota vocale, l'automobile del giro di domani…).
// Niente Timer: `TimelineView(.animation)` con un `Canvas`. La pausa è centralizzata come per l'acqua: con «Riduci
// movimento» (`\.prismaCalmo`), nelle istantanee (`\.modoIstantanea`, `\.prismaStatoFinale`), con la finestra di
// Prisma che non si vede (nascosta, ridotta, coperta) o con il Mac (o il dispositivo) a riposo la tela disegna un solo
// fotogramma: quello finale (`tempoFinale`). Una sola tela viva per volta è la regola delle esperienze (8 GB).

/// Se Prisma si vede: finestra visibile e Mac sveglio (iPhone e iPad: app in primo piano). Uno solo per tutta l'app.
final class VisibilitaPrisma: NSObject, ObservableObject {
    static let condivisa = VisibilitaPrisma()

    @Published private(set) var visibile = true

    #if os(macOS)
    private var aRiposo = false
    #endif

    private override init() {
        super.init()
        #if os(macOS)
        let centro = NotificationCenter.default
        for nome in [NSWindow.didChangeOcclusionStateNotification, NSApplication.didHideNotification,
                     NSApplication.didUnhideNotification] {
            centro.addObserver(self, selector: #selector(aggiorna), name: nome, object: nil)
        }
        let spazio = NSWorkspace.shared.notificationCenter
        for nome in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification] {
            spazio.addObserver(self, selector: #selector(riposo), name: nome, object: nil)
        }
        for nome in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            spazio.addObserver(self, selector: #selector(risveglio), name: nome, object: nil)
        }
        #elseif os(iOS)
        let centro = NotificationCenter.default
        centro.addObserver(self, selector: #selector(aggiorna), name: UIApplication.didEnterBackgroundNotification, object: nil)
        centro.addObserver(self, selector: #selector(aggiorna), name: UIApplication.willEnterForegroundNotification, object: nil)
        centro.addObserver(self, selector: #selector(aggiorna), name: UIApplication.didBecomeActiveNotification, object: nil)
        #endif
    }

    #if os(macOS)
    @objc private func riposo() {
        DispatchQueue.main.async { [weak self] in
            self?.aRiposo = true
            self?.aggiorna()
        }
    }

    @objc private func risveglio() {
        DispatchQueue.main.async { [weak self] in
            self?.aRiposo = false
            self?.aggiorna()
        }
    }
    #endif

    @objc private func aggiorna() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.aggiorna() }
            return
        }
        #if os(macOS)
        let finestra = NSApp?.windows.contains { $0.isVisible && $0.occlusionState.contains(.visible) && !$0.isMiniaturized } ?? true
        let nuovo = finestra && !(NSApp?.isHidden ?? false) && !aRiposo
        #elseif os(iOS)
        let nuovo = UIApplication.shared.applicationState != .background
        #else
        let nuovo = true
        #endif
        if nuovo != visibile { visibile = nuovo }
    }
}

/// Un disegno animato: `disegna` riceve il contesto, la misura e il tempo in secondi dall'apparizione. Con la pausa
/// (calmo, istantanea, Prisma non visibile) si disegna solo `tempoFinale`: lo stato finale del movimento.
struct TelaAnimata: View {
    /// Il tempo dello stato finale (per esempio la fine dei coriandoli). Le animazioni cicliche danno il fotogramma
    /// più leggibile.
    var tempoFinale: Double = 0
    /// Fotogrammi al secondo al più (30, come l'acqua; con il risparmio energetico 20).
    var fotogrammi: Double = Double(Misure.Acqua.fotogrammiAlSecondo)
    let disegna: (inout GraphicsContext, CGSize, Double) -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaStatoFinale) private var fermo
    @ObservedObject private var visibilita = VisibilitaPrisma.condivisa
    @State private var inizio = Date()

    init(tempoFinale: Double = 0, fotogrammi: Double = Double(Misure.Acqua.fotogrammiAlSecondo),
         disegna: @escaping (inout GraphicsContext, CGSize, Double) -> Void) {
        self.tempoFinale = tempoFinale
        self.fotogrammi = fotogrammi
        self.disegna = disegna
    }

    /// La tela è ferma sullo stato finale.
    private var inPausa: Bool { calmo || istantanea || fermo || !visibilita.visibile }

    private var intervallo: Double {
        let fps = ProcessInfo.processInfo.isLowPowerModeEnabled ? Double(Misure.Acqua.fotogrammiAlSecondoBassoConsumo) : fotogrammi
        return 1 / max(1, fps)
    }

    var body: some View {
        let pausa = inPausa
        TimelineView(.animation(minimumInterval: intervallo, paused: pausa)) { contesto in
            let t = pausa ? tempoFinale : max(0, contesto.date.timeIntervalSince(inizio))
            Canvas { c, misura in
                disegna(&c, misura, t)
            }
        }
        .accessibilityHidden(true)
    }
}
