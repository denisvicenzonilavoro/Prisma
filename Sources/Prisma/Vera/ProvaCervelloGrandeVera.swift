import Foundation

/// Prova di «Il cervello grande» (Vera/BRIEF.md, fase 5, funzione 25) dentro `Prisma --prova-vera`: il motore esterno non
/// collegato (nessuna richiesta parte), il guardiano (lavoro, modalità cliente e dati dei clienti bloccati, messaggi
/// ricostruiti senza contesto), l'etichetta sotto ogni risposta e nessuna chiave nelle impostazioni.
enum ProvaCervelloGrandeVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let dati = StatoShell(persistente: false).dati.istantanea
        let id = IdentificativiClienti(clienti: dati.clienti, consulente: dati.impostazioni.nomeUtente)
        nonCollegato(id, controlla)
        guardiano(id, controlla)
        etichetta(controlla)
        impostazioni(controlla)
    }

    private static let conversazione = SceltaVera(modalita: .conversazione, pensa: false)

    private static func nonCollegato(_ id: IdentificativiClienti, _ controlla: (Bool, String) -> Void) {
        controlla(CervelloGrandeVera.collegamentoAmmesso == false, "Cervello grande: il motore esterno non è collegato")
        let base = CervelloGrandeVera.guardiano(domanda: "Cos'è l'inflazione?", scelta: conversazione, storia: [], inModoCliente: false, identificativi: id)
        controlla(base.messaggi == nil, "Cervello grande: con il valore di base il guardiano blocca tutto")
        // Anche con dei messaggi ammessi (creati solo dal guardiano) il motore non collegato non risponde
        let ammessi = CervelloGrandeVera.guardiano(domanda: "Cos'è l'inflazione?", scelta: conversazione, storia: [], inModoCliente: false,
                                                   identificativi: id, ammesso: true)
        if case .ammesso(let m) = ammessi {
            let errore = ProvaSuMisuraVera.aspetta { () async -> Bool in
                do { _ = try await MotoreEsternoNonCollegato().scrivi(m); return false } catch { return error is ErroreVera }
            }
            controlla(errore, "Cervello grande: il motore non collegato lancia sempre un errore")
        } else {
            controlla(false, "Cervello grande: una domanda generale passa il guardiano (solo nella prova, con il collegamento acceso)")
        }
    }

    private static func guardiano(_ id: IdentificativiClienti, _ controlla: (Bool, String) -> Void) {
        func esito(_ domanda: String, scelta: SceltaVera = conversazione, storia: [MessaggioVera] = [], cliente: Bool = false) -> EsitoGuardiano {
            CervelloGrandeVera.guardiano(domanda: domanda, scelta: scelta, storia: storia, inModoCliente: cliente, identificativi: id, ammesso: true)
        }
        controlla(esito("Cos'è l'inflazione?", scelta: SceltaVera(modalita: .lavoro, pensa: false)).messaggi == nil,
                  "Cervello grande: la modalità lavoro resta a Qwen")
        controlla(esito("Cosa ne pensi di Giulia?").messaggi == nil, "Cervello grande: una domanda con il nome di un cliente resta sul Mac")
        controlla(esito("Scrivi a anna.verdi@example.org").messaggi == nil && esito("Il codice RSSGLI87L42A944X è giusto?").messaggi == nil,
                  "Cervello grande: email e codici fiscali restano sul Mac")
        controlla(esito("Cos'è l'inflazione?", cliente: true).messaggi == nil, "Cervello grande: in modalità cliente niente motore esterno")
        var lavoroUtente = MessaggioVera(autore: .utente, testo: "Quanto ha nel fondo?")
        lavoroUtente.data = Date()
        var lavoroVera = MessaggioVera(autore: .vera, testo: "Ha 20.800 € nel fondo pensione.", motore: "Qwen sul Mac")
        lavoroVera.modalita = .lavoro
        let nomeUtente = MessaggioVera(autore: .utente, testo: "Ieri ho visto Marco Bianchi")
        var nomeVera = MessaggioVera(autore: .vera, testo: "Bene, com'è andata?", motore: "Qwen sul Mac")
        nomeVera.modalita = .conversazione
        let buonaUtente = MessaggioVera(autore: .utente, testo: "Dammi un'idea per una mail di auguri")
        var buonaVera = MessaggioVera(autore: .vera, testo: "Un augurio semplice, con un ricordo dell'anno insieme.", motore: "Qwen sul Mac")
        buonaVera.modalita = .conversazione
        let regoleUtente = MessaggioVera(autore: .utente, testo: "Apri l'agenda")
        var regoleVera = MessaggioVera(autore: .vera, testo: "Ecco l'agenda di oggi: 3 appuntamenti.", motore: StatoShell.motoreAzioni)
        regoleVera.modalita = .conversazione
        let storia = [lavoroUtente, lavoroVera, nomeUtente, nomeVera, regoleUtente, regoleVera, buonaUtente, buonaVera]
        let m = esito("E in inglese come la scriveresti?", storia: storia).messaggi ?? []
        let testi = m.map(\.testo)
        controlla(m.count == 4 && m.first?.ruolo == .sistema && m.first?.testo == IstruzioniVera.conversazione
                  && testi[1] == buonaUtente.testo && testi[2] == buonaVera.testo && testi.last == "E in inglese come la scriveresti?",
                  "Cervello grande: solo le battute di conversazione pulite e la domanda (\(m.count) messaggi)")
        let tutto = testi.joined(separator: "\n")
        controlla(!tutto.contains("CONTESTO:") && !tutto.contains("SCHEDA DEL CLIENTE") && !tutto.contains("cliente attivo")
                  && !tutto.contains("20.800") && !tutto.contains("Marco"),
                  "Cervello grande: niente riga di contesto, niente scheda, niente cifre o nomi dei clienti")
        let conContesto = NucleoVera.rigaContesto(AmbienteVera(cliente: "Giulia Rossi")) + "\n\nCos'è l'inflazione?"
        controlla(esito(conContesto).messaggi == nil, "Cervello grande: un messaggio con la riga di contesto di Prisma è bloccato")
    }

    private static func etichetta(_ controlla: (Bool, String) -> Void) {
        var lavoro = MessaggioVera(autore: .vera, testo: "Ecco.", motore: "Qwen sul Mac")
        lavoro.modalita = .lavoro
        var libera = MessaggioVera(autore: .vera, testo: "Ecco.", motore: "Qwen sul Mac")
        libera.modalita = .conversazione
        let regole = MessaggioVera(autore: .vera, testo: "Fatto.", motore: StatoShell.motoreAzioni)
        let calcoli = MessaggioVera(autore: .vera, testo: "Fatto.", motore: MotoriVera.sintesi.nome)
        let esterno = MessaggioVera(autore: .vera, testo: "Ecco.", motore: CervelloGrandeVera.nome)
        let suMisura = MessaggioVera(autore: .vera, testo: "Ecco.", motore: MotoreLocale.nome("vera-su-misura:2026-11-08"))
        controlla(EtichettaMotore.per(lavoro) == EtichettaMotore(testo: "Sul Mac · Qwen · dati del cliente", tono: .sulMac),
                  "Etichetta: Qwen in lavoro «Sul Mac · Qwen · dati del cliente»")
        controlla(EtichettaMotore.per(libera)?.testo == "Sul Mac · Qwen", "Etichetta: Qwen in conversazione «Sul Mac · Qwen»")
        controlla(EtichettaMotore.per(regole)?.testo == "Sul Mac · regole e calcoli di Prisma" && EtichettaMotore.per(calcoli)?.tono == .prisma,
                  "Etichetta: regole e calcoli di Prisma")
        controlla(EtichettaMotore.per(esterno) == EtichettaMotore(testo: "Motore esterno · nessun dato dei clienti", tono: .esterno),
                  "Etichetta: «Motore esterno · nessun dato dei clienti»")
        controlla(EtichettaMotore.per(suMisura)?.testo == "Sul Mac · Vera su misura", "Etichetta: «Sul Mac · Vera su misura»")
        controlla(EtichettaMotore.per(MessaggioVera(autore: .utente, testo: "Ciao")) == nil, "Etichetta: niente sotto i messaggi dell'utente")
        // Regola 3 bloccata: ogni messaggio di Vera con un motore ha la sua etichetta, nei dati di prova di tutte le chat
        let s = StatoShell(persistente: false)
        let senza = s.dati.conversazioni.values.flatMap { $0 }.filter { $0.autore == .vera && ($0.motore ?? "").isEmpty == false && EtichettaMotore.per($0) == nil }
        controlla(senza.isEmpty, "Etichetta: ogni risposta di Vera con un motore ha l'etichetta")
    }

    private static func impostazioni(_ controlla: (Bool, String) -> Void) {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        let testo = ((try? e.encode(ImpostazioniVera())).flatMap { String(data: $0, encoding: .utf8) } ?? "").lowercased()
        let vietate = ["\"chiave", "apikey", "api_key", "token", "password", "segreto", "secret", "\"url"]
        controlla(!testo.isEmpty && !vietate.contains { testo.contains($0) } && testo.contains("motoreesterno"),
                  "Cervello grande: nessuna chiave, indirizzo o password nelle impostazioni di Vera")
        var vera = ImpostazioniVera()
        vera.motoreEsterno.tipo = .servizio
        let d = JSONDecoder()
        let tornata = (try? e.encode(vera)).flatMap { try? d.decode(ImpostazioniVera.self, from: $0) }
        controlla(tornata?.motoreEsterno.tipo == .servizio && tornata == vera && CervelloGrandeVera.collegamentoAmmesso == false,
                  "Cervello grande: il tipo scelto si salva, e il motore resta non collegato")
        controlla(CervelloGrandeVera.regole.count == 3, "Cervello grande: tre regole, tutte bloccate")
    }
}
