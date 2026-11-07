import CoreGraphics
import Foundation

/// Prove di ciò che Studio › Track record mostra (`PresentazioneTrackRecord`, chiamate da `ProvaCalcoli.esegui()`, cioè da
/// `Prisma --prova-calcoli`): la scala comune delle due linee, l'ordine dell'elenco, la pillola «Rimandata» e le linee
/// di un'accettata. Casi costruiti a mano; l'indice «indice-prova» è un RIFERIMENTO DI PROVA scritto qui.
enum ProvaCalcoliPresentazioneTrack {
    static func esegui(_ verifica: VerificaCalcoli) {
        func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }

        // 1. Normalizzazione: scala comune, punti tra 0 e 1, x in proporzione alle date
        let date = [d(2024, 1, 1), d(2025, 1, 1), d(2026, 1, 1)]
        let n = PresentazioneTrackRecord.normalizza([100, 110, 120], [100, 105, 108], date: date)
        let tutti = n.a + n.b
        verifica.vero("Track record (vista): punti tra 0 e 1", tutti.allSatisfy { $0.x >= 0 && $0.x <= 1 && $0.y >= 0 && $0.y <= 1 })
        verifica.vero("Track record (vista): stessa scala per le due linee", n.a[0].y == n.b[0].y && n.a[2].y > n.b[2].y)
        verifica("Track record (vista): x in proporzione alle date", Double(n.a[1].x), 366.0 / 731.0, tolleranza: 1e-6)
        verifica.vero("Track record (vista): margine sopra e sotto", n.a[2].y < 1 && n.a[0].y > 0)
        let costante = PresentazioneTrackRecord.normalizza([50, 50], [], date: [d(2025, 1, 1), d(2026, 1, 1)])
        verifica.vero("Track record (vista): serie costante a metà altezza",
                      costante.a.count == 2 && costante.a.allSatisfy { abs($0.y - 0.5) < 1e-9 } && costante.b.isEmpty)
        let senza = PresentazioneTrackRecord.normalizza([1, 2, 3], [], date: [])
        verifica.vero("Track record (vista): senza date x equidistanti", senza.a.map { $0.x } == [0, 0.5, 1])
        verifica.vero("Track record (vista): nessun valore, nessun punto",
                      PresentazioneTrackRecord.normalizza([], [], date: []).a.isEmpty)

        // 2. Ordine: accettate per differenza decrescente, poi da misurare, in attesa, rifiutate; a parità la più recente
        func racc(_ id: String, _ data: Date, _ scelta: SceltaCliente) -> Raccomandazione {
            var r = Raccomandazione(id: id, data: data, clienteId: "anna", posizioneId: "p-\(id)", canale: .indipendente,
                                    area: .investimento, proposta: "Proposta \(id)", motivazione: "",
                                    cifre: CifreRaccomandazione(), alternativa: .nessuna)
            r.registraScelta(scelta, il: data)
            return r
        }
        func scarto(_ x: Double) -> TrackRecord.Misura {
            .scarto(TrackRecord.Scarto(differenza: x, valoreEffettivo: 10_000 + x, valoreAlternativa: 10_000,
                                       tassoEffettivo: nil, tassoAlternativa: nil, puntiAnnui: nil, anniStimati: [], stima: true))
        }
        func voce(_ r: Raccomandazione, _ m: TrackRecord.Misura, posizione: Posizione? = nil) -> TrackRecord.Voce {
            TrackRecord.Voce(raccomandazione: r, posizione: posizione, daAlmeno12Mesi: false, inEssere: true, misura: m)
        }
        let voci = [
            voce(racc("rifiutata", d(2026, 5, 1), .rifiutata), .nonAccettata),
            voce(racc("piccola", d(2025, 1, 1), .accettata), scarto(200)),
            voce(racc("attesa", d(2026, 6, 1), .inAttesa), .nonAccettata),
            voce(racc("da-misurare", d(2026, 2, 1), .accettata), .pochiDati),
            voce(racc("grande", d(2024, 1, 1), .accettata), scarto(4_000)),
            voce(racc("negativa", d(2025, 3, 1), .accettata), scarto(-1_200)),
        ]
        let ordine = PresentazioneTrackRecord.ordinate(voci).map { $0.id }
        verifica.vero("Track record (vista): ordine dell'elenco",
                      ordine == ["grande", "piccola", "negativa", "da-misurare", "attesa", "rifiutata"])

        // 3. Pillola: «in attesa» con la proposta rimandata diventa «Rimandata», con la data in cui riprenderla
        var rimandata = Posizione(clienteId: "anna", canale: .alleanza, stato: .proposta, area: .previdenza, nome: "Rendita")
        rimandata.esito = .rimandata
        var seguito = SeguitoProposta()
        seguito.riprendereIl = d(2027, 1, 15)
        rimandata.seguito = seguito
        let vRimandata = voce(racc("rim", d(2026, 6, 1), .inAttesa), .nonAccettata, posizione: rimandata)
        verifica.vero("Track record (vista): rimandata con la data", PresentazioneTrackRecord.esito(vRimandata) == .rimandata(riprendereIl: d(2027, 1, 15)))
        verifica.vero("Track record (vista): in attesa senza proposta rimandata", PresentazioneTrackRecord.esito(voci[2]) == .inAttesa)

        // 4. Copertura accettata: il capitale assicurato al posto della differenza
        var copertura = Posizione(clienteId: "anna", canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Temporanea")
        copertura.capitaleAssicurato = 200_000
        let rCopertura = Raccomandazione(id: "cop", data: d(2025, 1, 1), clienteId: "anna", posizioneId: copertura.id,
                                         canale: .alleanza, area: .protezione, proposta: "Temporanea", motivazione: "",
                                         cifre: CifreRaccomandazione(), alternativa: .nessuna)
        var accettataCopertura = rCopertura
        accettataCopertura.registraScelta(.accettata, il: d(2025, 1, 10))
        verifica("Track record (vista): capitale assicurato della copertura",
                 PresentazioneTrackRecord.capitaleAssicurato(voce(accettataCopertura, .senzaRiferimento, posizione: copertura)) ?? -1, 200_000)
        verifica.vero("Track record (vista): una copertura non accettata non mostra il capitale",
                      PresentazioneTrackRecord.capitaleAssicurato(voce(rCopertura, .nonAccettata, posizione: copertura)) == nil)

        // 5. Le linee di un'accettata: valori rilevati e alternativa al ritmo dell'indice di prova (+1% l'anno)
        let indice = "indice-prova"
        var riferimenti = RiferimentiRendimento()
        riferimenti.indici = [IndiceRiferimento(id: indice, nome: "Indice di prova")]
        riferimenti.valori = [2024, 2025, 2026].map { ValoreRiferimento(serie: indice, anno: $0, valore: 1.0) }
        let tabella = TabellaRiferimenti(riferimenti)
        let p = AiutiProva.posizione("ETF", .investimento, 10_800) { q in
            q.id = "p-linee"
            q.decorrenza = d(2024, 1, 1)
            q.dataValore = d(2026, 1, 1)
            q.totaleVersato = 10_000
            q.rilevazioni = [Rilevazione(data: d(2024, 1, 1), controvalore: 10_000, versato: 10_000),
                             Rilevazione(data: d(2025, 1, 1), controvalore: 10_300, versato: 10_000)]
        }
        let alternativa = AlternativaRaccomandazione(tipo: .riferimento, descrizione: "Lo stesso capitale al ritmo dell'indice di prova",
                                                     serieRiferimento: indice, ricavata: false)
        var rLinee = Raccomandazione(id: "linee", data: d(2023, 12, 15), clienteId: "anna", posizioneId: p.id, canale: .indipendente,
                                     area: .investimento, proposta: "ETF", motivazione: "", cifre: CifreRaccomandazione(),
                                     alternativa: alternativa)
        rLinee.registraScelta(.accettata, il: d(2024, 1, 1))
        if let l = PresentazioneTrackRecord.linee(voce(rLinee, .pochiDati, posizione: p), tabella: tabella) {
            verifica.vero("Track record (vista): tre punti per linea", l.proposta.count == 3 && l.alternativa.count == 3)
            verifica.vero("Track record (vista): le linee partono insieme e la proposta finisce sopra",
                          l.proposta[0] == l.alternativa[0] && l.proposta[2].y > l.alternativa[2].y)
        } else {
            verifica.vero("Track record (vista): linee di un'accettata", false)
        }
        verifica.vero("Track record (vista): una rifiutata non ha linee",
                      PresentazioneTrackRecord.linee(voce(racc("no", d(2025, 1, 1), .rifiutata), .nonAccettata, posizione: p),
                                                     tabella: tabella) == nil)
    }
}
