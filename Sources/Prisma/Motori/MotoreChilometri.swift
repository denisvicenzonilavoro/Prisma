import Foundation

// I chilometri di Studio › Spese (Design/template-luce-specifica.md §6.3.5 punto 3, «Luce» giro 9; decisioni 22 e 100).
// Motore puro: niente servizi di percorso, niente coordinate, niente indovinelli sul testo del luogo.
//
// - Una visita è un appuntamento concluso, con un cliente (o senza, se l'utente lo chiede), che non è una telefonata né
//   un pezzo di giornata bloccato e che non si è svolto in studio (`Appuntamento.presso`).
// - Un giro è una giornata: le visite dello stesso giorno, in ordine d'orario (sede → visite → sede).
// - I km di un giro: la correzione a mano del giorno (`kmCorretti`) vince sempre; altrimenti la somma dei km di andata e
//   ritorno scritti dall'utente per ogni cliente visitato «dal cliente». Due o più visite di fila dallo stesso cliente
//   sono una sola andata e ritorno (sede → cliente → sede). Se il giro unisce più clienti la somma conta ogni andata e
//   ritorno: l'utente la corregge a mano (la tabella fra clienti non c'è, decisione 22).
// - Visite senza km: luogo non indicato («Dove eri?»), «altrove», cliente senza distanza o senza cliente. Il totale
//   del mese conta solo i km noti e lo dice («almeno …»).
// - Un cliente eliminato lascia le sue visite concluse in `ArchivioSpese.visiteTolte` (senza nome né testi, con i km di
//   allora): i km e le visite dei mesi già chiusi col commercialista non cambiano.
// - Il mese mostrato: fino al giorno di cambio (10 di base) il mese prima, quello da chiudere col commercialista.

enum MotoreChilometri {
    /// Perché una visita non ha i km.
    enum MotivoSenzaKm: Equatable {
        /// Il luogo dell'incontro non è indicato: «Dove eri?».
        case luogoMancante
        /// Il cliente non ha i km di andata e ritorno scritti.
        case distanzaMancante
        /// Fatta altrove: la tabella dei clienti non vale.
        case altrove
        /// Un appuntamento senza cliente.
        case senzaCliente
        /// Una visita di un cliente poi eliminato, che non aveva i km: si corregge il giro a mano.
        case clienteEliminato
    }

    /// Da dove vengono i km di una visita o di un giro.
    enum Origine: Equatable {
        /// Dalla tabella andata e ritorno per cliente.
        case tabella
        /// Dalla correzione a mano del giorno.
        case manuale
    }

    /// Una visita con i suoi km (calcolata, mai salvata).
    struct Visita: Identifiable, Equatable {
        var id: String { appuntamentoId }
        let appuntamentoId: String
        let clienteId: String
        let inizio: Date
        let presso: LuogoIncontro?
        /// I km di andata e ritorno dalla tabella (nil se mancano o non valgono).
        let km: Double?
        let motivo: MotivoSenzaKm?
        /// La sigla di una visita di un cliente eliminato (`ArchivioSpese.visiteTolte`, `clienteId` vuoto): niente nome
        /// né appuntamento da cambiare.
        var gruppoTolto: String? = nil
        var tolta: Bool { gruppoTolto != nil }
        /// Chi si è visitato: il cliente, o la sigla delle visite tolte (per «di fila dallo stesso cliente» e i clienti).
        var gruppo: String { gruppoTolto.map { "tolta:" + $0 } ?? clienteId }
    }

    /// Una giornata di visite.
    struct Giro: Identifiable, Equatable {
        var id: String { chiave }
        /// «2026-10-03» (la chiave delle correzioni).
        let chiave: String
        let giorno: Date
        let visite: [Visita]
        /// I km del giro: la correzione, o la somma della tabella se tutte le visite l'hanno (nil = da completare).
        let km: Double?
        /// La parte nota dei km (per «almeno …»).
        let kmNoti: Double
        let origine: Origine?
        /// Visite senza km in un giro non corretto a mano.
        var senzaKm: Int { origine == .manuale ? 0 : visite.filter { $0.km == nil }.count }
        var corretto: Bool { origine == .manuale }
    }

    /// I km noti di un giro: una visita di fila dallo stesso cliente della precedente (con i suoi km) non aggiunge un'altra
    /// andata e ritorno, perché non si è tornati in sede fra le due.
    static func kmContati(_ visite: [Visita]) -> Double {
        var totale = 0.0
        for (i, v) in visite.enumerated() {
            guard let km = v.km else { continue }
            if i > 0, !v.gruppo.isEmpty, visite[i - 1].gruppo == v.gruppo, visite[i - 1].km != nil { continue }
            totale += km
        }
        return totale
    }

    /// I km di un mese (per la colonna del grafico).
    struct Mese: Identifiable, Equatable {
        var id: Date { inizio }
        let inizio: Date
        let km: Double
    }

    /// Il riepilogo di un mese.
    struct Riepilogo: Equatable {
        let mese: Date
        let giri: [Giro]
        /// I km noti del mese.
        let totale: Double
        let visite: Int
        let clienti: Int
        /// Visite senza km nei giri non corretti.
        let senzaKm: Int
        /// Visite senza luogo indicato (fra quelle senza km).
        let senzaLuogo: Int
        /// Gli ultimi mesi fino a quello mostrato (il più vecchio prima).
        let serie: [Mese]

        var completo: Bool { senzaKm == 0 }
        var vuoto: Bool { giri.isEmpty }
    }

    /// Quanti mesi ha la serie del grafico «Chilometri per mese» (10 colonne come nel template).
    static let mesiSerie = 10

    // MARK: Il mese mostrato

    /// Il primo giorno del mese mostrato da Studio › Spese: fino al giorno di cambio il mese prima, poi quello in corso.
    static func meseMostrato(oggi: Date, giornoCambio: Int = ImpostazioniSpese.giornoCambioPredefinito,
                             calendario cal: Calendar = .current) -> Date {
        let inizio = inizioMese(oggi, cal)
        guard cal.component(.day, from: oggi) <= giornoCambio else { return inizio }
        return cal.date(byAdding: .month, value: -1, to: inizio) ?? inizio
    }

    /// Un numero di km al decimo («41,5»).
    static func decimo(_ v: Double) -> Double { (v * 10).rounded() / 10 }

    /// Il valore in euro dei km di un giro, al centesimo, con il valore per km scritto dall'utente (lo stesso nel CSV e nel
    /// PDF del pacchetto, che ne fa la somma).
    static func euro(_ km: Double, perKm: Double) -> Double { (km * perKm * 100).rounded() / 100 }

    static func inizioMese(_ d: Date, _ cal: Calendar = .current) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: d)) ?? cal.startOfDay(for: d)
    }

    // MARK: Le visite

    /// Vero se l'appuntamento è una visita per i chilometri (prima di guardare il mese).
    static func eVisita(_ a: Appuntamento, contaSenzaCliente: Bool) -> Bool {
        guard a.stato == .concluso, a.tipo != .telefonata, a.tipo != .nonDisponibile, a.presso != .studio else { return false }
        return !a.clienteId.isEmpty || contaSenzaCliente
    }

    /// Una visita con i suoi km secondo la tabella dell'utente.
    static func visita(_ a: Appuntamento, kmClienti: [String: Double]) -> Visita {
        let km: Double?
        let motivo: MotivoSenzaKm?
        if a.clienteId.isEmpty {
            (km, motivo) = (nil, .senzaCliente)
        } else {
            switch a.presso {
            case nil:
                (km, motivo) = (nil, .luogoMancante)
            case .altro:
                (km, motivo) = (nil, .altrove)
            case .cliente, .studio:
                if let v = kmClienti[a.clienteId] {
                    (km, motivo) = (v, nil)
                } else {
                    (km, motivo) = (nil, .distanzaMancante)
                }
            }
        }
        return Visita(appuntamentoId: a.id, clienteId: a.clienteId, inizio: a.inizio, presso: a.presso, km: km, motivo: motivo)
    }

    /// Una visita di un cliente eliminato, con i km che valevano quel giorno.
    static func visita(_ t: VisitaTolta) -> Visita {
        Visita(appuntamentoId: t.id, clienteId: "", inizio: t.inizio, presso: t.presso, km: t.km,
               motivo: t.km == nil ? .clienteEliminato : nil, gruppoTolto: t.gruppo)
    }

    /// Le visite concluse di un cliente che si sta eliminando, da tenere per i chilometri (senza nome, titolo, luogo né
    /// note): i km di allora dalla tabella, una sigla a caso uguale per tutte.
    static func visiteDaTenere(clienteId: String, appuntamenti: [Appuntamento], kmClienti: [String: Double]) -> [VisitaTolta] {
        guard !clienteId.isEmpty else { return [] }
        let gruppo = String(UUID().uuidString.prefix(8)).lowercased()
        return appuntamenti.filter { $0.clienteId == clienteId && eVisita($0, contaSenzaCliente: false) }.map { a in
            VisitaTolta(id: a.id, inizio: a.inizio, presso: a.presso, km: visita(a, kmClienti: kmClienti).km, gruppo: gruppo)
        }
    }

    /// I giri del mese che comincia in `mese`, in ordine di data.
    /// `visiteTolte`: le visite concluse dei clienti poi eliminati (i km dei mesi chiusi non cambiano).
    static func giri(mese: Date, appuntamenti: [Appuntamento], impostazioni: ImpostazioniSpese, kmClienti: [String: Double],
                     visiteTolte: [VisitaTolta] = [], calendario cal: Calendar = .current) -> [Giro] {
        let inizio = inizioMese(mese, cal)
        guard let fine = cal.date(byAdding: .month, value: 1, to: inizio) else { return [] }
        let delMese = appuntamenti.filter {
            $0.inizio >= inizio && $0.inizio < fine && eVisita($0, contaSenzaCliente: impostazioni.contaVisiteSenzaCliente)
        }.map { visita($0, kmClienti: kmClienti) }
            + visiteTolte.filter { $0.inizio >= inizio && $0.inizio < fine }.map(visita)
        let perGiorno = Dictionary(grouping: delMese) { cal.startOfDay(for: $0.inizio) }
        return perGiorno.keys.sorted().map { giorno in
            let visite = (perGiorno[giorno] ?? []).sorted { ($0.inizio, $0.id) < ($1.inizio, $1.id) }
            let chiave = ImpostazioniSpese.chiaveGiorno(giorno, calendario: cal)
            // Al decimo di km, come si scrivono: i giri, il totale, il PDF e il CSV del pacchetto tornano fra loro
            let noti = decimo(kmContati(visite))
            if let corretti = impostazioni.kmCorretti[chiave].map(decimo) {
                return Giro(chiave: chiave, giorno: giorno, visite: visite, km: corretti, kmNoti: corretti, origine: .manuale)
            }
            let completo = visite.allSatisfy { $0.km != nil }
            return Giro(chiave: chiave, giorno: giorno, visite: visite, km: completo ? noti : nil, kmNoti: noti,
                        origine: noti > 0 || completo ? .tabella : nil)
        }
    }

    /// Il riepilogo del mese: giri, totale dei km noti, visite, clienti, visite senza km e la serie dei mesi.
    static func riepilogo(mese: Date, appuntamenti: [Appuntamento], impostazioni: ImpostazioniSpese,
                          kmClienti: [String: Double], visiteTolte: [VisitaTolta] = [],
                          calendario cal: Calendar = .current) -> Riepilogo {
        let inizio = inizioMese(mese, cal)
        let g = giri(mese: inizio, appuntamenti: appuntamenti, impostazioni: impostazioni, kmClienti: kmClienti,
                     visiteTolte: visiteTolte, calendario: cal)
        let visite = g.flatMap(\.visite)
        let serie: [Mese] = (0..<mesiSerie).reversed().compactMap { indietro in
            guard let m = cal.date(byAdding: .month, value: -indietro, to: inizio) else { return nil }
            let km = indietro == 0 ? g.map(\.kmNoti).reduce(0, +)
                : giri(mese: m, appuntamenti: appuntamenti, impostazioni: impostazioni, kmClienti: kmClienti,
                       visiteTolte: visiteTolte, calendario: cal).map(\.kmNoti).reduce(0, +)
            return Mese(inizio: m, km: km)
        }
        return Riepilogo(mese: inizio, giri: g, totale: decimo(g.map(\.kmNoti).reduce(0, +)), visite: visite.count,
                         clienti: Set(visite.map(\.gruppo).filter { !$0.isEmpty }).count,
                         senzaKm: g.map(\.senzaKm).reduce(0, +),
                         senzaLuogo: g.filter { !$0.corretto }.flatMap(\.visite).filter { $0.motivo == .luogoMancante }.count,
                         serie: serie)
    }
}
