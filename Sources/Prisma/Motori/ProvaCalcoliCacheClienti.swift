import Foundation

/// Prove delle cache dei motori per cliente (giro 0 di «Prisma istantaneo», tappa 4; CacheClienti.swift): nessuna cache
/// resta vecchia. Cliente per cliente:
/// - cambiando una posizione di un cliente si rifà solo lui, e le sue cifre sono uguali a quelle calcolate da zero su
///   uno stato nuovo con lo stesso archivio (anche il radar e le attenzioni di tutti, rimessi insieme dalle voci);
/// - cambiando la scheda di un cliente, un suo obiettivo o la sua Analisi 360: solo lui;
/// - un cliente nuovo: solo lui;
/// - cambiando le impostazioni dei calcoli (o il catalogo dei prodotti): rifatti tutti;
/// - cambiando l'aspetto o una nota: nessuno.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliCacheClienti {
    static func esegui(_ verifica: VerificaCalcoli) {
        let s = StatoShell(persistente: false)
        let ids = s.dati.clienti.map(\.id)
        guard ids.count >= 3, let primo = ids.first else {
            verifica.vero("Cache per cliente: clienti di prova", false)
            return
        }
        // Un cliente con posizioni (quello che cambia) e uno con un obiettivo
        let conPosizioni = ids.first { id in s.dati.posizioni.contains { $0.clienteId == id && $0.stato == .inEssere } } ?? primo
        tutteLeCifre(s)
        s.cacheClienti.azzeraConteggi()

        // 1. Senza cambi: nessuno si rifà
        tutteLeCifre(s)
        verifica("Cache per cliente: senza cambi non si rifà nessuno", Double(rifatti(s).count), 0)

        // 2. Una posizione di un cliente
        if let i = s.dati.posizioni.firstIndex(where: { $0.clienteId == conPosizioni && $0.stato == .inEssere }) {
            s.dati.posizioni[i].controvalore = s.dati.posizioni[i].valore + 12_345
        }
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: cambiata una posizione, rifatto solo il suo cliente (\(rifatti(s).sorted()))",
                      rifatti(s) == [conPosizioni])
        uguali(s, verifica, "dopo la posizione")

        // 3. La scheda di un altro cliente
        s.cacheClienti.azzeraConteggi()
        let altro = ids.first { $0 != conPosizioni } ?? primo
        if let i = s.dati.clienti.firstIndex(where: { $0.id == altro }) { s.dati.clienti[i].nome += " (prova della cache)" }
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: cambiata la scheda, rifatto solo quel cliente (\(rifatti(s).sorted()))",
                      rifatti(s) == [altro])
        uguali(s, verifica, "dopo la scheda")

        // 4. Un obiettivo e l'Analisi 360 di un cliente
        s.cacheClienti.azzeraConteggi()
        if let i = s.dati.obiettivi.indices.first {
            let id = s.dati.obiettivi[i].clienteId
            s.dati.obiettivi[i].importo += 1_000
            tutteLeCifre(s)
            verifica.vero("Cache per cliente: cambiato un obiettivo, rifatto solo il suo cliente (\(rifatti(s).sorted()))",
                          rifatti(s) == [id])
            uguali(s, verifica, "dopo l'obiettivo")
        }
        s.cacheClienti.azzeraConteggi()
        let terzo = ids[2]
        var a = s.analisi360(terzo)
        a.note += " (prova della cache)"
        s.dati.analisi[terzo] = a
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: salvata l'Analisi 360, rifatto solo quel cliente (\(rifatti(s).sorted()))",
                      rifatti(s) == [terzo])
        uguali(s, verifica, "dopo l'Analisi 360")

        // 5. Un cliente nuovo
        s.cacheClienti.azzeraConteggi()
        var nuovo = Cliente.nuovo(tinta: .verde)
        nuovo.nome = "Cliente della prova della cache"
        s.dati.clienti.append(nuovo)
        s.dati.posizioni.append(AiutiProva.posizione("Fondo della prova", .investimento, 50_000) { $0.clienteId = nuovo.id })
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: un cliente nuovo, fatto solo lui (\(rifatti(s).sorted()))", rifatti(s) == [nuovo.id])
        uguali(s, verifica, "dopo il cliente nuovo")

        // 6. Le impostazioni dei calcoli: tutti
        s.cacheClienti.azzeraConteggi()
        s.dati.impostazioni.tolleranzaRadar = (s.dati.impostazioni.tolleranzaRadar ?? 5) + 1
        tutteLeCifre(s)
        let tutti = Set(s.dati.clienti.map(\.id))
        verifica.vero("Cache per cliente: cambiate le impostazioni dei calcoli, rifatti tutti", rifatti(s) == tutti)
        uguali(s, verifica, "dopo le impostazioni")

        // 7. Il catalogo dei prodotti: tutti
        s.cacheClienti.azzeraConteggi()
        if let i = s.dati.prodotti.indices.first { s.dati.prodotti[i].costoAnnuo = (s.dati.prodotti[i].costoAnnuo ?? 1) + 0.1 }
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: cambiato il catalogo, rifatti tutti", rifatti(s) == tutti)
        uguali(s, verifica, "dopo il catalogo")

        // 8. Aspetto e note: nessuno
        s.cacheClienti.azzeraConteggi()
        s.dati.impostazioni.aspetto = s.dati.impostazioni.aspetto == .scuro ? .chiaro : .scuro
        s.dati.note.append(Nota(clienteId: primo, titolo: "Prova della cache", testo: "Un tasto"))
        tutteLeCifre(s)
        verifica("Cache per cliente: aspetto e note non rifanno nessuno", Double(rifatti(s).count), 0)

        // 9. Un archivio sostituito (ripristino): tutti
        s.cacheClienti.azzeraConteggi()
        var d = s.dati.istantanea
        if let i = d.posizioni.indices.first { d.posizioni[i].controvalore = d.posizioni[i].valore + 1 }
        s.dati.carica(d)
        tutteLeCifre(s)
        verifica.vero("Cache per cliente: archivio sostituito, rifatti tutti", rifatti(s) == tutti)
        uguali(s, verifica, "dopo il ripristino")

        // 9b. Un cliente eliminato: la sua voce se ne va subito, senza aspettare un cambio del comune
        if let via = s.dati.clienti.last?.id {
            tutteLeCifre(s)
            s.dati.clienti.removeAll { $0.id == via }
            verifica.vero("Cache per cliente: cliente eliminato, la sua voce non resta in memoria", s.cacheClienti.voci[via] == nil)
            tutteLeCifre(s)
            uguali(s, verifica, "dopo il cliente eliminato")
        }
        // 9c. Uno eliminato e uno nuovo insieme (stesso numero di clienti), poi le impostazioni dei calcoli: nessuna
        // voce orfana
        if let via = s.dati.clienti.last?.id {
            var nuovo2 = Cliente.nuovo(tinta: .blu)
            nuovo2.nome = "Altro cliente della prova della cache"
            var elenco = s.dati.clienti
            elenco.removeAll { $0.id == via }
            elenco.append(nuovo2)
            s.dati.clienti = elenco
            tutteLeCifre(s)
            s.dati.impostazioni.tolleranzaRadar = (s.dati.impostazioni.tolleranzaRadar ?? 5) + 1
            tutteLeCifre(s)
            let presenti = Set(s.dati.clienti.map(\.id))
            verifica.vero("Cache per cliente: eliminato e aggiunto insieme, nessuna voce orfana",
                          s.cacheClienti.voci.keys.allSatisfy { presenti.contains($0) } && s.cacheClienti.voci[via] == nil)
            uguali(s, verifica, "dopo eliminato e aggiunto")
        }

        // 11. Il radar in sottofondo: con molti clienti da rifare si mostra l'ultimo radar, poi arriva quello nuovo,
        // uguale al calcolo da zero
        radarInSottofondo(verifica)

        // 10. Le attribuzioni di DatiVivi: aggiunte, tolte, spostamenti
        let p1 = AiutiProva.posizione("A", .investimento, 1) { $0.clienteId = "a" }
        let p2 = AiutiProva.posizione("B", .investimento, 1) { $0.clienteId = "b" }
        let p3 = AiutiProva.posizione("C", .investimento, 1) { $0.clienteId = "c" }
        verifica.vero("Cache per cliente: tolta una posizione, toccato il suo cliente",
                      DatiVivi.clientiToccati([p1, p2, p3], [p1, p3], \.clienteId) == ["b"])
        verifica.vero("Cache per cliente: aggiunta in fondo, toccato il suo cliente",
                      DatiVivi.clientiToccati([p1, p2], [p1, p2, p3], \.clienteId) == ["c"])
        verifica.vero("Cache per cliente: scambio di due posizioni, toccati tutti e due",
                      DatiVivi.clientiToccati([p1, p2, p3], [p1, p3, p2], \.clienteId) == ["b", "c"])
        var p2b = p2
        p2b.clienteId = "a"
        verifica.vero("Cache per cliente: posizione passata a un altro cliente, toccati il vecchio e il nuovo",
                      DatiVivi.clientiToccati([p1, p2, p3], [p1, p2b, p3], \.clienteId) == ["a", "b"])
    }

    private static func radarInSottofondo(_ verifica: VerificaCalcoli) {
        guard let molti = try? ProvaCarico.moltiplica(DatiPrisma.demo(), copie: 8) else {
            verifica.vero("Cache per cliente: archivio con molti clienti per il radar in sottofondo", false)
            return
        }
        let s = StatoShell(persistente: false)
        s.dati.carica(molti)
        s.cacheClienti.sottofondoPerProva = true
        let primo = s.radarPortafoglio()
        verifica.vero("Radar in sottofondo: il primo radar si calcola subito (non c'è un radar da mostrare intanto)",
                      primo == MotoreRadar.calcola(s.dati.istantanea))
        // Il catalogo cambia per tutti: tutte le voci da rifare
        if let i = s.dati.prodotti.indices.first { s.dati.prodotti[i].costoAnnuo = (s.dati.prodotti[i].costoAnnuo ?? 1) + 0.5 }
        // E un modello diverso per un cliente: il radar nuovo deve essere davvero diverso da quello di prima
        if let i = s.dati.clienti.firstIndex(where: { $0.modelloId != nil }),
           let altro = s.dati.portafogliModello.first(where: { $0.id != s.dati.clienti[i].modelloId }) {
            s.dati.clienti[i].modelloId = altro.id
        }
        let arriviPrima = s.cacheClienti.arrivi
        let intanto = s.radarPortafoglio()
        verifica.vero("Radar in sottofondo: intanto si mostra l'ultimo radar valido", intanto.voci.count == primo.voci.count)
        verifica.vero("Radar in sottofondo: il calcolo è partito", s.cacheClienti.radarInCorso != nil)
        // Il body che si rivaluta mentre il calcolo è in corso (un clic, l'aspetto…) non lo fa ripartire da zero
        let partenze = s.cacheClienti.partenzeRadar
        for _ in 0..<3 { _ = s.radarPortafoglio() }
        verifica.vero("Radar in sottofondo: rivalutare il radar non riparte da zero (\(s.cacheClienti.partenzeRadar - partenze) partenze in più)",
                      s.cacheClienti.partenzeRadar == partenze && s.cacheClienti.radarInCorso != nil)
        let limite = Date().addingTimeInterval(60)
        while s.cacheClienti.arrivi == arriviPrima, Date() < limite {
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        verifica.vero("Radar in sottofondo: le voci nuove sono arrivate", s.cacheClienti.arrivi > arriviPrima)
        let dopo = s.radarPortafoglio()
        verifica.vero("Radar in sottofondo: il radar arrivato è uguale al calcolo da zero", dopo == MotoreRadar.calcola(s.dati.istantanea))
        verifica.vero("Radar in sottofondo: e diverso da quello di prima (un modello cambiato)", dopo != primo)

        // Un archivio sostituito (ripristino) con gli stessi id: il radar di prima non si mostra nemmeno per un momento
        var d = s.dati.istantanea
        if let i = d.prodotti.indices.first { d.prodotti[i].costoAnnuo = (d.prodotti[i].costoAnnuo ?? 1) + 0.5 }
        if let i = d.clienti.firstIndex(where: { $0.modelloId != nil }) { d.clienti[i].modelloId = nil }
        // Un calcolo in corso al momento del ripristino si annulla
        if let i = s.dati.prodotti.indices.first { s.dati.prodotti[i].costoAnnuo = (s.dati.prodotti[i].costoAnnuo ?? 1) + 0.25 }
        _ = s.radarPortafoglio()
        let inCorsoPrima = s.cacheClienti.radarInCorso != nil
        s.dati.carica(d)
        verifica.vero("Radar in sottofondo: ripristino, l'ultimo radar e il calcolo in corso si dimenticano",
                      inCorsoPrima && s.cacheClienti.ultimoRadar == nil && s.cacheClienti.radarInCorso == nil)
        let ripristinato = s.radarPortafoglio()
        verifica.vero("Radar in sottofondo: dopo il ripristino il radar è subito quello dell'archivio nuovo",
                      ripristinato == MotoreRadar.calcola(s.dati.istantanea) && s.cacheClienti.radarInCorso == nil)
    }

    /// I clienti rifatti dall'ultimo azzeramento dei conteggi.
    private static func rifatti(_ s: StatoShell) -> Set<String> {
        Set(s.cacheClienti.rifatte.filter { $0.value > 0 }.keys)
    }

    /// Chiede tutte le cifre per cliente, più il radar e le attenzioni di tutti.
    private static func tutteLeCifre(_ s: StatoShell) {
        for c in s.dati.clienti {
            _ = s.riepilogoPosizioniCliente(c.id)
            _ = s.analisiDossier(c.id)
            _ = s.coerenzaCliente(c)
            _ = s.fiscoPolizze(c)
            _ = s.conformitaCliente(c.id)
            _ = s.completezzaCliente(c.id)
            _ = s.bisogniRilevati(c.id)
            _ = s.andamentoCliente(c.id)
            _ = s.aree360(c.id)
            _ = s.avanzamentiObiettivi(c.id)
        }
        _ = s.radarPortafoglio()
        _ = s.mossaDelGiorno()
        _ = s.portafoglioComune()
    }

    /// Le cifre in cache uguali a quelle di uno stato nuovo con lo stesso archivio (calcolo da zero).
    private static func uguali(_ s: StatoShell, _ verifica: VerificaCalcoli, _ quando: String) {
        let zero = StatoShell(persistente: false)
        zero.dati.carica(s.dati.istantanea)
        var diversi: [String] = []
        for c in s.dati.clienti {
            let a = s.riepilogoPosizioniCliente(c.id), b = zero.riepilogoPosizioniCliente(c.id)
            if a.patrimonioNetto != b.patrimonioNetto || a.attivita != b.attivita || a.premiAnnui != b.premiAnnui
                || a.proposteAperte != b.proposteAperte {
                diversi.append("\(c.id): riepilogo")
            }
            if s.aree360(c.id) != zero.aree360(c.id) { diversi.append("\(c.id): aree di Analisi 360") }
            // L'andamento porta le date di adesso (giorni della storia e della stima): si confrontano le cifre
            let x = s.andamentoCliente(c.id), y = zero.andamentoCliente(c.id)
            if x.inEssere != y.inEssere || x.conProposte != y.conProposte || x.proposteAperte != y.proposteAperte
                || x.valoreProposte != y.valoreProposte || x.storia != y.storia {
                diversi.append("\(c.id): andamento")
            }
            if s.bisogniRilevati(c.id) != zero.bisogniRilevati(c.id) { diversi.append("\(c.id): bisogni") }
            if s.completezzaCliente(c.id)?.percentuale != zero.completezzaCliente(c.id)?.percentuale {
                diversi.append("\(c.id): completezza")
            }
            if s.coerenzaCliente(c).oggi.patrimonioFinanziario != zero.coerenzaCliente(c).oggi.patrimonioFinanziario {
                diversi.append("\(c.id): coerenza")
            }
            if s.conformitaCliente(c.id)?.voci.map(\.stato) != zero.conformitaCliente(c.id)?.voci.map(\.stato) {
                diversi.append("\(c.id): conformità")
            }
            if s.obiettiviCliente(c.id) != zero.obiettiviCliente(c.id) { diversi.append("\(c.id): obiettivi") }
            let av = s.avanzamentiObiettivi(c.id), bv = zero.avanzamentiObiettivi(c.id)
            if av.keys.sorted() != bv.keys.sorted()
                || av.contains(where: { k, x in bv[k].map { $0.accantonato != x.accantonato || $0.mancante != x.mancante
                    || $0.versamentoNecessario != x.versamentoNecessario } ?? true }) {
                diversi.append("\(c.id): avanzamento degli obiettivi")
            }
        }
        if s.mossaDelGiorno() != zero.mossaDelGiorno() { diversi.append("mossa del giorno") }
        if s.radarPortafoglio() != MotoreRadar.calcola(s.dati.istantanea) { diversi.append("radar") }
        if s.portafoglioComune().attenzioni.map(\.id) != zero.portafoglioComune().attenzioni.map(\.id) {
            diversi.append("attenzioni")
        }
        verifica.vero("Cache per cliente: \(quando), cifre uguali al calcolo da zero\(diversi.isEmpty ? "" : " (\(diversi.joined(separator: ", ")))")",
                      diversi.isEmpty)
    }
}
