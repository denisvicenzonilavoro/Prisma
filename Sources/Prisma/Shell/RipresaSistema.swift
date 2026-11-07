#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Combine

// Proprietario: G2 (ciclo di vita).

#if os(macOS)
extension StatoShell {
    /// Stop del Mac e schermo spento: prima di dormire i lavori a tempo si fermano (notifiche, promemoria,
    /// backup automatico) e i dati cambiati partono per il disco; al risveglio l'interfaccia c'è già, ferma
    /// com'era, e i controlli ripartono dopo `attesaDopoRisveglio`, così il risveglio resta libero.
    /// Niente animazioni; l'acqua la ferma e la fa ripartire lo sfondo da sé.
    /// Con il Mac a riposo, lo schermo spento o bloccato e l'utente che cambia sessione Prisma si chiude sotto la
    /// schermata di benvenuto, di colpo: al ritorno c'è il cursore da trascinare, e allo sblocco i widget.
    /// La chiama `init` solo con l'archivio sul disco (mai nelle istantanee e nelle prove).
    func avviaRipresa() {
        let centro = NSWorkspace.shared.notificationCenter
        for nome in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification] {
            centro.publisher(for: nome)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    // Prima il blocco (di colpo), poi gli effetti delle finestre (Core Animation) finiscono:
                    // al risveglio tutto è fermo, sotto la schermata di benvenuto
                    self?.bloccaPerRiposo()
                    self?.annullaEffetti()
                    self?.sospendiLavoriATempo()
                }
                .store(in: &abbonamenti)
        }
        // Lo schermo bloccato (⌃⌘Q, salvaschermo con la password) e il cambio di utente: solo il blocco
        centro.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.bloccaPerRiposo() }
            .store(in: &abbonamenti)
        DistributedNotificationCenter.default().publisher(for: Notification.Name("com.apple.screenIsLocked"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.bloccaPerRiposo() }
            .store(in: &abbonamenti)
        for nome in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            centro.publisher(for: nome)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.riprendiLavoriATempo(dopo: StatoShell.attesaDopoRisveglio) }
                .store(in: &abbonamenti)
        }
    }

    /// La schermata di benvenuto, di colpo, se non c'è già (mai nelle istantanee e nelle prove).
    func bloccaPerRiposo() {
        guard persistente, !bloccato else { return }
        blocca(animato: false)
    }
}
#elseif os(iOS)
extension StatoShell {
    /// Su iPhone e iPad il sonno del Mac non c'è: Prisma va in background. Lì i lavori a tempo si fermano e i dati
    /// cambiati partono per il disco; tornando in primo piano i controlli ripartono poco dopo.
    func avviaRipresa() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.annullaEffetti()
                self?.sospendiLavoriATempo()
            }
            .store(in: &abbonamenti)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.riprendiLavoriATempo(dopo: StatoShell.attesaRitornoPrimoPiano) }
            .store(in: &abbonamenti)
    }

    /// Tornando in primo piano su iPhone e iPad i controlli ripartono dopo un secondo (non c'è un risveglio da lasciare libero).
    static let attesaRitornoPrimoPiano: Double = 1
}
#endif
