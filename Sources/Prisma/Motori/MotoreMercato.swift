import Foundation

// Il motore di Mercato, «Prisma conosce il mercato» (Design/template-novita-specifica.md §12.5.3, giro 7). Motore puro:
// i dati, le soglie dell'utente e `oggi` entrano sempre come parametri; niente rete (ClienteMercato), niente Shell.
// - ricerca per ISIN con «nei portafogli di N clienti» (dalle posizioni);
// - «Chi è toccato oggi»: gli eventi di mercato (variazioni oltre soglia, calo dal massimo, distanza dal riferimento,
//   cedole in arrivo) incrociati con le posizioni vere, separati per canale;
// - avvisi con le soglie dell'utente (nessuna soglia = nessun avviso), con lo stato nuovo o visto;
// - i valori nuovi delle posizioni dalle quote per ISIN, da passare all'aggiornamento dei valori (AggiornaValori),
//   sempre con data e fonte;
// - unione, potatura e serie calcolate (spread).

/// Le regole fisse di Mercato, tutte in un punto.
enum RegoleMercato {
    /// Il massimo per il «calo dal massimo» si cerca negli ultimi tanti giorni.
    static let giorniMassimo = 365
    /// La distanza dal riferimento si misura su tanti giorni («in un mese»).
    static let giorniDistanza = 30
    /// Una quota più vecchia di così non fa più nascere eventi.
    static let giorniQuotaRecente = 35
    /// Un avviso di un evento singolo (variazione, cedola) resta nell'elenco per tanti giorni dalla data del dato.
    static let giorniConservazioneAvvisi = 90
    /// Un avviso diventa un'occasione per Messaggi per tanti giorni dalla sua nascita (oggi e ieri in «Da mandare oggi»).
    static let giorniMessaggio = 7
    /// Un obiettivo oltre tanti anni è toccato dall'inflazione.
    static let anniObiettivoInflazione = 5
}

/// Un cliente toccato da un evento: le sue posizioni, l'impatto stimato in euro (nil = solo qualitativo) per canale.
struct ClienteToccato: Equatable {
    var clienteId: String
    var posizioni: [String]
    var impatto: Double?
    var perCanale: [Canale: Double]
    var canali: [Canale]

    /// Il canale quando le posizioni toccate sono di uno solo.
    var canaleUnico: Canale? { canali.count == 1 ? canali.first : nil }
}

/// Un evento di mercato con i clienti che tocca (non si salva: si ricalcola; gli avvisi sì).
struct EventoMercato: Identifiable, Equatable {
    let id: String
    let tipo: TipoEventoMercato
    let titolo: String
    let dettaglio: String
    /// La misura (variazione in % o in punti, calo in %, distanza in punti, giorni alla cedola) e la soglia.
    let valore: Double
    let soglia: Double
    /// La data del dato (o della cedola).
    let data: Date
    /// La citazione della fonte.
    let fonte: String
    let serieId: String?
    let isin: String?
    let posizioneId: String?
    /// Dal più toccato.
    let toccati: [ClienteToccato]
}

/// Il risultato di una ricerca per ISIN.
struct RicercaISIN: Equatable {
    var isin: String
    /// Le quote importate o scritte a mano (nil = nessuna: «Quota —»).
    var quota: QuotaISIN?
    /// Le posizioni in essere e in proposta con questo ISIN.
    var posizioni: [String]
    var proposte: [String]
    /// I clienti che l'hanno in portafoglio (posizioni in essere), in ordine di id.
    var clienti: [String]
    /// Quanti clienti per canale.
    var clientiPerCanale: [Canale: Int]

    var numeroClienti: Int { clienti.count }
    /// «Nei portafogli di 3 clienti».
    var neiPortafogli: String { TestiMercato.neiPortafogli(clienti.count) }
}

enum RisultatoISIN: Equatable {
    case nonValido
    case trovato(RicercaISIN)
}

/// Un valore nuovo per una posizione, dalle quote per ISIN: quota × numero di quote, con data e fonte.
struct ValoreDaMercato: Identifiable, Equatable {
    var posizioneId: String
    var clienteId: String
    var nomePosizione: String
    var isin: String
    var quota: Double
    var numeroQuote: Double?
    /// nil senza il numero di quote (`motivo`).
    var valore: Double?
    var data: Date
    /// La citazione della fonte della quota.
    var fonte: String
    var motivo: String?

    var id: String { posizioneId }

    /// La riga per `AggiornaValori.esiti`: con la posizione già nota (abbinamento «griglia»), il valore e la data.
    /// Senza valore la riga risulta «senza valore».
    func riga(id: Int) -> AggiornaValori.Riga {
        var r = AggiornaValori.Riga(id: id)
        r.posizioneId = posizioneId
        r.prodotto = nomePosizione
        r.valore = valore
        r.data = ValoriDaDocumento.mezzogiorno(data)
        return r
    }
}

enum MotoreMercato {
    // MARK: - ISIN

    /// Maiuscolo, senza spazi né trattini: « ie00 b4l5 y983 » → «IE00B4L5Y983».
    static func normalizzaISIN(_ s: String) -> String {
        s.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Forma (2 lettere, 9 lettere o cifre, 1 cifra) e cifra di controllo: le lettere diventano numeri (A = 10 … Z = 35)
    /// e sulle cifre si fa il controllo di Luhn.
    static func isinValido(_ s: String) -> Bool {
        let c = Array(s)
        guard c.count == 12, c[0...1].allSatisfy({ $0.isASCII && $0.isUppercase }),
              c[2...10].allSatisfy({ $0.isASCII && ($0.isUppercase || $0.isNumber) }), c[11].isASCII, c[11].isNumber else { return false }
        var cifre: [Int] = []
        for ch in c {
            guard let v = ch.asciiValue else { return false }
            if ch.isNumber {
                cifre.append(Int(v) - 48)
            } else {
                let n = Int(v) - 55
                cifre.append(n / 10)
                cifre.append(n % 10)
            }
        }
        var somma = 0
        for (i, d) in cifre.reversed().enumerated() {
            var x = d
            if i % 2 == 1 {
                x *= 2
                if x > 9 { x -= 9 }
            }
            somma += x
        }
        return somma % 10 == 0
    }

    /// Le posizioni con quell'ISIN (normalizzato), di ogni stato.
    static func posizioni(conISIN isin: String, in posizioni: [Posizione]) -> [Posizione] {
        let codice = normalizzaISIN(isin)
        guard !codice.isEmpty else { return [] }
        return posizioni.filter { p in p.isin.map(normalizzaISIN) == codice }
    }

    /// Cerca un ISIN tra le quote e le posizioni: «nei portafogli di N clienti» conta i clienti con una posizione in
    /// essere (le proposte a parte, le chiuse no).
    static func cercaISIN(_ testo: String, posizioni: [Posizione], quote: [QuotaISIN]) -> RisultatoISIN {
        let codice = normalizzaISIN(testo)
        guard isinValido(codice) else { return .nonValido }
        let stesse = Self.posizioni(conISIN: codice, in: posizioni)
        let inEssere = stesse.filter { $0.stato == .inEssere }
        let clienti = Array(Set(inEssere.map(\.clienteId))).sorted()
        var perCanale: [Canale: Int] = [:]
        for k in Canale.allCases {
            let n = Set(inEssere.filter { $0.canale == k }.map(\.clienteId)).count
            if n > 0 { perCanale[k] = n }
        }
        return .trovato(RicercaISIN(isin: codice, quota: quote.first { $0.isin == codice },
                                    posizioni: inEssere.map(\.id).sorted(),
                                    proposte: stesse.filter { $0.stato == .proposta }.map(\.id).sorted(),
                                    clienti: clienti, clientiPerCanale: perCanale))
    }

    // MARK: - Serie: unione, potatura, valori a una data

    /// L'ultimo punto a quella data o prima (stesso giorno compreso).
    static func valore(_ punti: [PuntoMercato], al data: Date, cal: Calendar = .current) -> PuntoMercato? {
        let fine = cal.startOfDay(for: data)
        return punti.last { cal.startOfDay(for: $0.data) <= fine }
    }

    /// I punti vecchi e nuovi insieme: a parità di giorno vince il nuovo; dal più vecchio.
    static func unisci(_ esistenti: [PuntoMercato], _ nuovi: [PuntoMercato], cal: Calendar = .current) -> [PuntoMercato] {
        var perGiorno: [Date: PuntoMercato] = [:]
        for p in esistenti { perGiorno[cal.startOfDay(for: p.data)] = p }
        for p in nuovi { perGiorno[cal.startOfDay(for: p.data)] = p }
        return perGiorno.values.sorted { $0.data < $1.data }
    }

    /// Solo lo storico che serve (13 mesi per i dati giornalieri, 3 anni per gli altri), più l'ultimo valore prima
    /// del limite: una serie che cambia di rado (il tasso BCE) non resta senza valore.
    static func potati(_ punti: [PuntoMercato], frequenza: FrequenzaMercato, oggi: Date, cal: Calendar = .current) -> [PuntoMercato] {
        guard let limite = cal.date(byAdding: .month, value: -frequenza.mesiConservati, to: cal.startOfDay(for: oggi)) else { return punti }
        let ordinati = punti.sorted { $0.data < $1.data }
        let dentro = ordinati.filter { $0.data >= limite }
        if let prima = ordinati.last(where: { $0.data < limite }) { return [prima] + dentro }
        return dentro
    }

    /// Registra nell'archivio una serie scaricata (BCE o Eurostat) con i dati della configurazione.
    static func registra(_ lettura: LetturaMercato, configurata s: ConfigurazioneMercato.Serie, in archivio: inout ArchivioMercato,
                         il oggi: Date, cal: Calendar = .current) {
        let vecchi = archivio.serie(s.id)?.punti ?? []
        let nuova = SerieMercato(id: s.id, codice: s.codice, nome: s.nome, origine: s.fonte, fonte: s.fonte.nome, datoDiTerzi: s.terzi,
                                 unita: s.unita, tipo: s.tipo, frequenza: s.frequenza,
                                 punti: potati(unisci(vecchi, lettura.punti, cal: cal), frequenza: s.frequenza, oggi: oggi, cal: cal),
                                 aggiornataIl: oggi)
        sostituisci(nuova, in: &archivio)
    }

    /// Registra una serie importata da CSV o scritta a mano dal consulente (indici, quote non per ISIN…).
    static func registraImportata(id: String, nome: String, punti: [PuntoMercato], fonte: String, origine: OrigineDatoMercato,
                                  unita: UnitaMercato, tipo: TipoSerieMercato, frequenza: FrequenzaMercato,
                                  in archivio: inout ArchivioMercato, il oggi: Date, cal: Calendar = .current) {
        let vecchia = archivio.serie(id)
        let nuova = SerieMercato(id: id, codice: vecchia?.codice ?? "", nome: nome, origine: origine, fonte: fonte,
                                 datoDiTerzi: vecchia?.datoDiTerzi, unita: unita, tipo: tipo, frequenza: frequenza,
                                 punti: potati(unisci(vecchia?.punti ?? [], punti, cal: cal), frequenza: frequenza, oggi: oggi, cal: cal),
                                 aggiornataIl: oggi)
        sostituisci(nuova, in: &archivio)
    }

    private static func sostituisci(_ s: SerieMercato, in archivio: inout ArchivioMercato) {
        if let i = archivio.serie.firstIndex(where: { $0.id == s.id }) {
            archivio.serie[i] = s
        } else {
            archivio.serie.append(s)
        }
    }

    /// Registra quote per ISIN (da CSV o a mano): ogni quota porta la sua fonte. Gli ISIN non validi si saltano.
    static func registraQuote(_ quote: [String: [PuntoMercato]], fonte: String, origine: OrigineDatoMercato, nomi: [String: String] = [:],
                              in archivio: inout ArchivioMercato, il oggi: Date, cal: Calendar = .current) {
        for isin in quote.keys.sorted() {
            let codice = normalizzaISIN(isin)
            guard isinValido(codice), let nuovi = quote[isin], !nuovi.isEmpty else { continue }
            let conFonte = nuovi.map { PuntoMercato(data: $0.data, valore: $0.valore, fonte: fonte) }
            if let i = archivio.quote.firstIndex(where: { $0.isin == codice }) {
                var q = archivio.quote[i]
                q.punti = potati(unisci(q.punti, conFonte, cal: cal), frequenza: .giornaliera, oggi: oggi, cal: cal)
                q.fonte = fonte
                q.origine = origine
                q.importataIl = oggi
                if let n = nomi[isin] ?? nomi[codice], !n.isEmpty { q.nome = n }
                archivio.quote[i] = q
            } else {
                archivio.quote.append(QuotaISIN(isin: codice, nome: nomi[isin] ?? nomi[codice] ?? "",
                                                punti: potati(conFonte, frequenza: .giornaliera, oggi: oggi, cal: cal),
                                                fonte: fonte, origine: origine, importataIl: oggi))
            }
        }
        archivio.quote.sort { $0.isin < $1.isin }
    }

    /// Le serie calcolate della configurazione (spread = `da` − `meno` sulle stesse date).
    static func aggiornaCalcolate(_ configurazione: ConfigurazioneMercato, in archivio: inout ArchivioMercato, il oggi: Date,
                                  cal: Calendar = .current) {
        for k in configurazione.calcolate {
            guard let a = archivio.serie(k.da), let b = archivio.serie(k.meno) else { continue }
            guard let s = differenza(a, b, id: k.id, nome: k.nome, unita: k.unita, tipo: k.tipo, il: oggi, cal: cal) else { continue }
            sostituisci(s, in: &archivio)
        }
    }

    /// `a` − `b` sui giorni che hanno entrambe; nil se non ce n'è nessuno. La fonte è quella di `a` (le due serie
    /// della configurazione vengono dalla stessa fonte).
    static func differenza(_ a: SerieMercato, _ b: SerieMercato, id: String, nome: String, unita: UnitaMercato, tipo: TipoSerieMercato,
                           il oggi: Date, cal: Calendar = .current) -> SerieMercato? {
        var perGiorno: [Date: Double] = [:]
        for p in b.punti { perGiorno[cal.startOfDay(for: p.data)] = p.valore }
        let punti = a.punti.compactMap { p -> PuntoMercato? in
            guard let v = perGiorno[cal.startOfDay(for: p.data)] else { return nil }
            return PuntoMercato(data: p.data, valore: p.valore - v)
        }
        guard !punti.isEmpty else { return nil }
        return SerieMercato(id: id, codice: "\(a.codice) − \(b.codice)", nome: nome, origine: a.origine, fonte: a.fonte,
                            datoDiTerzi: a.datoDiTerzi, unita: unita, tipo: tipo, frequenza: a.frequenza, punti: punti, aggiornataIl: oggi)
    }

    // MARK: - Chi è toccato

    /// Gli eventi di mercato con le soglie dell'utente, incrociati con le posizioni vere (in essere) dei clienti.
    /// Senza soglie nessun evento. Ordine: dal più grande impatto, poi per tipo e titolo.
    static func toccati(archivio: ArchivioMercato, impostazioni: ImpostazioniMercato, posizioni: [Posizione], clienti: [Cliente],
                        obiettivi: [Obiettivo], oggi: Date, cal: Calendar = .current) -> [EventoMercato] {
        let inEssere = posizioni.filter { $0.stato == .inEssere }
        let nomi = Dictionary(clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { a, _ in a })
        var eventi: [EventoMercato] = []
        eventi += variazioni(archivio.serie, impostazioni: impostazioni, posizioni: inEssere, obiettivi: obiettivi, nomi: nomi, oggi: oggi, cal: cal)
        eventi += cali(archivio.quote, impostazioni: impostazioni, posizioni: inEssere, nomi: nomi, oggi: oggi, cal: cal)
        eventi += distanze(archivio, impostazioni: impostazioni, posizioni: inEssere, nomi: nomi, oggi: oggi, cal: cal)
        eventi += cedole(inEssere, impostazioni: impostazioni, nomi: nomi, oggi: oggi, cal: cal)
        return eventi.sorted { a, b in
            let ia = a.toccati.compactMap(\.impatto).map(abs).reduce(0, +)
            let ib = b.toccati.compactMap(\.impatto).map(abs).reduce(0, +)
            if ia != ib { return ia > ib }
            if a.tipo != b.tipo {
                return (TipoEventoMercato.allCases.firstIndex(of: a.tipo) ?? 0) < (TipoEventoMercato.allCases.firstIndex(of: b.tipo) ?? 0)
            }
            return a.id < b.id
        }
    }

    /// Le serie che si sono mosse sull'ultimo dato oltre la soglia (indici in %, tassi e inflazione in punti).
    static func variazioni(_ serie: [SerieMercato], impostazioni: ImpostazioniMercato, posizioni: [Posizione], obiettivi: [Obiettivo],
                           nomi: [String: String], oggi: Date, cal: Calendar) -> [EventoMercato] {
        var eventi: [EventoMercato] = []
        for s in serie {
            guard s.punti.count >= 2, let dopo = s.punti.last else { continue }
            let prima = s.punti[s.punti.count - 2]
            guard recente(dopo.data, giorni: s.frequenza.giorniFreschezza, oggi: oggi, cal: cal) else { continue }
            let inPercentuale = s.unita.variazioneInPercentuale
            guard let soglia = inPercentuale ? impostazioni.variazioneIndici : impostazioni.variazioneTassi else { continue }
            let delta: Double
            if inPercentuale {
                guard prima.valore != 0 else { continue }
                delta = (dopo.valore / prima.valore - 1) * 100
            } else {
                delta = dopo.valore - prima.valore
            }
            guard abs(delta) >= soglia - 1e-9 else { continue }
            let toccati = esposti(a: s, variazione: delta, posizioni: posizioni, obiettivi: obiettivi, nomi: nomi, oggi: oggi, cal: cal)
            guard !toccati.isEmpty else { continue }
            eventi.append(EventoMercato(id: "variazione-\(s.id)-\(timbro(dopo.data, cal: cal))", tipo: .variazioneSerie,
                                        titolo: TestiMercato.titoloVariazione(s, variazione: delta, data: dopo.data),
                                        dettaglio: TestiMercato.dettaglioVariazione(s, prima: prima, dopo: dopo, soglia: soglia),
                                        valore: delta, soglia: soglia, data: dopo.data, fonte: s.citazione, serieId: s.id,
                                        isin: nil, posizioneId: nil, toccati: toccati))
        }
        return eventi
    }

    /// Chi è esposto a una serie, per tipo: azioni agli indici azionari (impatto = valore × quota in azioni ×
    /// variazione), titoli di Stato ai rendimenti e allo spread, liquidità e debiti ai tassi, obiettivi lontani
    /// all'inflazione. La gestione separata non entra (non scende, come nella prova delle crisi).
    static func esposti(a s: SerieMercato, variazione: Double, posizioni: [Posizione], obiettivi: [Obiettivo],
                        nomi: [String: String], oggi: Date, cal: Calendar) -> [ClienteToccato] {
        var voci: [(posizione: Posizione, impatto: Double?)] = []
        switch s.tipo {
        case .indiceAzionario:
            for p in posizioni {
                guard let c = MotoreResistenza.composizione(p), c.azioni > 0 else { continue }
                voci.append((posizione: p, impatto: p.valore * c.azioni * variazione / 100))
            }
        case .rendimentoStato, .spread:
            for p in posizioni {
                guard let c = MotoreResistenza.composizione(p), c.governativi > 0 else { continue }
                voci.append((posizione: p, impatto: nil))
            }
        case .tassoInterbancario, .tassoUfficiale:
            for p in posizioni where p.area == .liquidita || p.area == .debiti { voci.append((posizione: p, impatto: nil)) }
        case .inflazione:
            let limite = cal.date(byAdding: .year, value: RegoleMercato.anniObiettivoInflazione, to: oggi) ?? oggi
            let clienti = Set(obiettivi.filter { $0.scadenza > limite }.map(\.clienteId))
            return clienti.filter { nomi[$0] != nil }.map {
                ClienteToccato(clienteId: $0, posizioni: [], impatto: nil, perCanale: [:], canali: [])
            }.sorted { ordine($0, $1, nomi: nomi) }
        case .altro:
            return []
        }
        return raggruppa(voci, nomi: nomi)
    }

    /// Le quote per ISIN scese dal massimo degli ultimi 12 mesi di almeno la soglia, nei portafogli dei clienti.
    static func cali(_ quote: [QuotaISIN], impostazioni: ImpostazioniMercato, posizioni: [Posizione], nomi: [String: String],
                     oggi: Date, cal: Calendar) -> [EventoMercato] {
        guard let soglia = impostazioni.caloDalMassimo else { return [] }
        var eventi: [EventoMercato] = []
        for q in quote {
            guard let ultimo = valore(q.punti, al: oggi, cal: cal),
                  recente(ultimo.data, giorni: RegoleMercato.giorniQuotaRecente, oggi: oggi, cal: cal),
                  let inizio = cal.date(byAdding: .day, value: -RegoleMercato.giorniMassimo, to: cal.startOfDay(for: oggi)) else { continue }
            let periodo = q.punti.filter { $0.data >= inizio && $0.data <= ultimo.data }
            guard let massimo = periodo.max(by: { $0.valore < $1.valore }), massimo.valore > 0 else { continue }
            let calo = (1 - ultimo.valore / massimo.valore) * 100
            guard calo >= soglia - 1e-9 else { continue }
            let suoi = Self.posizioni(conISIN: q.isin, in: posizioni)
            var voci: [(posizione: Posizione, impatto: Double?)] = []
            for p in suoi {
                let impatto: Double
                if let n = p.numeroQuote, n > 0 {
                    impatto = n * (ultimo.valore - massimo.valore)
                } else {
                    impatto = -p.valore * calo / 100
                }
                voci.append((posizione: p, impatto: impatto))
            }
            let toccati = raggruppa(voci, nomi: nomi)
            guard !toccati.isEmpty else { continue }
            let nome = nomeISIN(q, posizioni: suoi)
            let fonte = TestiMercato.citazione(origine: q.origine, fonte: ultimo.fonte ?? q.fonte, datoDiTerzi: nil)
            eventi.append(EventoMercato(id: "calo-\(q.isin)", tipo: .caloDalMassimo, titolo: TestiMercato.titoloCalo(nome: nome, calo: calo),
                                        dettaglio: TestiMercato.dettaglioCalo(ultimo: ultimo, massimo: massimo, soglia: soglia, fonte: fonte),
                                        valore: calo, soglia: soglia, data: ultimo.data, fonte: fonte, serieId: nil, isin: q.isin,
                                        posizioneId: nil, toccati: toccati))
        }
        return eventi
    }

    /// Le quote che in un mese si sono allontanate dalla loro serie di riferimento (scelta dall'utente per ISIN) di
    /// almeno la soglia, in punti percentuali. Il riferimento deve essere un indice (variazione in %).
    static func distanze(_ archivio: ArchivioMercato, impostazioni: ImpostazioniMercato, posizioni: [Posizione], nomi: [String: String],
                         oggi: Date, cal: Calendar) -> [EventoMercato] {
        guard let soglia = impostazioni.distanzaDalRiferimento else { return [] }
        var eventi: [EventoMercato] = []
        for (isin, idSerie) in impostazioni.riferimenti.sorted(by: { $0.key < $1.key }) {
            guard let q = archivio.quota(isin), let s = archivio.serie(idSerie), s.unita.variazioneInPercentuale,
                  let ultimo = valore(q.punti, al: oggi, cal: cal),
                  recente(ultimo.data, giorni: RegoleMercato.giorniQuotaRecente, oggi: oggi, cal: cal),
                  let inizio = cal.date(byAdding: .day, value: -RegoleMercato.giorniDistanza, to: ultimo.data),
                  let qPrima = valore(q.punti, al: inizio, cal: cal), qPrima.valore > 0,
                  let sDopo = valore(s.punti, al: ultimo.data, cal: cal), let sPrima = valore(s.punti, al: inizio, cal: cal),
                  sPrima.valore > 0, sDopo.data > sPrima.data else { continue }
            let vq = (ultimo.valore / qPrima.valore - 1) * 100
            let vs = (sDopo.valore / sPrima.valore - 1) * 100
            let distanza = vq - vs
            guard abs(distanza) >= soglia - 1e-9 else { continue }
            let suoi = Self.posizioni(conISIN: q.isin, in: posizioni)
            let voci: [(posizione: Posizione, impatto: Double?)] = suoi.map { p -> (posizione: Posizione, impatto: Double?) in
                (posizione: p, impatto: nil)
            }
            let toccati = raggruppa(voci, nomi: nomi)
            guard !toccati.isEmpty else { continue }
            let nome = nomeISIN(q, posizioni: suoi)
            let fonte = TestiMercato.citazione(origine: q.origine, fonte: ultimo.fonte ?? q.fonte, datoDiTerzi: nil)
            eventi.append(EventoMercato(id: "distanza-\(q.isin)", tipo: .distanzaDalRiferimento,
                                        titolo: TestiMercato.titoloDistanza(nome: nome, distanza: distanza),
                                        dettaglio: TestiMercato.dettaglioDistanza(variazioneQuota: vq, riferimento: s, variazioneRiferimento: vs,
                                                                                  soglia: soglia, fonte: fonte),
                                        valore: distanza, soglia: soglia, data: ultimo.data, fonte: fonte, serieId: s.id, isin: q.isin,
                                        posizioneId: nil, toccati: toccati))
        }
        return eventi
    }

    /// Le cedole dei titoli in essere che arrivano entro i giorni scelti (oggi compreso).
    static func cedole(_ posizioni: [Posizione], impostazioni: ImpostazioniMercato, nomi: [String: String], oggi: Date,
                       cal: Calendar) -> [EventoMercato] {
        guard let soglia = impostazioni.giorniCedola else { return [] }
        var eventi: [EventoMercato] = []
        for p in posizioni {
            guard let c = p.cedola, nomi[p.clienteId] != nil, let d = c.prossimaData(da: oggi, cal: cal) else { continue }
            let giorni = cal.dateComponents([.day], from: cal.startOfDay(for: oggi), to: cal.startOfDay(for: d)).day ?? 0
            guard giorni >= 0, giorni <= soglia else { continue }
            let toccato = ClienteToccato(clienteId: p.clienteId, posizioni: [p.id], impatto: nil, perCanale: [:], canali: [p.canale])
            eventi.append(EventoMercato(id: "cedola-\(p.id)-\(timbro(d, cal: cal))", tipo: .cedolaInArrivo,
                                        titolo: TestiMercato.titoloCedola(nome: p.nome, giorni: giorni, data: d),
                                        dettaglio: TestiMercato.dettaglioCedola(c, data: d, soglia: soglia),
                                        valore: Double(giorni), soglia: Double(soglia), data: d, fonte: "Dato della posizione",
                                        serieId: nil, isin: p.isin.map(normalizzaISIN), posizioneId: p.id, toccati: [toccato]))
        }
        return eventi
    }

    /// Le voci raggruppate per cliente (solo clienti esistenti): impatto per canale, dal più toccato.
    private static func raggruppa(_ voci: [(posizione: Posizione, impatto: Double?)], nomi: [String: String]) -> [ClienteToccato] {
        var perCliente: [String: ClienteToccato] = [:]
        for v in voci where nomi[v.posizione.clienteId] != nil {
            let id = v.posizione.clienteId
            var t = perCliente[id] ?? ClienteToccato(clienteId: id, posizioni: [], impatto: nil, perCanale: [:], canali: [])
            t.posizioni.append(v.posizione.id)
            if let i = v.impatto {
                t.impatto = (t.impatto ?? 0) + i
                t.perCanale[v.posizione.canale, default: 0] += i
            }
            if !t.canali.contains(v.posizione.canale) { t.canali.append(v.posizione.canale) }
            perCliente[id] = t
        }
        return perCliente.values.map { t -> ClienteToccato in
            var x = t
            x.posizioni.sort()
            x.canali.sort { $0.rawValue < $1.rawValue }
            return x
        }.sorted { ordine($0, $1, nomi: nomi) }
    }

    private static func ordine(_ a: ClienteToccato, _ b: ClienteToccato, nomi: [String: String]) -> Bool {
        let ia = abs(a.impatto ?? 0), ib = abs(b.impatto ?? 0)
        if ia != ib { return ia > ib }
        let na = nomi[a.clienteId] ?? "", nb = nomi[b.clienteId] ?? ""
        if na != nb { return na.localizedCompare(nb) == .orderedAscending }
        return a.clienteId < b.clienteId
    }

    /// Il nome da mostrare per un ISIN: quello delle quote, altrimenti della prima posizione, altrimenti il codice.
    private static func nomeISIN(_ q: QuotaISIN, posizioni: [Posizione]) -> String {
        if !q.nome.trimmingCharacters(in: .whitespaces).isEmpty { return q.nome }
        return posizioni.map(\.nome).sorted().first ?? q.isin
    }

    private static func recente(_ data: Date, giorni: Int, oggi: Date, cal: Calendar) -> Bool {
        guard let limite = cal.date(byAdding: .day, value: -giorni, to: cal.startOfDay(for: oggi)) else { return false }
        return data >= limite && cal.startOfDay(for: data) <= cal.startOfDay(for: oggi)
    }

    /// «aaaammgg» del giorno: entra negli id stabili.
    static func timbro(_ d: Date, cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: - Avvisi

    /// L'id stabile di un avviso: per le condizioni che durano (calo, distanza) non cambia finché la condizione
    /// resta, così l'avviso non si ripete; per gli eventi singoli (variazione, cedola) porta il giorno del dato.
    static func idAvviso(_ e: EventoMercato, clienteId: String, cal: Calendar = .current) -> String {
        let riferimento = e.posizioneId ?? e.isin ?? e.serieId ?? e.id
        if e.tipo.condizione { return "\(e.tipo.rawValue)-\(clienteId)-\(riferimento)" }
        return "\(e.tipo.rawValue)-\(clienteId)-\(riferimento)-\(timbro(e.data, cal: cal))"
    }

    /// Gli avvisi aggiornati con gli eventi di oggi: un avviso che c'era tiene stato, nascita e «visto»; uno nuovo
    /// nasce «nuovo». Una condizione che non c'è più (rientrata) toglie il suo avviso: se torna, torna nuovo. Gli
    /// eventi singoli restano `giorniConservazioneAvvisi` giorni. Prima i nuovi, poi dal dato più recente.
    static func avvisi(eventi: [EventoMercato], esistenti: [AvvisoMercato], oggi: Date, cal: Calendar = .current) -> [AvvisoMercato] {
        let perId = Dictionary(esistenti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var risultato: [AvvisoMercato] = []
        var visti = Set<String>()
        for e in eventi {
            for t in e.toccati {
                let id = idAvviso(e, clienteId: t.clienteId, cal: cal)
                guard visti.insert(id).inserted else { continue }
                if var a = perId[id] {
                    a.titolo = e.titolo
                    a.dettaglio = e.dettaglio
                    a.valore = e.valore
                    a.soglia = e.soglia
                    a.dataDato = e.data
                    a.fonte = e.fonte
                    a.posizioni = t.posizioni
                    a.canale = t.canaleUnico
                    risultato.append(a)
                } else {
                    risultato.append(AvvisoMercato(id: id, tipo: e.tipo, clienteId: t.clienteId, posizioni: t.posizioni, isin: e.isin,
                                                   serieId: e.serieId, canale: t.canaleUnico, titolo: e.titolo, dettaglio: e.dettaglio,
                                                   valore: e.valore, soglia: e.soglia, dataDato: e.data, fonte: e.fonte, creatoIl: oggi))
                }
            }
        }
        let limite = cal.date(byAdding: .day, value: -RegoleMercato.giorniConservazioneAvvisi, to: cal.startOfDay(for: oggi)) ?? oggi
        for a in esistenti where !visti.contains(a.id) && !a.tipo.condizione && a.dataDato >= limite {
            visti.insert(a.id)
            risultato.append(a)
        }
        return risultato.sorted { a, b in
            if a.stato != b.stato { return a.stato == .nuovo }
            if a.dataDato != b.dataDato { return a.dataDato > b.dataDato }
            return a.id < b.id
        }
    }

    /// Segna un avviso come visto (resta nell'elenco).
    static func segnaVisto(_ id: String, in avvisi: inout [AvvisoMercato], il quando: Date) {
        guard let i = avvisi.firstIndex(where: { $0.id == id }), avvisi[i].stato == .nuovo else { return }
        avvisi[i].stato = .visto
        avvisi[i].vistoIl = quando
    }

    // MARK: - Valori per l'aggiornamento delle posizioni

    /// I valori nuovi delle posizioni in essere con un ISIN e quote importate più recenti del loro valore: quota ×
    /// numero di quote (di ogni posizione: lo stesso ISIN in due posizioni dà due valori diversi), con data e fonte.
    /// Senza il numero di quote il valore manca e la spiegazione lo dice.
    static func valoriDaQuote(posizioni: [Posizione], quote: [QuotaISIN], oggi: Date, cal: Calendar = .current) -> [ValoreDaMercato] {
        var perISIN: [String: QuotaISIN] = [:]
        for q in quote { perISIN[q.isin] = q }
        var elenco: [ValoreDaMercato] = []
        for p in posizioni where AggiornaValori.candidabile(p) {
            guard let isin = p.isin.map(normalizzaISIN), let q = perISIN[isin], let ultimo = valore(q.punti, al: oggi, cal: cal) else { continue }
            // Solo un valore più recente di quello che la posizione ha già
            if let d = p.dataValore, cal.startOfDay(for: ultimo.data) <= cal.startOfDay(for: d) { continue }
            let fonte = TestiMercato.citazione(origine: q.origine, fonte: ultimo.fonte ?? q.fonte, datoDiTerzi: nil)
            let n = p.numeroQuote.flatMap { $0 > 0 && $0.isFinite ? $0 : nil }
            elenco.append(ValoreDaMercato(posizioneId: p.id, clienteId: p.clienteId, nomePosizione: p.nome, isin: isin, quota: ultimo.valore,
                                          numeroQuote: n, valore: n.map { ($0 * ultimo.valore * 100).rounded() / 100 },
                                          data: ultimo.data, fonte: fonte, motivo: n == nil ? TestiMercato.mancaNumeroQuote : nil))
        }
        return elenco.sorted { $0.posizioneId < $1.posizioneId }
    }

    /// Le righe per `AggiornaValori.esiti` (id dall'1, nell'ordine dei valori).
    static func righeAggiornamento(_ valori: [ValoreDaMercato]) -> [AggiornaValori.Riga] {
        valori.enumerated().map { $0.element.riga(id: $0.offset + 1) }
    }
}
