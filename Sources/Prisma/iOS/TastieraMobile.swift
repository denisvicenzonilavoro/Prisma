#if os(iOS)
import SwiftUI
import UIKit
import Combine

/// L'altezza della tastiera sull'iPhone (13 novembre 2026). Il guscio ignora la tastiera (il dock e la barra non
/// saltano su) e con la tastiera aperta accorcia la finestra fin sopra di lei e nasconde il dock: così il campo in
/// cui si scrive resta in vista e il dock non finisce sopra la tastiera. Dalle notifiche di sistema, niente Timer.
final class TastieraMobile: ObservableObject {
    /// Quanto copre la tastiera dal bordo in basso dello schermo (0 = chiusa).
    @Published private(set) var altezza: CGFloat = 0
    private var osservatori: [AnyCancellable] = []

    init() {
        let centro = NotificationCenter.default
        centro.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: centro.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] n in self?.aggiorna(n) }
            .store(in: &osservatori)
    }

    private func aggiorna(_ n: Notification) {
        guard n.name != UIResponder.keyboardWillHideNotification,
              let fine = (n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            if altezza != 0 { altezza = 0 }
            return
        }
        let schermo = UIScreen.main.bounds.height
        // Una tastiera esterna o fuori schermo lascia solo la barra dei suggerimenti, o niente
        let nuova = max(0, schermo - fine.minY)
        if abs(nuova - altezza) > 0.5 { altezza = nuova }
    }
}
#endif
