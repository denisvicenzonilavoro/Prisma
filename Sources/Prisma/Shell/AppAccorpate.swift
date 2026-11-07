import Foundation

/// Le app accorpate (`AppPrisma.ospite`): sul Mac non hanno più una finestra propria. `apri(_:)` le porta
/// nell'app che le ospita, sulla scheda giusta: Obiettivi e Documenti in Clienti, Simulazioni e Confronti
/// negli strumenti di Analisi 360, Attività nell'Agenda (vista mese). iPhone e iPad restano come prima.
extension StatoShell {
    /// Prepara l'ospite a mostrare l'app accorpata (non apre nulla: lo fa `apri`).
    func preparaOspite(per app: AppPrisma) {
        switch app {
        case .obiettivi: if schedaCliente != .obiettivi { schedaCliente = .obiettivi }
        case .documenti: if schedaCliente != .documenti { schedaCliente = .documenti }
        case .simulazioni: scegliStrumentoAnalisi(StatoShell.strumento(per: schedaSimulazioni))
        case .confronti: scegliStrumentoAnalisi(.confronto)
        case .attivita: selezionaAttivitaInAgenda(attivitaSelezionata)
        default: break
        }
    }

    /// L'app accorpata che l'ospite sta mostrando (nil se l'app non ospita nulla o mostra il suo contenuto).
    /// Serve dove prima si chiedeva `appAttiva == .documenti` e simili.
    func accorpataMostrata(in ospite: AppPrisma) -> AppPrisma? {
        switch ospite {
        case .clienti:
            switch schedaCliente {
            case .obiettivi: return .obiettivi
            case .documenti: return .documenti
            default: return nil
            }
        case .analisi360:
            switch strumentoAnalisi {
            case .confronto: return .confronti
            case .simulatore, .scenari, .tfr: return .simulazioni
            case nil: return nil
            }
        default:
            return nil
        }
    }

    /// Vero se davanti c'è l'app (con icona propria o accorpata nel suo ospite).
    func inPrimoPiano(_ app: AppPrisma) -> Bool {
        #if os(macOS)
        if let ospite = app.ospite {
            // L'Attività non ha una scheda: vale l'Agenda davanti con l'attività scelta
            if app == .attivita { return appAttiva == .agenda }
            return appAttiva == ospite && accorpataMostrata(in: ospite) == app
        }
        #endif
        return appAttiva == app
    }

    /// Mostra le attività nell'Agenda (vista mese) e, se c'è, l'attività scelta nel giorno della sua scadenza.
    func mostraAttivitaInAgenda(_ id: String? = nil) {
        selezionaAttivitaInAgenda(id ?? attivitaSelezionata)
        apri(.agenda)
    }

    /// Lo stato dell'Agenda per un'attività (senza aprire nulla): vista mese, giorno della scadenza, selezione.
    func selezionaAttivitaInAgenda(_ id: String?) {
        if vistaAgenda != .mese { vistaAgenda = .mese }
        guard let id, let a = attivita.first(where: { $0.id == id }) else { return }
        if attivitaSelezionata != id { attivitaSelezionata = id }
        giornoAgenda = Calendar.current.startOfDay(for: a.scadenza)
        // Il dettaglio dell'agenda resta libero per l'attività
        appuntamentoSelezionato = nil
        occasioneSelezionata = nil
        if filtroClienteAgenda != nil && filtroClienteAgenda != a.clienteId { filtroClienteAgenda = nil }
    }
}
