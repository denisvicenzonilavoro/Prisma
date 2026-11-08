import Foundation

// DATI DI PROVA DICHIARATI di Studio › Spese («Luce» giro 9): le cinque spese del template nel mese che Studio mostra
// (descrizioni e importi dimostrativi, nessuno scontrino vero), due corsi di aggiornamento e tre scadenze NON fiscali
// (decisione 66: nessuna data di F24, acconti o altre scadenze fiscali nei dati di prova). Ogni voce porta «dati di
// prova» nella nota e un id che comincia con «prova-», così «Togli i clienti di prova» le toglie.
// Le visite con i chilometri e le ore richieste dell'anno NON sono qui: compaiono solo nelle istantanee (IstantaneeSpese).

enum SpeseDiProva {
    static let prefisso = "prova-"
    static let nota = "dati di prova"

    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {
        d.speseStudio = archivio(oggi: oggi)
    }

    static func archivio(oggi: Date = Date(), calendario cal: Calendar = .current) -> ArchivioSpese {
        let mese = MotoreChilometri.meseMostrato(oggi: oggi, calendario: cal)
        func giorno(_ g: Int) -> Date {
            var c = cal.dateComponents([.year, .month], from: mese)
            (c.day, c.hour) = (g, 12)
            return cal.date(from: c) ?? mese
        }
        let spese = [
            SpesaStudio(id: prefisso + "spesa-carburante", data: giorno(2), descrizione: "Carburante", importo: 92.40,
                        categoria: .carburante, nota: nota),
            SpesaStudio(id: prefisso + "spesa-pranzo", data: giorno(8), descrizione: "Pranzo con cliente", importo: 48.00,
                        categoria: .pasti, nota: nota),
            SpesaStudio(id: prefisso + "spesa-parcheggio", data: giorno(14), descrizione: "Parcheggio", importo: 6.50,
                        categoria: .parcheggio, nota: nota),
            SpesaStudio(id: prefisso + "spesa-cancelleria", data: giorno(17), descrizione: "Cancelleria", importo: 31.90,
                        categoria: .cancelleria, nota: nota),
            SpesaStudio(id: prefisso + "spesa-corso", data: giorno(24), descrizione: "Corso di aggiornamento", importo: 180.00,
                        categoria: .formazione, canale: .indipendente, nota: nota),
        ]
        // I corsi nell'anno di oggi, mai dopo oggi
        let anno = cal.dateComponents([.year], from: oggi)
        func nellAnno(_ mese: Int, _ g: Int) -> Date {
            var c = anno
            (c.month, c.day, c.hour) = (mese, g, 9)
            return min(cal.date(from: c) ?? oggi, oggi)
        }
        let corsi = [
            CorsoAggiornamento(id: prefisso + "corso-1", titolo: "Corso di prova · prodotti assicurativi", ente: "Ente di prova",
                               data: nellAnno(3, 12), ore: 14, canale: .alleanza),
            CorsoAggiornamento(id: prefisso + "corso-2", titolo: "Seminario di prova · consulenza", ente: "Ente di prova",
                               data: nellAnno(6, 20), ore: 8, canale: .indipendente),
        ]
        let inizio = cal.startOfDay(for: oggi)
        func traGiorni(_ n: Int) -> Date { cal.date(byAdding: .hour, value: 9, to: cal.date(byAdding: .day, value: n, to: inizio) ?? inizio) ?? inizio }
        let scadenze = [
            ScadenzaStudio(id: prefisso + "scadenza-commercialista", titolo: "Incontro con il commercialista", data: traGiorni(12),
                           tipo: .altra, nota: nota),
            ScadenzaStudio(id: prefisso + "scadenza-rc", titolo: "Polizza RC professionale", data: traGiorni(40), ricorrenza: .annuale,
                           tipo: .polizza, nota: "rinnovo da confermare · \(nota)"),
            ScadenzaStudio(id: prefisso + "scadenza-aggiornamento", titolo: "Aggiornamento professionale", data: traGiorni(53),
                           tipo: .aggiornamento, nota: nota),
        ]
        return ArchivioSpese(spese: spese, scadenze: scadenze, corsi: corsi)
    }

    /// Toglie le voci di prova (id con «prova-»), lasciando quelle dell'utente.
    static func togli(_ a: inout ArchivioSpese) {
        a.spese.removeAll { $0.id.hasPrefix(prefisso) }
        a.scadenze.removeAll { $0.id.hasPrefix(prefisso) }
        a.corsi.removeAll { $0.id.hasPrefix(prefisso) }
    }
}
