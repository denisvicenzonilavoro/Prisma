import Foundation

/// Prove della mossa del giorno (`MotoreMossaDelGiorno`): i pesi documentati, il caso calmo con i dati vuoti,
/// i casi costruiti a mano con punteggi esatti e i 5 clienti di prova. Chiamate da `ProvaCalcoli.esegui()`:
/// gli errori si sommano. I casi a mano hanno date fisse (oggi è il 3 novembre 2026); i clienti di prova hanno
/// date relative a oggi, quindi si prova con `Date()`.
enum ProvaMossaDelGiorno {
    static func esegui(_ verifica: VerificaCalcoli) {
        pesi(verifica)
        calma(verifica)
        costruiti(verifica)
        clientiDiProva(verifica)
    }

    // MARK: - Aiuti

    private static let oggi = AiutiProva.data(2026, 11, 3)

    private static func cliente(_ id: String, _ nome: String) -> Cliente {
        Cliente(id: id, nome: nome, iniziali: String(nome.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
    }

    /// Ingressi senza occasioni né completezza: i punteggi sono esatti.
    private static func ingressi(clienti: [Cliente], posizioni: [Posizione] = [], appuntamenti: [Appuntamento] = [],
                                 proposte: [PropostaInSospeso] = [], riesami: [RiesameDovuto] = [],
                                 occasioni: [Occasione] = []) -> MotoreMossaDelGiorno.Ingressi {
        MotoreMossaDelGiorno.Ingressi(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, proposte: proposte,
                                      sogliaSeguito: Impostazioni.giorniSeguitoPredefiniti, riesami: riesami,
                                      occasioni: occasioni, completezza: { _ in nil }, oggi: oggi)
    }

    // MARK: - Pesi

    private static func pesi(_ verifica: VerificaCalcoli) {
        typealias P = PesiMossaDelGiorno
        let t = P.tabella
        verifica.vero("Mossa: tabella dei pesi non vuota", t.count >= 20)
        verifica.vero("Mossa: ogni peso ha il suo perché", t.allSatisfy { !$0.perche.isEmpty && $0.perche.count <= 120 })
        verifica.vero("Mossa: ogni peso è positivo", t.allSatisfy { $0.peso > 0 })
        verifica("Mossa: nomi dei pesi senza doppioni", Double(Set(t.map { $0.nome }).count), Double(t.count))
        verifica.vero("Mossa: la proposta ferma pesa più del riesame scaduto", P.propostaFerma > P.riesameScaduto)
        verifica.vero("Mossa: il riesame scaduto pesa più della sola scadenza", P.riesameScaduto > P.scadenza)
        verifica.vero("Mossa: un'occasione importante basta da sola", P.occasioneAlta >= P.sogliaMinima)
        verifica.vero("Mossa: un'occasione media con i dati scarsi resta sotto la soglia",
                      P.occasioneMedia + P.datiScarsi < P.sogliaMinima)
        verifica.vero("Mossa: le occasioni insieme valgono meno di una proposta ferma", P.occasioniMassimo < P.propostaFerma)
    }

    // MARK: - Il caso calmo

    private static func calma(_ verifica: VerificaCalcoli) {
        let vuoto = MotoreMossaDelGiorno.calcola(clienti: [], posizioni: [], appuntamenti: [], attivita: [], incontri: [],
                                                 prodotti: [], analisi: [:], oggi: oggi)
        if case .calma(let titolo, let frase) = vuoto {
            verifica.vero("Mossa: dati vuoti, niente di urgente", titolo == MotoreMossaDelGiorno.titoloCalma && !frase.isEmpty)
        } else {
            verifica.vero("Mossa: dati vuoti, niente di urgente", false)
        }
        // Un cliente senza posizioni né proposte: in ordine
        let solo = MotoreMossaDelGiorno.calcola(clienti: [cliente("a", "Anna Prova")], posizioni: [], appuntamenti: [],
                                                attivita: [], incontri: [], prodotti: [], analisi: [:], oggi: oggi)
        verifica.vero("Mossa: un cliente senza motivi, frase calma",
                      solo == .calma(titolo: MotoreMossaDelGiorno.titoloCalma, frase: MotoreMossaDelGiorno.fraseCalma))
        // Un'occasione media sola resta sotto la soglia
        let o = Occasione(tipo: .ricorrenzaGestione, data: AiutiProva.data(2026, 11, 20), clienteId: "a", posizioneId: nil,
                          familiareId: nil, canale: nil, titolo: "Ricorrenza annua", dettaglio: "", fonte: "", valore: nil,
                          importanza: .media, id: "prova-occasione")
        let sotto = MotoreMossaDelGiorno.scegli(ingressi(clienti: [cliente("a", "Anna Prova")], occasioni: [o]))
        verifica.vero("Mossa: un'occasione media sola non è una mossa", sotto.mossa == nil)
    }

    // MARK: - Casi costruiti a mano

    private static func costruiti(_ verifica: VerificaCalcoli) {
        let a = cliente("a", "Anna Prova")
        let b = cliente("b", "Bruno Prova")
        var pip = Posizione(id: "pip-b", clienteId: "b", canale: .alleanza, stato: .proposta, area: .previdenza, nome: "PIP")
        pip.esito = .presentata
        // Ferma da 30 giorni con la soglia di 21: 40 + 9 = 49 punti
        let ferma = PropostaInSospeso(posizione: pip, cliente: b, motivo: .senzaRisposta, dal: AiutiProva.data(2026, 10, 4),
                                      fonte: .presentazione, giorni: 30, urgente: false)
        // Riesame scaduto da 2 mesi: 30 + 2 × 2 = 34 punti
        let riesameA = RiesameDovuto(cliente: a, ultimoContatto: AiutiProva.data(2025, 9, 3), dovutoDal: AiutiProva.data(2026, 9, 3))
        let due = MotoreMossaDelGiorno.scegli(ingressi(clienti: [a, b], posizioni: [pip], proposte: [ferma], riesami: [riesameA]))
        verifica.vero("Mossa: la proposta ferma batte il riesame scaduto", due.mossa?.cliente.id == "b")
        verifica("Mossa: punteggio della proposta ferma da 30 giorni", Double(due.mossa?.punteggio ?? -1), 49)
        verifica.vero("Mossa: il canale della proposta (Alleanza)", due.mossa?.canale == .alleanza)
        verifica.vero("Mossa: senza appuntamento, bozza di presentazione della proposta",
                      due.mossa?.appuntamentoInAgenda == false && due.mossa?.appuntamento.tipo == .proposta)
        verifica.vero("Mossa: report della proposta di previdenza (come il fascicolo dell'Agenda)",
                      due.mossa?.report == Set<TipoProspetto>([.resoconto, .patrimonio, .costi, .previdenza]))
        verifica.vero("Mossa: titolo «Chiama»", due.mossa?.titolo(oggi: oggi) == "Chiama Bruno Prova")

        // Stesso cliente con proposta e riesame: 49 + 34 + 10 (due motivi) e la frase con tutti e due
        let riesameB = RiesameDovuto(cliente: b, ultimoContatto: AiutiProva.data(2025, 9, 3), dovutoDal: AiutiProva.data(2026, 9, 3))
        let insieme = MotoreMossaDelGiorno.scegli(ingressi(clienti: [a, b], posizioni: [pip], proposte: [ferma], riesami: [riesameB]))
        verifica("Mossa: proposta e riesame sullo stesso cliente", Double(insieme.mossa?.punteggio ?? -1), 93)
        verifica.vero("Mossa: il motivo in una frase con il dato concreto",
                      insieme.mossa?.motivo == "La proposta «PIP» è ferma da 30 giorni e il riesame annuale è scaduto da 2 mesi.")

        // Una scadenza fra 10 giorni di 50.000 €: 20 + 22 (vicinanza) + 10 (valore) = 52; già in agenda si dimezza
        var polizza = Posizione(id: "pol-a", clienteId: "a", canale: .indipendente, stato: .inEssere, area: .risparmio, nome: "Polizza")
        polizza.scadenza = AiutiProva.data(2026, 11, 13)
        polizza.controvalore = 50_000
        let scade = MotoreMossaDelGiorno.scegli(ingressi(clienti: [a], posizioni: [polizza]))
        verifica("Mossa: punteggio della scadenza vicina", Double(scade.mossa?.punteggio ?? -1), 52)
        verifica.vero("Mossa: la scadenza dice quanto c'è da destinare", scade.mossa?.motivo.contains("da destinare") == true)
        verifica.vero("Mossa: il canale della scadenza (indipendente)", scade.mossa?.canale == .indipendente)
        verifica.vero("Mossa: scadenza vicina, nel fascicolo il capitale in scadenza",
                      scade.mossa?.report.contains(.liquidita) == true)
        let collegato = Appuntamento(id: "app-a", clienteId: "a", titolo: "Scadenza", inizio: AiutiProva.data(2026, 11, 5),
                                     durataMinuti: 45, luogo: "", note: "", stato: .pianificato, tipo: .revisione, posizioneId: "pol-a")
        let avviata = MotoreMossaDelGiorno.scegli(ingressi(clienti: [a], posizioni: [polizza], appuntamenti: [collegato]))
        verifica("Mossa: scadenza già in agenda, punti dimezzati", Double(avviata.mossa?.punteggio ?? -1), 26)
        verifica.vero("Mossa: con l'appuntamento in agenda si prepara quello", avviata.mossa?.appuntamento.id == "app-a"
                      && avviata.mossa?.appuntamentoInAgenda == true)
        var diOggi = collegato
        diOggi.inizio = oggi
        let oggiInAgenda = MotoreMossaDelGiorno.scegli(ingressi(clienti: [a], posizioni: [polizza], appuntamenti: [diOggi]))
        verifica.vero("Mossa: incontro oggi, titolo «Prepara l'incontro»",
                      oggiInAgenda.mossa?.titolo(oggi: oggi) == "Prepara l'incontro con Anna Prova")
        // I debiti in scadenza non sono una mossa
        var mutuo = polizza
        mutuo.area = .debiti
        verifica.vero("Mossa: un debito in scadenza non è una mossa",
                      MotoreMossaDelGiorno.scegli(ingressi(clienti: [a], posizioni: [mutuo])).mossa == nil)
    }

    // MARK: - I 5 clienti di prova

    private static func clientiDiProva(_ verifica: VerificaCalcoli) {
        let demo = DatiPrisma.demo()
        let adesso = Date()
        func calcola(_ posizioni: [Posizione], _ appuntamenti: [Appuntamento], _ incontri: [Incontro]) -> EsitoMossaDelGiorno {
            MotoreMossaDelGiorno.calcola(clienti: demo.clienti, posizioni: posizioni, appuntamenti: appuntamenti,
                                         attivita: demo.attivita, incontri: incontri, prodotti: demo.prodotti,
                                         analisi: demo.analisi, regoleOccasioni: demo.impostazioni.occasioni,
                                         sogliaSeguito: demo.impostazioni.giorniSeguitoProposte, oggi: adesso)
        }
        // Così come sono: c'è sempre una mossa (la polizza di Sofia scade fra 70 giorni), con un motivo vero
        let base = calcola(demo.posizioni, demo.appuntamenti, demo.incontri)
        let ids = Set(demo.clienti.map(\.id))
        verifica.vero("Mossa (clienti di prova): c'è una mossa", base.mossa != nil)
        verifica.vero("Mossa (clienti di prova): il cliente è uno dei 5", base.mossa.map { ids.contains($0.cliente.id) } == true)
        verifica.vero("Mossa (clienti di prova): il motivo non è vuoto e finisce con il punto",
                      base.mossa.map { $0.motivo.count > 10 && $0.motivo.hasSuffix(".") } == true)
        verifica.vero("Mossa (clienti di prova): sopra la soglia", (base.mossa?.punteggio ?? 0) >= PesiMossaDelGiorno.sogliaMinima)
        verifica.vero("Mossa (clienti di prova): report per l'incontro", base.mossa.map { !$0.report.isEmpty } == true)

        // Il PIP di Giulia presentato 50 giorni fa, senza appuntamenti né incontri: è lei la mossa del giorno
        let cal = Calendar.current
        let presentata = cal.date(byAdding: .day, value: -50, to: cal.startOfDay(for: adesso)).flatMap {
            cal.date(bySettingHour: 10, minute: 0, second: 0, of: $0)
        } ?? adesso
        let posizioni = demo.posizioni.map { p -> Posizione in
            guard p.id == "pos-giulia-piano-previdenziale-integrativo" else { return p }
            var q = p
            var s = q.seguito ?? SeguitoProposta()
            s.presentataIl = presentata
            q.seguito = s
            return q
        }
        let giulia = calcola(posizioni, demo.appuntamenti.filter { $0.clienteId != "giulia" },
                             demo.incontri.filter { $0.clienteId != "giulia" })
        verifica.vero("Mossa (clienti di prova): Giulia, con il PIP fermo", giulia.mossa?.cliente.id == "giulia")
        verifica.vero("Mossa (clienti di prova): il motivo dice da quanti giorni",
                      giulia.mossa?.motivo.contains("è ferma da 50 giorni") == true)
        verifica.vero("Mossa (clienti di prova): il canale del PIP (Alleanza)", giulia.mossa?.canale == .alleanza)
        verifica.vero("Mossa (clienti di prova): anche il riesame che manca",
                      giulia.mossa?.segnali.contains { $0.tipo == .riesame } == true)
        verifica.vero("Mossa (clienti di prova): nel fascicolo il piano previdenziale",
                      giulia.mossa?.report.contains(.previdenza) == true)
    }
}
