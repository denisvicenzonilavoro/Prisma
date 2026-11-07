import Foundation

// MARK: - Lo stato del lavoro (i tre anelli della scrivania, tema Apple §3.6)
// Nel template i tre anelli del riquadro «Portafoglio clienti» sono «Clienti in regola», «Riesami dell'anno» e
// «Proposte concluse» (32/35, 26/35, 9/15). Qui si contano dai dati di Prisma, senza cifre inventate:
// - in regola: i clienti senza scadenze di conformità da sistemare (MotoreConformita, `EsitoConformita.inRegola`);
// - riesami dell'anno: fra i clienti con posizioni in essere, quelli visti negli ultimi 12 mesi
//   (`MotoreRiesame.mesiRiesame`: un appuntamento passato o un incontro, come il calendario dei riesami);
// - proposte concluse: fra le proposte presentate (non le bozze), quelle con un esito finale, accettate o
//   rifiutate (come gli esiti del Portafoglio, `MotorePortafoglio`: una proposta attivata resta «accettata»).
// Motore puro: riceve `oggi` e la conformità già calcolata (la Shell la tiene in cache, `conformitaClienti`).

/// I tre conteggi degli anelli.
struct StatoDelLavoro: Equatable {
    /// Un anello: quanti sono a posto su quanti contano.
    struct Conteggio: Equatable {
        let fatti: Int
        let totale: Int

        /// 0…1 (0 se non conta nessuno).
        var frazione: Double { totale > 0 ? min(max(Double(fatti) / Double(totale), 0), 1) : 0 }
    }

    let inRegola: Conteggio
    let riesami: Conteggio
    let proposte: Conteggio

    /// Non c'è niente da contare (nessun cliente): la scrivania non mostra gli anelli.
    var vuoto: Bool { inRegola.totale == 0 && riesami.totale == 0 && proposte.totale == 0 }
}

enum MotoreStatoDelLavoro {
    /// I tre anelli dei clienti dati. `conformita`: gli esiti di `MotoreConformita.calcola(clienti:…)` per gli stessi
    /// clienti (un cliente senza esito conta come in regola: non ha niente da sistemare che Prisma sappia).
    static func calcola(clienti: [Cliente], posizioni: [Posizione], appuntamenti: [Appuntamento], incontri: [Incontro],
                        conformita: [EsitoConformita], oggi: Date) -> StatoDelLavoro {
        let ids = Set(clienti.map(\.id))

        // Clienti in regola
        let daSistemare = Set(conformita.filter { !$0.inRegola }.map(\.cliente.id)).intersection(ids)
        let inRegola = StatoDelLavoro.Conteggio(fatti: ids.count - daSistemare.count, totale: ids.count)

        // Riesami dell'anno: i clienti con posizioni in essere visti negli ultimi 12 mesi
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let unAnnoFa = cal.date(byAdding: .month, value: -MotoreRiesame.mesiRiesame, to: inizio) ?? inizio
        let conPosizioni = Set(posizioni.filter { $0.stato == .inEssere }.map(\.clienteId)).intersection(ids)
        var visti = Set<String>()
        for a in appuntamenti where a.inizio < oggi && a.inizio >= unAnnoFa && conPosizioni.contains(a.clienteId) {
            visti.insert(a.clienteId)
        }
        for i in incontri where i.data < oggi && i.data >= unAnnoFa && conPosizioni.contains(i.clienteId) {
            visti.insert(i.clienteId)
        }
        let riesami = StatoDelLavoro.Conteggio(fatti: visti.count, totale: conPosizioni.count)

        // Proposte concluse: come gli esiti del Portafoglio, una proposta attivata (in essere) resta accettata
        let proposte = posizioni.filter { p in
            ids.contains(p.clienteId) && (p.stato == .proposta || p.esito == .accettata)
        }
        let presentate = proposte.filter { p in
            guard let e = p.esito else { return false }
            return e != .bozza
        }
        let concluse = presentate.filter { $0.esito == .accettata || $0.esito == .rifiutata }
        let conteggioProposte = StatoDelLavoro.Conteggio(fatti: concluse.count, totale: presentate.count)

        return StatoDelLavoro(inRegola: inRegola, riesami: riesami, proposte: conteggioProposte)
    }
}

/// Prove dello stato del lavoro (chiamate da `ProvaCalcoli.esegui()`): i tre conteggi su casi costruiti a mano.
enum ProvaStatoDelLavoro {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 3)
        func cliente(_ id: String) -> Cliente {
            Cliente(id: id, nome: id.capitalized, iniziali: String(id.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                    telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        }
        func posizione(_ cliente: String, _ stato: StatoPosizione, esito: EsitoProposta? = nil) -> Posizione {
            var p = AiutiProva.posizione("Prova", .investimento, 10_000)
            p.clienteId = cliente
            p.stato = stato
            p.esito = esito
            return p
        }
        let clienti = ["anna", "bruno", "carla"].map(cliente)

        // Vuoto: niente da contare
        let vuoto = MotoreStatoDelLavoro.calcola(clienti: [], posizioni: [], appuntamenti: [], incontri: [], conformita: [], oggi: oggi)
        verifica.vero("Stato del lavoro: senza clienti è vuoto", vuoto.vuoto && vuoto.inRegola.frazione == 0)

        // Riesami: Anna vista 3 mesi fa (appuntamento), Bruno 14 mesi fa (incontro), Carla senza posizioni in essere
        let posizioni = [
            posizione("anna", .inEssere), posizione("bruno", .inEssere),
            posizione("carla", .proposta, esito: .bozza),
            posizione("anna", .proposta, esito: .presentata),
            posizione("bruno", .proposta, esito: .rifiutata),
            posizione("bruno", .inEssere, esito: .accettata),
            posizione("anna", .proposta, esito: .rimandata),
        ]
        let appuntamenti = [
            Appuntamento(id: "a1", clienteId: "anna", titolo: "Riesame", inizio: AiutiProva.data(2026, 8, 3), durataMinuti: 60,
                         luogo: "", note: "", stato: .concluso),
            // Nel futuro: non è un riesame fatto
            Appuntamento(id: "a2", clienteId: "bruno", titolo: "Riesame", inizio: AiutiProva.data(2026, 12, 3), durataMinuti: 60,
                         luogo: "", note: "", stato: .pianificato),
        ]
        let incontri = [Incontro(clienteId: "bruno", titolo: "Vecchio incontro", data: AiutiProva.data(2025, 9, 3))]
        let s = MotoreStatoDelLavoro.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: incontri,
                                             conformita: [], oggi: oggi)
        verifica("Stato del lavoro: riesami fatti", Double(s.riesami.fatti), 1)
        verifica("Stato del lavoro: clienti con posizioni in essere", Double(s.riesami.totale), 2)
        // Presentate: presentata, rifiutata, accettata (attivata), rimandata = 4; concluse: rifiutata e accettata = 2
        verifica("Stato del lavoro: proposte presentate (senza le bozze)", Double(s.proposte.totale), 4)
        verifica("Stato del lavoro: proposte concluse", Double(s.proposte.fatti), 2)
        verifica("Stato del lavoro: frazione delle proposte", s.proposte.frazione, 0.5)
        // Senza esiti di conformità tutti in regola
        verifica("Stato del lavoro: in regola senza esiti", Double(s.inRegola.fatti), 3)
        verifica("Stato del lavoro: clienti contati", Double(s.inRegola.totale), 3)
    }
}
