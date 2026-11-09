import Foundation

/// DATI DI PROVA DICHIARATI (Messaggi › Campagne, «Luce» giro 12, piano §7.1): i quattro gruppi del template
/// (Design/template-luce-specifica.md §9.4.1: «Nessuna protezione per il coniuge», «BTP in scadenza a marzo»,
/// «Compiono 50 anni nel 2027», «Fondo pensione fermo da un anno») fatti nascere dai motori veri (`MotoreCampagne`) sui
/// clienti di prova e sui clienti fittizi, solo per le istantanee 862-868. Nessuna campagna salvata, nessun dato vero:
/// si aggiungono un titolo di Stato di prova in scadenza fra quattro mesi (Sofia, Laura e tre fittizi), un compleanno
/// tondo l'anno prossimo (Laura e tre fittizi) e un fondo pensione di prova senza versamenti da quattordici mesi
/// (Giulia, Sofia, Marco e tre fittizi). Non entra mai nell'archivio di prova (`ClientiFittizi.completi()` resta com'è):
/// lo chiama solo la scena, sui dati della scena. Il pannello dice «tra i clienti di prova».
enum CampagneDiProva {
    /// Gli id delle posizioni aggiunte cominciano così (si riconoscono nelle istantanee).
    static let prefisso = "campagna-prova-"

    /// I clienti di prova e fittizi di ciascun gruppo del template (solo quelli presenti nei dati vengono toccati).
    static let scadenze = ["sofia", "laura", ClientiFittizi.prefisso + "ferraro", ClientiFittizi.prefisso + "marchetti",
                           ClientiFittizi.prefisso + "greco"]
    static let compleanni = ["laura", ClientiFittizi.prefisso + "russo", ClientiFittizi.prefisso + "ricci",
                             ClientiFittizi.prefisso + "lombardi"]
    static let fondiFermi = ["giulia", "sofia", "marco", ClientiFittizi.prefisso + "galli", ClientiFittizi.prefisso + "fontana",
                             ClientiFittizi.prefisso + "barbieri"]

    /// Applica i dati di prova dei gruppi a `d` (i dati della scena). Date relative a `oggi`, così i gruppi restano attuali.
    static func applicaScena(_ d: inout DatiPrisma, oggi: Date = Date(), cal: Calendar = Calendar(identifier: .gregorian)) {
        let inizio = cal.startOfDay(for: oggi)
        let presenti = Set(d.clienti.map(\.id))
        var nuove: [Posizione] = []

        // Il titolo di Stato di prova in scadenza il 15 del quarto mese da oggi (entro i sei mesi di RegoleCampagne)
        let fraQuattro = cal.date(byAdding: .month, value: 4, to: inizio) ?? inizio
        var giorno = cal.dateComponents([.year, .month], from: fraQuattro)
        giorno.day = 15
        giorno.hour = 12
        let scadenza = cal.date(from: giorno) ?? fraQuattro
        for (i, id) in scadenze.enumerated() where presenti.contains(id) {
            var p = Posizione(clienteId: id, canale: .indipendente, stato: .inEssere, area: .investimento,
                              nome: "BTP di prova \(i + 1)")
            p.id = prefisso + "btp-" + id
            p.controvalore = Double(20_000 + i * 5_000)
            p.scadenza = scadenza
            p.quotaTitoliStato = 1
            nuove.append(p)
        }

        // Il compleanno tondo l'anno prossimo (50 anni, come nel template); giorno e mese restano quelli della scheda
        let annoNascita = cal.component(.year, from: oggi) + 1 - 50
        for id in compleanni {
            guard let i = d.clienti.firstIndex(where: { $0.id == id }) else { continue }
            var parti = d.clienti[i].dataNascita.map { cal.dateComponents([.month, .day], from: $0) } ?? DateComponents(month: 6, day: 15)
            parti.year = annoNascita
            parti.hour = 12
            d.clienti[i].dataNascita = cal.date(from: parti)
        }

        // Il fondo pensione di prova senza versamenti da quattordici mesi (un solo versamento, poi nulla)
        let versamento = cal.date(byAdding: .month, value: -14, to: inizio) ?? inizio
        for (i, id) in fondiFermi.enumerated() where presenti.contains(id) {
            var p = Posizione(clienteId: id, canale: .indipendente, stato: .inEssere, area: .previdenza,
                              nome: "Fondo pensione di prova \(i + 1)")
            p.id = prefisso + "fondo-" + id
            p.controvalore = Double(12_000 + i * 3_000)
            p.movimenti = [Movimento(data: versamento, importo: 1_200)]
            nuove.append(p)
        }

        let gia = Set(d.posizioni.map(\.id))
        let daAggiungere = nuove.filter { !gia.contains($0.id) }
        if !daAggiungere.isEmpty { d.posizioni = d.posizioni + daAggiungere }
    }

    /// I dati di prova completi per le istantanee delle campagne: clienti fittizi più i gruppi del template.
    static func datiScena(oggi: Date = Date()) -> DatiPrisma {
        var d = ClientiFittizi.completi()
        applicaScena(&d, oggi: oggi)
        return d
    }
}
