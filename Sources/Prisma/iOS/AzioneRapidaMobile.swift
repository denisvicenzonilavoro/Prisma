#if os(iOS)
import SwiftUI
import UIKit

// L'azione rapida dall'icona di Prisma («Luce» giro 13, decisione 33): tenendo premuta l'icona sulla schermata Home,
// «Nota veloce» apre Incontri e la schermata «Una nota veloce». Solo questa: niente Siri, App Intents, tasto Azione,
// audio in background né compiti in background. La voce sta in `Supporto/iOS/Info.plist` (`UIApplicationShortcutItems`).
// Nelle istantanee e nelle prove non fa nulla (StatoMobile ascolta solo con l'archivio vero).

extension Notification.Name {
    /// «Nota veloce» dall'icona.
    static let prismaNotaVeloce = Notification.Name("prisma.notaVeloce")
}

enum AzioneRapidaMobile {
    /// Il tipo della voce in Info.plist.
    static let notaVeloce = "local.prisma.notaVeloce"
    /// L'azione è arrivata all'apertura, prima che lo stato ascolti: StatoMobile la raccoglie appena nasce.
    @MainActor static var notaVeloceInAttesa = false

    @MainActor
    static func esegui(_ voce: UIApplicationShortcutItem) -> Bool {
        guard voce.type == notaVeloce else { return false }
        notaVeloceInAttesa = true
        NotificationCenter.default.post(name: .prismaNotaVeloce, object: nil)
        return true
    }
}

/// Il delegato dell'app: dice al sistema di usare `DelegatoScenaMobile` per le scene (lì arrivano le azioni rapide).
final class DelegatoMobile: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let c = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        c.delegateClass = DelegatoScenaMobile.self
        return c
    }
}

/// Il delegato della scena: l'azione rapida all'apertura (app chiusa) e con l'app già aperta.
final class DelegatoScenaMobile: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let voce = connectionOptions.shortcutItem {
            Task { @MainActor in _ = AzioneRapidaMobile.esegui(voce) }
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Task { @MainActor in
            completionHandler(AzioneRapidaMobile.esegui(shortcutItem))
        }
    }
}
#endif
