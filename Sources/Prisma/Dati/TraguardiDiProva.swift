import Foundation

/// I due traguardi del template (Design/template-luce-specifica.md §5.4.6), solo nei dati di prova (`DatiPrisma.demo()`
/// e quindi `ClientiFittizi.completi()`), con le date relative a oggi. DATI DI PROVA DICHIARATI: il pannello lo dice
/// accanto al perché («dati di prova»).
/// - Sofia Romano: l'obiettivo di prova «Rendita integrativa» (120.000 €, nato cinque anni e mezzo fa) raggiunto ieri, con
///   una frase sul regalo nelle note dell'obiettivo (da lì viene l'idea);
/// - Giulia Rossi: il primo incontro di prova, concluso un anno e due giorni fa: «Un anno insieme».
enum TraguardiDiProva {
    static let obiettivoSofia = "obiettivo-sofia-rendita-prova"
    static let primoIncontroGiulia = "event-giulia-primo-incontro-prova"

    static func applica(_ d: inout DatiPrisma, oggi: Date = Date(), calendario: Calendar = Calendar(identifier: .gregorian)) {
        let inizio = calendario.startOfDay(for: oggi)
        func mezzogiorno(_ g: Date) -> Date { calendario.date(bySettingHour: 12, minute: 0, second: 0, of: g) ?? g }
        let ieri = mezzogiorno(calendario.date(byAdding: .day, value: -1, to: inizio) ?? inizio)
        if d.clienti.contains(where: { $0.id == "sofia" }), !d.obiettivi.contains(where: { $0.id == obiettivoSofia }) {
            var o = Obiettivo(clienteId: "sofia", titolo: "Rendita integrativa", area: .pensione, importo: 120_000, scadenza: ieri)
            o.id = obiettivoSofia
            o.accantonato = 120_000
            o.priorita = .alta
            o.creatoIl = calendario.date(byAdding: .month, value: -66, to: ieri) ?? ieri
            o.raggiuntoIl = ieri
            o.note = "Sogna di portare i nipoti a Vienna: una guida della città sarebbe il regalo giusto."
            d.obiettivi.append(o)
        }
        if d.clienti.contains(where: { $0.id == "giulia" }), !d.appuntamenti.contains(where: { $0.id == primoIncontroGiulia }) {
            let unAnno = calendario.date(byAdding: .year, value: -1, to: inizio) ?? inizio
            let giorno = calendario.date(byAdding: .day, value: -2, to: unAnno) ?? unAnno
            let quando = calendario.date(bySettingHour: 17, minute: 0, second: 0, of: giorno) ?? giorno
            d.appuntamenti.append(Appuntamento(id: primoIncontroGiulia, clienteId: "giulia", titolo: "Il nostro primo incontro",
                                               inizio: quando, durataMinuti: 60, luogo: "", note: "Dati di prova.",
                                               stato: .concluso, tipo: .primoIncontro))
        }
    }
}
