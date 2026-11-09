import Foundation

/// DATI DI PROVA del Territorio («Luce» giro 11): un giro a Bologna con tre clienti di prova messi a mano (Laura, Andrea
/// e, fra le due, Sofia), la partenza dello studio (solo istantanee e prove) e un'attività di prova per il suggerimento
/// «Lungo la strada». Caricati anche da Impostazioni › Dati di prova (§0.7) e tolti con `rimuoviDatiDiProva`. Mai in
/// `DatiPrisma.demo()` (prove e istantanee esistenti invariate). Coordinate inventate, vicino al centro della tabella di
/// prova di Bologna.
enum TerritorioDiProva {
    static let prefisso = "prova-giro-"
    static let nota = "dati di prova"

    /// La partenza di prova (centro di Bologna, approssimato a mano).
    static let partenza = Coordinata(lat: 44.494, lon: 11.343)
    /// Le posizioni a mano dei tre clienti del giro: Laura a nord-ovest, Andrea a sud-est, Sofia fra le due.
    static let posizioni: [String: Coordinata] = [
        "laura": Coordinata(lat: 44.515, lon: 11.300),
        "andrea": Coordinata(lat: 44.470, lon: 11.395),
        "sofia": Coordinata(lat: 44.493, lon: 11.349),
    ]

    /// Il giorno del giro di prova: domani se è un giorno di lavoro (`orari.giorni`), altrimenti il primo giorno di lavoro
    /// dopo (così istantanee e prove non dipendono dal giorno della settimana in cui girano).
    static func giorno(da oggi: Date, orari: OrariLavoro, calendario: Calendar = .current) -> Date {
        let domani = calendario.date(byAdding: .day, value: 1, to: calendario.startOfDay(for: oggi)) ?? oggi
        return MotoreTerritorio.giornoLavorativo(da: domani, orari: orari, calendario: calendario)
    }

    /// Mette i dati di prova del giro in `d`. `conPartenza`: anche la partenza di prova in Impostazioni › Territorio (solo
    /// istantanee e prove: `ripristinaDatiDiProva` conserva le impostazioni dell'utente). Gli altri appuntamenti di prova
    /// che si accavallano con la mattina del giro si spostano di una settimana, perché il giro si legga.
    static func applica(_ d: inout DatiPrisma, giorno: Date, conPartenza: Bool, calendario: Calendar = .current) {
        let inizio = calendario.startOfDay(for: giorno)
        func ora(_ h: Int, _ m: Int) -> Date { calendario.date(bySettingHour: h, minute: m, second: 0, of: inizio) ?? inizio }
        if conPartenza {
            d.impostazioni.territorio.partenza = LuogoManuale(coordinata: partenza, nota: nota)
        }
        for (id, c) in posizioni {
            if let i = d.clienti.firstIndex(where: { $0.id == id }) {
                d.clienti[i].luogo = LuogoManuale(coordinata: c, nota: nota)
            }
        }
        // La mattina del giro libera dagli altri appuntamenti di prova
        let mattina = (ora(9, 0), ora(14, 0))
        for i in d.appuntamenti.indices where !d.appuntamenti[i].id.hasPrefix(prefisso) {
            let a = d.appuntamenti[i]
            if a.inizio < mattina.1 && a.fine > mattina.0 {
                d.appuntamenti[i].inizio = calendario.date(byAdding: .day, value: 7, to: a.inizio) ?? a.inizio
            }
        }
        d.appuntamenti.removeAll { $0.id.hasPrefix(prefisso) }
        d.attivita.removeAll { $0.id.hasPrefix(prefisso) }
        let clienti = Set(d.clienti.map(\.id))
        if clienti.contains("laura") {
            d.appuntamenti.append(Appuntamento(id: prefisso + "laura", clienteId: "laura", titolo: "Il progetto professionale (dati di prova)",
                                               inizio: ora(10, 0), durataMinuti: 60, luogo: "", note: nota, stato: .pianificato,
                                               tipo: .analisi, presso: .cliente))
        }
        if clienti.contains("andrea") {
            d.appuntamenti.append(Appuntamento(id: prefisso + "andrea", clienteId: "andrea", titolo: "Le priorità della famiglia (dati di prova)",
                                               inizio: ora(12, 30), durataMinuti: 60, luogo: "", note: nota, stato: .pianificato,
                                               tipo: .analisi, presso: .cliente))
        }
        if clienti.contains("sofia") {
            d.attivita.append(Attivita(id: prefisso + "sofia", clienteId: "sofia", titolo: "Consenso privacy da rinnovare (dati di prova)",
                                       scadenza: inizio, priorita: .alta, completata: false, note: nota))
        }
    }

    /// Toglie i dati di prova del giro (appuntamenti e attività con il prefisso, posizioni a mano e partenza con la nota).
    static func togli(_ d: inout DatiPrisma) {
        d.appuntamenti.removeAll { $0.id.hasPrefix(prefisso) }
        d.attivita.removeAll { $0.id.hasPrefix(prefisso) }
        for i in d.clienti.indices where d.clienti[i].luogo?.nota == nota { d.clienti[i].luogo = nil }
        if d.impostazioni.territorio.partenza?.nota == nota { d.impostazioni.territorio.partenza = nil }
    }
}
