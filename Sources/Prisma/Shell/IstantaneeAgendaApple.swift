#if os(macOS)
import Foundation

/// Le istantanee dell'Agenda nel tema Apple (§4.4): la vista Settimana del template (barra laterale con il mese a
/// puntini, «Questa settimana» e «Da non dimenticare», la settimana a pillola, la giornata di oggi con la fascia
/// «Da fare e da ricordare», gli impegni e la linea dell'ora ferma alle 10:24), in chiaro e in scuro; la vista
/// Giorno con la colonna del giorno; la traccia dell'impegno di Giulia già aperta. Le cifre vengono dai motori di
/// Prisma sui dati di prova (date relative a oggi).
extension Istantanee {
    nonisolated static var sceneAgendaApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("450-agenda-apple", { s in preparaAgendaApple(s, vista: .settimana) }),
            ("450-agenda-apple-scuro", { s in preparaAgendaApple(s, vista: .settimana) }),
            ("451-agenda-giornata", { s in preparaAgendaApple(s, vista: .giorno) }),
            ("452-agenda-traccia-impegno", { s in
                RichiestaIstantaneaAgenda.chiedi(s, impegno: "event-giulia")
                preparaAgendaApple(s, vista: .settimana)
            }),
        ]
    }

    /// L'Agenda aperta su oggi, con una cosa rimasta indietro (Marco) nella fascia della giornata.
    nonisolated static func preparaAgendaApple(_ s: StatoShell, vista: VistaAgenda) {
        attivitaRimastaIndietro(s)
        s.giornoAgenda = Calendar.current.startOfDay(for: Date())
        s.vistaAgenda = vista
        s.filtroClienteAgenda = nil
        s.appuntamentoSelezionato = nil
        s.occasioneSelezionata = nil
        s.attivitaSelezionata = nil
        s.apri(.agenda)
    }
}
#endif
