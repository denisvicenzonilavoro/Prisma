import Foundation

/// I documenti fac-simile della fase 3 di Vera, per le prove e le istantanee (scelta dell'utente: fac-simile, segnati
/// come tali): le condizioni di una polizza «Infortuni famiglia» con gli articoli del template e una proposta della
/// stessa copertura, migliorata. Nessun prodotto reale, nessuna compagnia reale.
enum FacSimiliVera {
    static let avvertenza = "FAC-SIMILE scritto per le prove di Prisma. Nessun prodotto reale."

    /// Le condizioni della polizza attuale (due pagine).
    static let polizza: [String] = [
        """
        CONDIZIONI DI ASSICURAZIONE · INFORTUNI FAMIGLIA
        \(avvertenza)
        Art. 1.2 – Oggetto
        La Società indennizza le conseguenze dirette ed esclusive degli infortuni. Le malattie sono escluse.
        Art. 3.1 – Rischi esclusi
        Sono esclusi gli infortuni derivanti dalla pratica di sport a livello agonistico.
        Art. 3.2 – Guida
        Sono esclusi gli infortuni subiti alla guida senza patente o in stato di ebbrezza.
        Art. 4.1 – Decorrenza
        La garanzia decorre dopo 180 giorni dalla data di sottoscrizione.
        """,
        """
        Art. 6.1 – Franchigia
        Per l'invalidità permanente non si fa luogo a indennizzo fino al 3%; oltre, si indennizza la parte eccedente.
        Art. 6.2 – Diaria da ricovero
        La diaria da ricovero è corrisposta dal terzo giorno di ricovero.
        Art. 7.1 – Somme assicurate
        Il massimale per il caso morte è di 100.000 €.
        Art. 7.3 – Spese mediche
        Le spese mediche sono rimborsate fino a 5.000 € per sinistro.
        """,
    ]

    /// La proposta (una pagina): carenza più corta, massimale più alto, sport agonistici non più esclusi.
    static let proposta: [String] = [
        """
        PROPOSTA · INFORTUNI FAMIGLIA PIÙ
        \(avvertenza)
        Art. 1.2 – Oggetto
        La Società indennizza le conseguenze dirette ed esclusive degli infortuni. Le malattie sono escluse.
        Art. 3.2 – Guida
        Sono esclusi gli infortuni subiti alla guida senza patente o in stato di ebbrezza.
        Art. 4.1 – Decorrenza
        La garanzia decorre dopo 90 giorni dalla data di sottoscrizione.
        Art. 6.1 – Franchigia
        Per l'invalidità permanente non si fa luogo a indennizzo fino al 3%; oltre, si indennizza la parte eccedente.
        Art. 7.1 – Somme assicurate
        Il massimale per il caso morte è di 250.000 €.
        """,
    ]

    /// I due documenti di un cliente, con i dati letti (come li avrebbe letti l'estrattore).
    static func documenti(cliente: String, oggi: Date = Date()) -> (polizza: Documento, proposta: Documento) {
        var a = Documento(clienteId: cliente, titolo: "Infortuni famiglia (fac-simile)", tipo: .polizza)
        a.id = "doc-facsimile-polizza-\(cliente)"
        a.importatoIl = oggi.addingTimeInterval(-86_400 * 30)
        a.pagine = polizza.count
        a.campi = [CampoEstratto(chiave: .capitaleAssicurato, valore: "100.000 €", pagina: 2),
                   CampoEstratto(chiave: .premio, valore: "420 €", pagina: 1),
                   CampoEstratto(chiave: .emittente, valore: "Compagnia fac-simile", pagina: 1)]
        var b = Documento(clienteId: cliente, titolo: "Infortuni famiglia più (proposta, fac-simile)", tipo: .proposta)
        b.id = "doc-facsimile-proposta-\(cliente)"
        b.importatoIl = oggi
        b.pagine = proposta.count
        b.campi = [CampoEstratto(chiave: .capitaleAssicurato, valore: "250.000 €", pagina: 1),
                   CampoEstratto(chiave: .premio, valore: "610 €", pagina: 1),
                   CampoEstratto(chiave: .emittente, valore: "Compagnia fac-simile", pagina: 1)]
        return (a, b)
    }
}
