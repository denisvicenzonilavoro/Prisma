import Foundation

/// Il prospetto del riesame annuale (per te, da portare all'incontro di revisione): l'ordine del
/// giorno, com'è andata ogni posizione, cosa scade, le occasioni dei prossimi 12 mesi, obiettivi, check-up,
/// proposte, scadenze di conformità e domande da fare. La Shell passa la conformità e le occasioni del cliente.
extension CompositoreProspetti {
    static let titoloRiesame = "Riesame annuale"

    /// Con `memoria` (giro 6) il prospetto apre l'ordine del giorno con quanto è cambiato dal riesame precedente e
    /// aggiunge la cronologia dei riesami; senza è identico a prima (Vera lo chiama senza).
    /// Con `valore` («Luce» giro 8, decisione 58) aggiunge «Quanto vale avermi accanto»: le cifre del lavoro fatto,
    /// solo qui, nel prospetto per il consulente.
    static func riesame(_ f: FonteVera, conformita: EsitoConformita? = nil, occasioni: [Occasione]? = nil,
                        memoria: MemoriaRiesame? = nil, valore: ValoreConsulente? = nil) -> ContenutoProspetto {
        let r = MotoreRiesame.calcola(f, conformita: conformita, occasioni: occasioni)
        let data: (Date) -> String = { Formati.dataBreve.string(from: $0) }
        var b: [BloccoProspetto] = []
        var n = 0
        func sezione(_ titolo: String) {
            n += 1
            b.append(.sezione(numero: String(format: "%02d", n), titolo: titolo))
        }

        let finanziarie = f.posizioni.filter { $0.stato == .inEssere && $0.area.proiettabile }
        b.append(.indicatori([
            IndicatoreProspetto(etichetta: "Ultimo incontro", valore: r.ultimoContatto.map(data) ?? "—",
                                nota: r.mesiDallUltimo.map { $0 == 0 ? "questo mese" : "\($0) \($0 == 1 ? "mese" : "mesi") fa" } ?? "nessuno registrato"),
            IndicatoreProspetto(etichetta: "Investimenti in essere", valore: Formati.euro(finanziarie.reduce(0) { $0 + $1.valore }),
                                nota: "\(finanziarie.count) posizioni · \(r.sottoAtteso.count) sotto l'atteso"),
            IndicatoreProspetto(etichetta: "Scadenze in 12 mesi", valore: "\(r.scadenze.count)",
                                nota: r.scadenze.first?.scadenza.map { "la prima il \(data($0))" } ?? "nessuna"),
            IndicatoreProspetto(etichetta: "Punti da trattare", valore: "\(r.punti.count)",
                                nota: "\(r.punti.filter { $0.priorita == .alta }.count) con priorità alta"),
        ]))
        if let a = r.prossimo {
            b.append(.avviso("Prossimo appuntamento già in agenda: «\(a.titolo)» il \(Formati.dataOra.string(from: a.inizio))."))
        } else if !r.dovuto {
            b.append(.avviso("L'ultimo incontro è di \(r.mesiDallUltimo ?? 0) mesi fa: il riesame annuale non è ancora dovuto, ma il quadro è aggiornato a oggi."))
        }

        sezione("Ordine del giorno")
        // Memoria del riesame: prima di tutto che cosa è cambiato dal riesame precedente
        if let m = memoria { b += bloccoCambiato(m) }
        if r.punti.isEmpty {
            b.append(.testo("Nessun punto da trattare: posizioni in linea, niente in scadenza, dati aggiornati."))
        } else {
            b.append(.tabella(TabellaProspetto(
                // Il tema e il canale in due colonne: il canale come etichetta, «—» se il punto riguarda il cliente.
                // Punto e Da sapere vanno a capo (righe ad altezza variabile, misurate dall'impaginatore)
                colonne: [ColonnaProspetto(titolo: "#", peso: 0.35), ColonnaProspetto(titolo: "Tema", peso: 1.05),
                          ColonnaProspetto(titolo: "Canale", peso: 0.95),
                          ColonnaProspetto(titolo: "Punto", peso: 2.1), ColonnaProspetto(titolo: "Da sapere", peso: 2.9),
                          ColonnaProspetto(titolo: "Priorità", peso: 0.75)],
                righe: r.punti.enumerated().map { i, p -> [CellaProspetto] in
                    let canale: CellaProspetto = p.canale.map { CellaProspetto.c($0) } ?? CellaProspetto.n("—")
                    let priorita: CellaProspetto = p.priorita == .alta ? CellaProspetto.f(p.priorita.nome) : CellaProspetto.n(p.priorita.nome)
                    return [CellaProspetto.n("\(i + 1)"), CellaProspetto.t(p.tema.nome), canale,
                            CellaProspetto.f(p.titolo), CellaProspetto.t(p.dettaglio), priorita]
                })))
        }

        sezione("Com'è andata rispetto all'atteso")
        if r.andamenti.isEmpty {
            b.append(.testo("Nessuna posizione ha ancora due valori rilevati: l'andamento si misura dallo storico. Aggiungi i valori passati dagli estratti conto (Documenti → «Registra il valore»)."))
        } else {
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Posizione", peso: 2.2), ColonnaProspetto(titolo: "Canale", peso: 1),
                          ColonnaProspetto(titolo: "Dal", peso: 0.9), ColonnaProspetto(titolo: "Rendimento", peso: 1.2, destra: true),
                          ColonnaProspetto(titolo: "Atteso netto", peso: 1, destra: true), ColonnaProspetto(titolo: "Giudizio", peso: 1.3)],
                righe: r.andamenti.map { p, a in
                    [.f(p.nome), .c(p.canale), .t(data(a.dal)), .t(TestiResoconto.rendimento(a)),
                     .t(a.attesoConfrontabile.map { CifreDoc.percento($0) } ?? "—"),
                     a.giudizio == .sotto ? .f(a.giudizio?.etichetta ?? "—") : .t(a.giudizio?.etichetta ?? "—")]
                })))
        }
        if !r.senzaStorico.isEmpty {
            b.append(.testo("Senza storico (un solo valore): \(r.senzaStorico.map(\.nome).joined(separator: ", "))."))
        }

        sezione("Cosa scade nei prossimi 12 mesi")
        if r.scadenze.isEmpty {
            b.append(.testo("Nessuna posizione in essere scade nei prossimi 12 mesi."))
        } else {
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Scadenza", peso: 1), ColonnaProspetto(titolo: "Posizione", peso: 2.3),
                          ColonnaProspetto(titolo: "Canale", peso: 1), ColonnaProspetto(titolo: "Valore", peso: 1.2, destra: true)],
                righe: r.scadenze.map { p in
                    [.t(p.scadenza.map(data) ?? "—"), .f(p.nome), .c(p.canale), p.area == .protezione ? .n("copertura da rinnovare") : .t(Formati.euro(p.valore))]
                })))
        }

        // Le occasioni dei prossimi 12 mesi (le ricorrenze sono rumore; il fisco ha il suo calendario)
        let occasioniAnno = r.occasioni.filter { $0.tipo != .scadenzaFiscale && $0.tipo != .ricorrenzaGestione }
        if !occasioniAnno.isEmpty {
            sezione("Le occasioni dei prossimi 12 mesi")
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Data", peso: 0.9), ColonnaProspetto(titolo: "Occasione", peso: 2.2),
                          ColonnaProspetto(titolo: "Canale", peso: 1), ColonnaProspetto(titolo: "Cosa cambia", peso: 3.9)],
                righe: occasioniAnno.map { o -> [CellaProspetto] in
                    let canale: CellaProspetto = o.canale.map { CellaProspetto.c($0) } ?? CellaProspetto.n("—")
                    return [CellaProspetto.t(data(o.data)), CellaProspetto.f(o.titolo), canale, CellaProspetto.t(o.dettaglio)]
                })))
            b.append(.nota(TestiOccasioni.avvertenza))
        }

        if !r.obiettivi.isEmpty {
            sezione("Obiettivi")
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Obiettivo", peso: 2.2), ColonnaProspetto(titolo: "Entro", peso: 1),
                          ColonnaProspetto(titolo: "Importo", peso: 1.1, destra: true), ColonnaProspetto(titolo: "Raggiunto", peso: 0.9, destra: true),
                          ColonnaProspetto(titolo: "Serve al mese", peso: 1.1, destra: true), ColonnaProspetto(titolo: "Versa oggi", peso: 1.1, destra: true)],
                righe: r.obiettivi.map { o, av in
                    [.f(o.titolo), .t(data(o.scadenza)), .t(Formati.euro(o.importo)), .t(Formati.percentuale((av.quota * 100).rounded())),
                     .t(av.versamentoNecessario.map(Formati.euro) ?? "—"), .t(av.versamentiAttivi > 0 ? Formati.euro(av.versamentiAttivi) : "—")]
                })))
        }

        let daRivedere = r.checkUp.daAffrontare
        if !daRivedere.isEmpty {
            sezione("Check-up: aree da rivedere")
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Area", peso: 1.6), ColonnaProspetto(titolo: "Semaforo", peso: 1),
                          ColonnaProspetto(titolo: "Oggi", peso: 1.4), ColonnaProspetto(titolo: "Cosa fare", peso: 3.6)],
                righe: daRivedere.map { i in [.f(i.titolo), i.semaforo == .rosso ? .f(i.semaforo.nome) : .t(i.semaforo.nome), .t(i.valore), .t(i.azione)] })))
        }

        if !r.proposte.isEmpty || !r.attivitaAperte.isEmpty {
            sezione("Proposte e attività aperte")
            if !r.proposte.isEmpty {
                b.append(.tabella(TabellaProspetto(
                    colonne: [ColonnaProspetto(titolo: "Proposta", peso: 2.4), ColonnaProspetto(titolo: "Canale", peso: 1),
                              ColonnaProspetto(titolo: "Esito", peso: 1), ColonnaProspetto(titolo: "Importo", peso: 1.1, destra: true)],
                    righe: r.proposte.map { p in
                        [.f(p.nome), .c(p.canale), .t((p.esito ?? .bozza).nome),
                         .t(p.versamentoIniziale > 0 ? Formati.euro(p.versamentoIniziale) : p.premioAnnuo > 0 ? "\(Formati.euro(p.premioAnnuo))/anno" : "—")]
                    })))
            }
            if !r.attivitaAperte.isEmpty {
                b.append(.voci(r.attivitaAperte.prefix(8).map { CampoVoce(etichetta: data($0.scadenza), valore: $0.titolo) }))
            }
        }

        if !r.fineAnno.scadenze.isEmpty {
            sezione("Calendario fiscale")
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Entro", peso: 0.9), ColonnaProspetto(titolo: "Scadenza", peso: 1.7),
                          ColonnaProspetto(titolo: "Cosa fare", peso: 4), ColonnaProspetto(titolo: "Importo", peso: 0.9, destra: true)],
                righe: r.fineAnno.scadenze.map { s in
                    [.t(data(s.data)), .f(s.titolo), .t(s.dettaglio), s.importo.map { .t(CifreDoc.euro($0)) } ?? .n("—")]
                })))
        }

        // Completezza dei dati: quali analisi del riesame girano su dati mancanti, stimati o vecchi
        let k = MotoreCompletezza.calcola(f)
        let daCompletare = k.daCompletare
        sezione("Dati per l'analisi")
        if daCompletare.isEmpty {
            b.append(.testo(TestiCompletezza.tuttoCompleto))
        } else {
            b.append(.avviso("Completi al \(k.percentuale)%: " + TestiCompletezza.riepilogo(k) + "."))
            let mostrate = daCompletare.prefix(MotoreCompletezza.massimoProspetto)
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Dato", peso: 2), ColonnaProspetto(titolo: "Stato", peso: 0.9),
                          ColonnaProspetto(titolo: "Cosa usa l'analisi", peso: 3.9), ColonnaProspetto(titolo: "Canale", peso: 0.9)],
                righe: mostrate.map { v -> [CellaProspetto] in
                    let stato: CellaProspetto = v.stato == .mancante ? CellaProspetto.f(v.stato.nome) : CellaProspetto.t(v.stato.nome)
                    let ipotesi: String = v.ipotesi.isEmpty ? "—" : v.ipotesi
                    let canale: CellaProspetto = v.canale.map { CellaProspetto.c($0) } ?? CellaProspetto.n("—")
                    return [CellaProspetto.f(v.titolo), stato, CellaProspetto.t(ipotesi), canale]
                })))
            if daCompletare.count > mostrate.count {
                b.append(.testo("…e altre \(daCompletare.count - mostrate.count): l'elenco completo è nella Panoramica del cliente."))
            }
        }

        // In regola: le scadenze di conformità dovute (le voci non richieste restano fuori)
        if let e = r.conformita, !e.dovute.isEmpty {
            sezione("In regola: scadenze di conformità")
            b.append(.tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Voce", peso: 2.2), ColonnaProspetto(titolo: "Canale", peso: 1.1),
                          ColonnaProspetto(titolo: "Registrata il", peso: 1), ColonnaProspetto(titolo: "Valida fino al", peso: 1),
                          ColonnaProspetto(titolo: "Stato", peso: 1.1)],
                righe: e.dovute.map { v -> [CellaProspetto] in
                    let canale: CellaProspetto = v.canale.map { CellaProspetto.c($0) } ?? CellaProspetto.n("Tutti")
                    let stato: CellaProspetto = v.stato <= .mancante
                        ? CellaProspetto.f(TestiConformita.etichetta(v)) : CellaProspetto.t(TestiConformita.etichetta(v))
                    return [CellaProspetto.f(TestiConformita.nome(v.tipo)), canale,
                            CellaProspetto.t(v.data.map(data) ?? "—"), CellaProspetto.t(v.scadenza.map(data) ?? "—"), stato]
                })))
            b.append(.nota(TestiConformita.avvertenza))
        }

        // Memoria del riesame: la fotografia di oggi e le ultime salvate, una riga per riesame
        if let m = memoria {
            sezione(TestiMemoria.titoloCronologia)
            b += bloccoCronologia(m)
        }

        // Quanto vale avermi accanto: per il consulente, con le stesse cifre e la stessa nota della Sala
        if let v = valore {
            sezione("Quanto vale avermi accanto")
            b += bloccoValore(v)
        }

        sezione("Domande da fare")
        let domande = r.domande + (memoria.map { TestiMemoria.domande($0.variazioni) } ?? [])
        b.append(.testo(domande.map { "• \($0)" }.joined(separator: "\n")))

        let metodoMemoria = memoria == nil ? "" : " " + TestiMemoria.metodo
        b.append(.nota("Metodo: andamento dallo storico dei valori di ogni posizione, al netto dei costi e tolti i versamenti, confrontato con il rendimento atteso meno i costi annui (in linea entro un punto all'anno). Scadenze delle posizioni in essere nei prossimi 12 mesi, con il valore di oggi prima delle imposte. Obiettivi con le posizioni collegate; aree del check-up dai dati del dossier e dall'Analisi 360. Valori da aggiornare: posizioni con il valore fermo da più di un anno. Documento ad uso del consulente per preparare l'incontro." + metodoMemoria))

        let precedente = memoria?.precedente.map { " · riesame precedente il \(Formati.dataEstesa.string(from: $0.data))" } ?? ""
        return ContenutoProspetto(occhiello: "Prospetto di dettaglio · Riesame annuale", titolo: "\(titoloRiesame) di \(f.cliente.nome)",
                                  sottotitolo: "Preparato il \(Formati.dataEstesa.string(from: f.oggi))" + (r.ultimoContatto.map { " · ultimo incontro il \(Formati.dataEstesa.string(from: $0))" } ?? "") + precedente,
                                  cliente: f.cliente.nome, data: f.oggi, blocchi: b)
    }

    /// Le voci del valore del lavoro con il cliente (o «presto per misurare»), il compenso per canale, la nota.
    static func bloccoValore(_ v: ValoreConsulente) -> [BloccoProspetto] {
        var b: [BloccoProspetto] = []
        guard !v.presto, let totale = v.totale else {
            b.append(.testo("Presto per misurare: il rapporto è cominciato il \(Formati.dataBreve.string(from: v.dal)) o non ci sono ancora raccomandazioni accettate."))
            return b
        }
        b.append(.indicatori([
            IndicatoreProspetto(etichetta: "Valore stimato", valore: (v.parziale ? "almeno " : "") + Formati.euro(totale),
                                nota: "dal \(Formati.dataBreve.string(from: v.dal))"),
            IndicatoreProspetto(etichetta: "Compenso", valore: Formati.euro(v.compenso),
                                nota: v.provvigioniNonStimate ? "provvigioni Alleanza non stimate" : "parcelle e provvigioni stimate"),
            IndicatoreProspetto(etichetta: v.rapportoSoloParcelle ? "Per euro di parcella" : "Per euro di compenso",
                                valore: v.rapporto.map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: ",") } ?? "—",
                                nota: v.rapportoSoloParcelle ? "valore del canale indipendente" : "euro di valore"),
            IndicatoreProspetto(etichetta: "Protetto (caso morte)", valore: v.protetto.map(Formati.euro) ?? "—", nota: "non entra nel totale"),
        ]))
        b.append(.tabella(TabellaProspetto(
            colonne: [ColonnaProspetto(titolo: "Voce", peso: 1.6), ColonnaProspetto(titolo: "Cifra", peso: 1, destra: true),
                      ColonnaProspetto(titolo: "Alleanza", peso: 1, destra: true), ColonnaProspetto(titolo: "Indipendente", peso: 1, destra: true),
                      ColonnaProspetto(titolo: "Nota", peso: 2.6)],
            righe: v.voci.map { x -> [CellaProspetto] in
                [.f(x.tipo.titolo), .t(x.totale.map(Formati.euro) ?? "—"),
                 .t(x.perCanale[.alleanza].map(Formati.euro) ?? "—"), .t(x.perCanale[.indipendente].map(Formati.euro) ?? "—"),
                 .t(x.motivoAssente ?? (x.stima ? "stima" : "—"))]
            })))
        b.append(.nota("Contano solo le posizioni nate da raccomandazioni accettate dopo l'inizio del rapporto. Tasse con il reddito di oggi (stima); costi tagliati sul valore di oggi della nuova posizione; alternativa dal track record (stima). Documento ad uso del consulente: non è una comunicazione al cliente."))
        return b
    }

    /// In testa all'ordine del giorno: che cosa è cambiato dal riesame precedente (tabella con il canale come
    /// etichetta di stampa), nessuna variazione, oppure la prima fotografia.
    private static func bloccoCambiato(_ m: MemoriaRiesame) -> [BloccoProspetto] {
        guard let p = m.precedente else { return [.testo(TestiMemoria.primaFotografia)] }
        guard !m.variazioni.isEmpty, let testo = TestiMemoria.testoProspetto(m: m) else {
            return [.testo(TestiMemoria.nessunaVariazione(data: p.data))]
        }
        let righe: [[CellaProspetto]] = m.variazioni.map { v in
            let tema = CellaProspetto.t(v.tema.nome)
            let canale: CellaProspetto = v.canale.map { CellaProspetto.c($0) } ?? CellaProspetto.n(TestiMemoria.vuoto)
            let frase: CellaProspetto = v.verso == .peggio ? CellaProspetto.f(v.testo) : CellaProspetto.t(v.testo)
            let verso: CellaProspetto
            switch v.verso {
            case .meglio: verso = CellaProspetto.t("meglio")
            case .peggio: verso = CellaProspetto.f("peggio")
            case .neutro: verso = CellaProspetto.n(TestiMemoria.vuoto)
            }
            return [tema, canale, frase, CellaProspetto.n(v.prima), CellaProspetto.t(v.oggi), verso]
        }
        return [
            .testo(testo),
            .tabella(TabellaProspetto(
                colonne: [ColonnaProspetto(titolo: "Tema", peso: 1.1), ColonnaProspetto(titolo: "Canale", peso: 0.95),
                          ColonnaProspetto(titolo: "Cosa è cambiato", peso: 2.25),
                          ColonnaProspetto(titolo: "Prima", peso: 1.3), ColonnaProspetto(titolo: "Oggi", peso: 1.3),
                          ColonnaProspetto(titolo: "Verso", peso: 0.8)],
                righe: righe)),
        ]
    }

    /// «Cronologia dei riesami»: la riga «Oggi» (non salvata, evidenziata) e le ultime fotografie salvate, con il
    /// patrimonio sempre diviso per canale. Senza fotografie salvate un testo (la riga «Oggi» da sola non dice niente).
    private static func bloccoCronologia(_ m: MemoriaRiesame) -> [BloccoProspetto] {
        guard !m.cronologia.isEmpty else { return [.testo(TestiMemoria.nessunaFotografia)] }
        func riga(_ f: FotografiaRiesame, data: String, forte: Bool) -> [CellaProspetto] {
            let cella: (String) -> CellaProspetto = { forte ? CellaProspetto.f($0) : CellaProspetto.t($0) }
            return [cella(data),
                    cella(TestiMemoria.propensioneBreve(f.propensione)),
                    cella(TestiMemoria.euroAlMese(f.divarioPensione)),
                    cella(TestiMemoria.euro(f.scopertoCasoMorte)),
                    cella(TestiMemoria.euro(f.patrimonioAlleanza)),
                    cella(TestiMemoria.euro(f.patrimonioIndipendente)),
                    cella(TestiMemoria.semafori(f: f)),
                    cella(f.completezza.map { "\($0)%" } ?? TestiMemoria.vuoto)]
        }
        let salvate = m.cronologia.prefix(MotoreMemoria.massimoCronologiaProspetto)
        var righe: [[CellaProspetto]] = [riga(m.attuale, data: "Oggi", forte: true)]
        for f in salvate { righe.append(riga(f, data: Formati.dataBreve.string(from: f.data), forte: false)) }
        return [.tabella(TabellaProspetto(
            colonne: [ColonnaProspetto(titolo: "Data", peso: 1), ColonnaProspetto(titolo: "Propensione", peso: 1),
                      ColonnaProspetto(titolo: "Divario pensione", peso: 1.1, destra: true),
                      ColonnaProspetto(titolo: "Scoperto caso morte", peso: 1.2, destra: true),
                      ColonnaProspetto(titolo: "Alleanza", peso: 1.1, destra: true),
                      ColonnaProspetto(titolo: "Indipendente", peso: 1.1, destra: true),
                      ColonnaProspetto(titolo: "Semafori", peso: 1.3), ColonnaProspetto(titolo: "Dati", peso: 0.7, destra: true)],
            righe: righe,
            evidenzia: [0]))]
    }
}
