import Foundation

// I dati di prova della linea della vita (Orizzonte, giro 4; specifica §7.6): gli eventi del template per i cinque
// clienti di prova, con importo e durata, e il risparmio libero del profilo, così la scheda si vede piena. Gli anni
// sono contati da oggi (come le scadenze degli obiettivi di prova): la casa di Giulia cade nell'anno dell'obiettivo
// «Anticipo per la casa» e l'università di Anna in quello dell'obiettivo di Marco, quindi l'obiettivo e l'evento
// contano una volta sola. Importi del template (dimostrativi), in euro di oggi.

extension DatiDemo {
    static func eventiVita(oggi: Date = Date()) -> [EventoLineaVita] {
        let anno = Calendar(identifier: .gregorian).component(.year, from: oggi)
        func evento(_ id: String, _ cliente: String, _ tipo: EventoLineaVita.Tipo, traAnni: Int, importo: Double,
                    perAnni: Int? = nil, titolo: String? = nil) -> EventoLineaVita {
            var e = EventoLineaVita(clienteId: cliente, tipo: tipo, anno: anno + traAnni, importo: importo,
                                    durataAnni: perAnni, titolo: titolo)
            e.id = id
            return e
        }
        return [
            evento("vita-giulia-matrimonio", "giulia", .matrimonio, traAnni: 1, importo: -15_000),
            evento("vita-giulia-casa", "giulia", .casa, traAnni: 3, importo: -40_000),
            evento("vita-giulia-figlio", "giulia", .figlio, traAnni: 4, importo: -4_000, perAnni: 22, titolo: "Un figlio"),
            evento("vita-giulia-eredita", "giulia", .eredita, traAnni: 25, importo: 80_000),
            evento("vita-marco-studi", "marco", .studi, traAnni: 5, importo: -9_000, perAnni: 5, titolo: "Università di Anna"),
            evento("vita-marco-casa", "marco", .casa, traAnni: 12, importo: -150_000, titolo: "Casa al mare"),
            evento("vita-laura-sabbatico", "laura", .annoSabbatico, traAnni: 2, importo: -30_000),
            evento("vita-andrea-casa", "andrea", .casa, traAnni: 4, importo: -35_000),
            evento("vita-sofia-nipoti", "sofia", .altro, traAnni: 5, importo: -30_000, titolo: "Un aiuto ai nipoti"),
        ]
    }

    /// Il risparmio annuo libero dei clienti di prova, oltre ai versamenti delle posizioni.
    static let risparmiLiberi: [String: Double] = [
        "giulia": 4_800, "marco": 9_000, "laura": 10_000, "andrea": 3_000, "sofia": 2_000,
    ]

    /// Mette il risparmio libero nel profilo dei clienti di prova.
    static func aggiungiRisparmiLiberi(_ clienti: inout [Cliente]) {
        for i in clienti.indices {
            if let r = risparmiLiberi[clienti[i].id] { clienti[i].profilo.risparmioAnnuo = r }
        }
    }
}
