import Foundation

// La rete di Mercato (giro 7): l'unica parte di Prisma che esce su internet, e solo così.
// - Solo con l'interruttore «Dati di mercato» acceso (`ImpostazioniMercato.attivo`, spento di base).
// - Solo verso due indirizzi pubblici: il Data Portal della BCE (SDMX) e la dissemination API di Eurostat (JSON-stat).
// - Tutte le richieste nascono da una sola funzione, `richiesta(_:oggi:)`, che riceve soltanto una serie della
//   configurazione (codice pubblico, filtri pubblici) e la data di oggi: nessun dato dei clienti può entrarci (né
//   nomi, né importi, né portafogli, né ISIN). Un codice che non ha la forma dei codici pubblici non parte.
// - Niente account, niente chiavi, niente cookie, niente cache del sistema (sessione effimera), attese brevi.
// - Cache: un nuovo scaricamento non parte prima di `intervalloMinimo` dall'ultimo (salvo «Aggiorna ora»).
// Le prove (ProvaCalcoliMercato) non escono su internet: rispondono le risposte di esempio di Risorse/Mercato/Esempi.

/// Com'è andato un aggiornamento.
struct EsitoAggiornamentoMercato {
    var archivio: ArchivioMercato
    /// Le serie scaricate e lette.
    var scaricate: [String]
    /// id della serie → perché non si è scaricata.
    var errori: [String: String]
    /// true se non è partita nessuna richiesta (interruttore spento o ultimo aggiornamento troppo recente).
    var saltato: Bool
}

enum ClienteMercato {
    static let indirizzoBCE = "https://data-api.ecb.europa.eu/service/data/"
    static let indirizzoEurostat = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
    /// Gli unici host a cui Prisma può chiedere qualcosa su internet.
    static let hostConsentiti: Set<String> = ["data-api.ecb.europa.eu", "ec.europa.eu"]
    static let attesaRichiesta: TimeInterval = 20
    static let attesaRisorsa: TimeInterval = 60
    /// Un nuovo scaricamento automatico non parte prima di tante ore dall'ultimo.
    static let intervalloMinimo: TimeInterval = 6 * 60 * 60
    /// Dati giornalieri: le ultime tante osservazioni (il tasso BCE ha un valore per ogni variazione: anche se non
    /// cambia da più di un anno, l'ultimo valore arriva).
    static let osservazioniGiornaliere = 300

    /// Le forme ammesse dei codici pubblici (configurazione): chiave SDMX della BCE, dataset e filtri di Eurostat.
    static let formaChiaveBCE = #"^[A-Z0-9_]{2,20}(\.[A-Za-z0-9_]{1,30}){1,15}$"#
    static let formaDatasetEurostat = #"^[a-z0-9_]{3,40}$"#
    static let formaFiltro = #"^[A-Za-z0-9_]{1,30}$"#

    // MARK: - L'unica funzione che costruisce le richieste

    /// La richiesta per una serie della configurazione, oppure nil se il codice o i filtri non hanno la forma dei
    /// codici pubblici. Riceve solo la serie e la data di oggi (per il periodo): nessun dato dei clienti.
    static func richiesta(_ s: ConfigurazioneMercato.Serie, oggi: Date) -> URLRequest? {
        var componenti: URLComponents?
        var accetta = ""
        switch s.fonte {
        case .bce:
            guard s.codice.range(of: formaChiaveBCE, options: .regularExpression) != nil,
                  let punto = s.codice.firstIndex(of: ".") else { return nil }
            let flusso = String(s.codice[..<punto])
            let chiave = String(s.codice[s.codice.index(after: punto)...])
            componenti = URLComponents(string: indirizzoBCE + flusso + "/" + chiave)
            var q = [URLQueryItem(name: "format", value: "csvdata")]
            if s.frequenza == .giornaliera {
                q.append(URLQueryItem(name: "lastNObservations", value: String(osservazioniGiornaliere)))
            } else if let inizio = inizio(s.frequenza, oggi: oggi) {
                q.append(URLQueryItem(name: "startPeriod", value: periodo(inizio, frequenza: s.frequenza)))
            }
            componenti?.queryItems = q
            accetta = "text/csv"
        case .eurostat:
            guard s.codice.range(of: formaDatasetEurostat, options: .regularExpression) != nil else { return nil }
            let filtri = (s.filtri ?? [:]).sorted { $0.key < $1.key }
            guard filtri.allSatisfy({ $0.key.range(of: formaFiltro, options: .regularExpression) != nil
                                      && $0.value.range(of: formaFiltro, options: .regularExpression) != nil }) else { return nil }
            componenti = URLComponents(string: indirizzoEurostat + s.codice)
            var q = [URLQueryItem(name: "format", value: "JSON"), URLQueryItem(name: "lang", value: "EN")]
            q += filtri.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let inizio = inizio(s.frequenza, oggi: oggi) {
                q.append(URLQueryItem(name: "sinceTimePeriod", value: periodo(inizio, frequenza: s.frequenza)))
            }
            componenti?.queryItems = q
            accetta = "application/json"
        case .csv, .aMano:
            return nil
        }
        guard let url = componenti?.url, url.scheme == "https", let host = url.host, hostConsentiti.contains(host) else { return nil }
        var r = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: attesaRichiesta)
        r.httpMethod = "GET"
        r.httpShouldHandleCookies = false
        r.setValue(accetta, forHTTPHeaderField: "Accept")
        r.setValue("Prisma", forHTTPHeaderField: "User-Agent")
        return r
    }

    /// Le richieste di un aggiornamento: nessuna con l'interruttore spento; altrimenti una per ogni serie attiva con un
    /// codice valido.
    static func richieste(impostazioni: ImpostazioniMercato, configurazione: ConfigurazioneMercato,
                          oggi: Date) -> [(serie: ConfigurazioneMercato.Serie, richiesta: URLRequest)] {
        guard impostazioni.attivo else { return [] }
        return configurazione.attive(impostazioni).compactMap { s in richiesta(s, oggi: oggi).map { (serie: s, richiesta: $0) } }
    }

    /// Da quando chiedere i dati: 3 anni (o 13 mesi per i giornalieri) prima di oggi.
    static func inizio(_ frequenza: FrequenzaMercato, oggi: Date) -> Date? {
        Calendar(identifier: .gregorian).date(byAdding: .month, value: -frequenza.mesiConservati, to: oggi)
    }

    /// Il periodo nella forma delle API: «2023-11-04» (giornaliera), «2023-11» (mensile), «2023-Q4», «2023».
    static func periodo(_ d: Date, frequenza: FrequenzaMercato) -> String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: d)
        let a = c.year ?? 2000, m = c.month ?? 1, g = c.day ?? 1
        switch frequenza {
        case .giornaliera: return String(format: "%04d-%02d-%02d", a, m, g)
        case .mensile: return String(format: "%04d-%02d", a, m)
        case .trimestrale: return String(format: "%04d-Q%d", a, (m - 1) / 3 + 1)
        case .annuale: return String(format: "%04d", a)
        }
    }

    // MARK: - Sessione e scaricamento

    /// Una sessione effimera: niente cookie, niente cache, niente credenziali salvate, attese brevi. `protocolli`
    /// serve solo alle prove (risposte di esempio, nessuna rete).
    static func sessione(protocolli: [AnyClass] = []) -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.httpCookieAcceptPolicy = .never
        c.httpShouldSetCookies = false
        c.httpCookieStorage = nil
        c.urlCredentialStorage = nil
        c.urlCache = nil
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        c.timeoutIntervalForRequest = attesaRichiesta
        c.timeoutIntervalForResource = attesaRisorsa
        c.waitsForConnectivity = false
        if !protocolli.isEmpty { c.protocolClasses = protocolli + (c.protocolClasses ?? []) }
        return URLSession(configuration: c)
    }

    /// Scarica e legge una serie.
    static func scarica(_ s: ConfigurazioneMercato.Serie, richiesta r: URLRequest, sessione: URLSession) async -> Result<LetturaMercato, ErroreMercato> {
        do {
            let (dati, risposta) = try await sessione.data(for: r)
            if let finale = risposta.url?.host, !hostConsentiti.contains(finale) {
                return .failure(.rispostaDiErrore("risposta da un indirizzo non previsto"))
            }
            if let h = risposta as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
                if h.statusCode == 404 { return .failure(.serieNonTrovata(s.codice)) }
                // Eurostat spiega l'errore in JSON: lo si legge, altrimenti basta il codice HTTP
                if s.fonte == .eurostat, case .failure(let e) = leggi(dati, serie: s), case .rispostaDiErrore = e { return .failure(e) }
                return .failure(.rispostaDiErrore("HTTP \(h.statusCode)"))
            }
            return leggi(dati, serie: s)
        } catch {
            return .failure(.rete(error.localizedDescription))
        }
    }

    /// Legge la risposta con il lettore della sua fonte.
    static func leggi(_ dati: Data, serie s: ConfigurazioneMercato.Serie) -> Result<LetturaMercato, ErroreMercato> {
        do {
            switch s.fonte {
            case .bce:
                guard let testo = String(data: dati, encoding: .utf8) else { return .failure(.formatoNonRiconosciuto("testo non UTF-8")) }
                return .success(try LettoreMercato.sdmxCSV(testo, chiave: s.codice))
            case .eurostat:
                return .success(try LettoreMercato.jsonStat(dati))
            case .csv, .aMano:
                return .failure(.richiestaNonValida(s.codice))
            }
        } catch let e as ErroreMercato {
            return .failure(e)
        } catch {
            return .failure(.formatoNonRiconosciuto(error.localizedDescription))
        }
    }

    /// Aggiorna le serie dell'archivio: con l'interruttore spento non parte nulla; senza `forza` non riparte prima di
    /// `intervalloMinimo` dall'ultimo aggiornamento. Le serie una alla volta; poi le serie calcolate (spread).
    static func aggiorna(_ archivio: ArchivioMercato, impostazioni: ImpostazioniMercato, configurazione: ConfigurazioneMercato,
                         oggi: Date, forza: Bool = false, sessione: URLSession? = nil) async -> EsitoAggiornamentoMercato {
        guard impostazioni.attivo else {
            return EsitoAggiornamentoMercato(archivio: archivio, scaricate: [], errori: [:], saltato: true)
        }
        if !forza, let ultimo = archivio.ultimoAggiornamento, oggi.timeIntervalSince(ultimo) < intervalloMinimo, oggi >= ultimo {
            return EsitoAggiornamentoMercato(archivio: archivio, scaricate: [], errori: [:], saltato: true)
        }
        let s = sessione ?? Self.sessione()
        var a = archivio
        var scaricate: [String] = []
        var errori: [String: String] = [:]
        let elenco = richieste(impostazioni: impostazioni, configurazione: configurazione, oggi: oggi)
        for voce in configurazione.attive(impostazioni) where !elenco.contains(where: { $0.serie.id == voce.id }) {
            errori[voce.id] = ErroreMercato.richiestaNonValida(voce.codice).descrizione
        }
        for (serie, r) in elenco {
            switch await scarica(serie, richiesta: r, sessione: s) {
            case .success(let lettura):
                MotoreMercato.registra(lettura, configurata: serie, in: &a, il: oggi)
                scaricate.append(serie.id)
            case .failure(let e):
                errori[serie.id] = e.descrizione
            }
        }
        MotoreMercato.aggiornaCalcolate(configurazione, in: &a, il: oggi)
        if !scaricate.isEmpty { a.ultimoAggiornamento = oggi }
        a.ultimoErrore = errori.isEmpty ? nil
            : errori.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: " · ")
        return EsitoAggiornamentoMercato(archivio: a, scaricate: scaricate, errori: errori, saltato: false)
    }

    // MARK: - Controllo delle chiavi (workflow, `Prisma --controlla-mercato`)

    /// Scarica una volta tutte le serie della configurazione del pacchetto per controllare che le chiavi esistano e che
    /// il lettore le legga. Non apre l'archivio (nessun dato dei clienti) e serve solo al passo informativo del
    /// workflow: nell'app la rete parte solo con l'interruttore acceso.
    static func controllaConfigurazione() -> Int32 {
        guard let configurazione = ConfigurazioneMercato.caricaDelPacchetto(), !configurazione.serie.isEmpty else {
            print("ERRORE: configurazione delle serie (Risorse/Mercato/\(ConfigurazioneMercato.nomeFile)) non trovata o vuota")
            return 1
        }
        var acceso = ImpostazioniMercato()
        acceso.attivo = true
        let impostazioni = acceso
        final class Scatola: @unchecked Sendable { var esito: EsitoAggiornamentoMercato? }
        let scatola = Scatola()
        let fatto = DispatchSemaphore(value: 0)
        let oggi = Date()
        Task.detached {
            scatola.esito = await aggiorna(ArchivioMercato(), impostazioni: impostazioni, configurazione: configurazione, oggi: oggi, forza: true)
            fatto.signal()
        }
        guard fatto.wait(timeout: .now() + attesaRisorsa * Double(configurazione.serie.count + 1)) == .success, let esito = scatola.esito else {
            print("ERRORE: lo scaricamento delle serie non è finito in tempo")
            return 1
        }
        for s in configurazione.serie {
            if let serie = esito.archivio.serie(s.id), let ultimo = serie.ultimo {
                print("OK \(s.id) (\(s.codice)): \(serie.punti.count) valori, ultimo \(LettoreMercato.periodoBreve(ultimo.data)) = \(ultimo.valore) · \(serie.citazione)")
            } else {
                print("ERRORE \(s.id) (\(s.codice)): \(esito.errori[s.id] ?? "nessun valore")")
            }
        }
        for k in configurazione.calcolate {
            if let serie = esito.archivio.serie(k.id), let ultimo = serie.ultimo {
                print("OK \(k.id) (\(k.da) − \(k.meno)): \(serie.punti.count) valori, ultimo = \(ultimo.valore)")
            } else {
                print("ERRORE \(k.id): serie calcolata non ricavata")
            }
        }
        return esito.errori.isEmpty ? 0 : 1
    }
}

extension LettoreMercato {
    /// «2026-10-23» per i messaggi di controllo.
    static func periodoBreve(_ d: Date) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
