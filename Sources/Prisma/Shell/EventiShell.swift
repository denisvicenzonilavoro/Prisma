import Combine
import SwiftUI

/// Gli eventi interni della shell a cui altre parti rispondono (per esempio l'acqua con le sue gocce), senza
/// che chi li manda sappia chi ascolta. Li tiene StatoShell in `eventiShell`; non sono pubblicati: ascoltarli
/// non ridisegna niente finché non arriva un evento.
///
///     // In una vista
///     .allaSblocco { RispostaAcqua.condivisa.gocciaAlCentro(peso: …) }
///     .allaNotificaNuova { evento in if let c = evento.campanella { … } }
///     // Fuori dalle viste (Combine)
///     stato.eventiShell.sblocco.sink { … }
final class EventiShell {
    /// Lo sblocco: parte nell'istante in cui la schermata di blocco comincia ad andarsene (StatoShell.allaSblocco).
    let sblocco = PassthroughSubject<Void, Never>()
    /// Una notifica nuova (il numero sulla campanella cresce, con Prisma sbloccata).
    let notificaNuova = PassthroughSubject<NotificaNuovaShell, Never>()
    /// Dove sta la campanella adesso, in coordinate `.global` (come `puntoAcqua`); nil se non è in vista.
    /// La aggiorna `.segnaCampanella()`; non è pubblicata.
    var campanella: CGRect?
    /// Quante notifiche erano nuove quando il pannello si è aperto (il pannello le segna subito come viste).
    var nuoveAllApertura = 0
}

/// Una notifica nuova: quante sono arrivate e dove sta la campanella (coordinate `.global`, nil se non si vede).
struct NotificaNuovaShell {
    let quante: Int
    let campanella: CGRect?
}

extension StatoShell {
    /// Il punto unico dello sblocco: lo chiama `sblocca`, appena tolta la schermata di blocco (anche nelle prove
    /// e nelle istantanee: chi ascolta decide se rispondere, per esempio l'acqua solo se può muoversi).
    func allaSblocco() {
        eventiShell.sblocco.send(())
    }

    /// Dopo un ricalcolo delle notifiche: se le nuove sono cresciute e Prisma non è bloccata, manda l'evento con
    /// la posizione della campanella. `prima`: le nuove prima del ricalcolo.
    func annunciaNotificheNuove(prima: Int) {
        let ora = notificheNuove
        guard ora > prima, !bloccato else { return }
        eventiShell.notificaNuova.send(NotificaNuovaShell(quante: ora - prima, campanella: eventiShell.campanella))
    }
}

extension View {
    /// Esegue `azione` a ogni sblocco di Prisma.
    func allaSblocco(_ azione: @escaping () -> Void) -> some View {
        modifier(AscoltoSblocco(azione: azione))
    }

    /// Esegue `azione` a ogni notifica nuova, con la posizione della campanella.
    func allaNotificaNuova(_ azione: @escaping (NotificaNuovaShell) -> Void) -> some View {
        modifier(AscoltoNotificaNuova(azione: azione))
    }

    /// Segna questa vista come la campanella delle notifiche: la sua cornice (coordinate `.global`) va in
    /// `eventiShell.campanella`, letta da chi riceve l'evento «notifica nuova».
    func segnaCampanella() -> some View {
        modifier(SegnoCampanella())
    }
}

private struct AscoltoSblocco: ViewModifier {
    @EnvironmentObject var stato: StatoShell
    let azione: () -> Void

    func body(content: Content) -> some View {
        content.onReceive(stato.eventiShell.sblocco) { _ in azione() }
    }
}

private struct AscoltoNotificaNuova: ViewModifier {
    @EnvironmentObject var stato: StatoShell
    let azione: (NotificaNuovaShell) -> Void

    func body(content: Content) -> some View {
        content.onReceive(stato.eventiShell.notificaNuova) { evento in azione(evento) }
    }
}

/// Tiene aggiornata la cornice della campanella senza ridisegnare niente (la classe non è pubblicata).
private struct SegnoCampanella: ViewModifier {
    @EnvironmentObject var stato: StatoShell

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { geo in
                let spazio: CoordinateSpace = .global
                let cornice = geo.frame(in: spazio)
                let eventi = stato.eventiShell
                Color.clear
                    .onAppear { eventi.campanella = cornice }
                    .onChange(of: cornice) { nuova in eventi.campanella = nuova }
                    .onDisappear { if eventi.campanella == cornice { eventi.campanella = nil } }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
