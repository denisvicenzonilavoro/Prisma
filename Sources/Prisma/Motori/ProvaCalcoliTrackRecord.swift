import Foundation

/// Prove del track record (chiamate da `ProvaCalcoli.esegui()`, cioè da `Prisma --prova-calcoli`): casi costruiti a mano,
/// oggi fisso al 3 novembre 2026. L'indice «indice-prova» con +1% nel 2024 e nel 2025 è un RIFERIMENTO DI PROVA scritto qui.
enum ProvaCalcoliTrackRecord {
    static func esegui(_ verifica: VerificaCalcoli) {
        let cal = Calendar(identifier: .gregorian)
        let oggi = AiutiProva.data(2026, 11, 3)
        func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
        let indice = "indice-prova"
        var riferimenti = RiferimentiRendimento()
        riferimenti.indici = [IndiceRiferimento(id: indice, nome: "Indice di prova")]
        riferimenti.valori = [ValoreRiferimento(serie: indice, anno: 2024, valore: 1.0), ValoreRiferimento(serie: indice, anno: 2025, valore: 1.0)]
        let tabella = TabellaRiferimenti(riferimenti)

        func posizione(_ id: String, stato: StatoPosizione = .inEssere, versato: Double? = nil, dal: Date? = nil,
                       valore: Double? = nil, al: Date? = nil) -> Posizione {
            var p = AiutiProva.posizione(id, .investimento, valore ?? 0) { q in
                q.id = id
                q.clienteId = "anna"
                q.stato = stato
                q.controvalore = valore
                q.dataValore = al
                q.decorrenza = dal
                if let v = versato, let x = dal { q.movimenti = [Movimento(data: x, importo: v)] }
            }
            p.esito = .accettata
            return p
        }
        func alternativa(_ serie: String?) -> AlternativaRaccomandazione {
            AlternativaRaccomandazione(tipo: serie == nil ? .altro : .riferimento,
                                       descrizione: serie == nil ? "Altra soluzione" : "Lo stesso capitale al ritmo dell'indice di prova",
                                       serieRiferimento: serie, ricavata: false)
        }
        func racc(_ id: String, posizione pid: String?, data: Date, serie: String?, scelta: SceltaCliente?, il: Date? = nil) -> Raccomandazione {
            var r = Raccomandazione(id: id, data: data, clienteId: "anna", posizioneId: pid, canale: .indipendente, area: .investimento,
                                    proposta: "Proposta \(id)", motivazione: "", cifre: CifreRaccomandazione(), alternativa: alternativa(serie))
            r.registraScelta(.inAttesa, il: data)
            if let s = scelta { r.registraScelta(s, il: il ?? data) }
            return r
        }

        let posizioni = [
            // 10.000 € il 1° gennaio 2024, 10.800 € il 1° gennaio 2026; l'indice dà 10.201 €: +599 €
            posizione("p1", versato: 10_000, dal: d(2024, 1, 1), valore: 10_800, al: d(2026, 1, 1)),
            // Esattamente al ritmo dell'indice: scarto zero
            posizione("p6", versato: 10_000, dal: d(2024, 1, 1), valore: 10_201, al: d(2026, 1, 1)),
            posizione("p2", versato: 5_000, dal: d(2026, 8, 1), valore: 5_000, al: d(2026, 8, 1)),
            posizione("p3", stato: .proposta),
            posizione("p5", stato: .chiusa),
            // Versamento del 2022: l'indice non ha i valori del 2022 e del 2023
            posizione("p7", versato: 10_000, dal: d(2022, 6, 1), valore: 11_000, al: d(2026, 1, 1)),
        ]
        let elenco = [
            racc("rA", posizione: "p1", data: d(2023, 12, 15), serie: indice, scelta: .accettata, il: d(2024, 1, 1)),
            racc("rB", posizione: "p6", data: d(2023, 12, 20), serie: indice, scelta: .accettata, il: d(2024, 1, 1)),
            racc("rC", posizione: "p2", data: d(2026, 7, 15), serie: nil, scelta: .accettata, il: d(2026, 8, 1)),
            racc("rD", posizione: "p3", data: d(2026, 3, 1), serie: indice, scelta: .rifiutata, il: d(2026, 3, 20)),
            racc("rE", posizione: nil, data: d(2026, 10, 1), serie: indice, scelta: nil),
            racc("rF", posizione: "p5", data: d(2024, 12, 1), serie: indice, scelta: .accettata, il: d(2025, 1, 1)),
            racc("rG", posizione: "p7", data: d(2025, 1, 15), serie: indice, scelta: .accettata, il: d(2025, 2, 1)),
        ]
        let t = MotoreTrackRecord.calcola(raccomandazioni: elenco, posizioni: posizioni, tabella: tabella, oggi: oggi, cal: cal)

        // 1. Conteggi
        verifica("Track record: raccomandazioni", Double(t.raccomandazioni), 7)
        verifica.vero("Track record: accettate, rifiutate, in attesa", t.accettate == 5 && t.rifiutate == 1 && t.inAttesa == 1)
        verifica("Track record: accettate su decise", t.quotaAccettate ?? -1, 5.0 / 6.0, tolleranza: 1e-9)
        verifica("Track record: accettate da almeno 12 mesi", Double(t.accettateDaAlmeno12Mesi), 4)
        verifica("Track record: ancora in essere dopo 12 mesi", Double(t.inEssereDopo12Mesi), 3)
        verifica("Track record: quota in essere dopo 12 mesi", t.quotaInEssereDopo12Mesi ?? -1, 0.75, tolleranza: 1e-9)
        verifica("Track record: dal", Double(t.dal ?? -1), 2023)
        verifica.vero("Track record: dalla più recente", t.voci.first?.id == "rE" && t.voci.last?.id == "rA")
        verifica.vero("Track record: sempre una stima", t.stima)
        let vuoto = MotoreTrackRecord.calcola(raccomandazioni: [], posizioni: posizioni, tabella: tabella, oggi: oggi, cal: cal)
        verifica.vero("Track record: senza raccomandazioni nessuna quota",
                      vuoto.quotaAccettate == nil && vuoto.quotaInEssereDopo12Mesi == nil && vuoto.scartoMedioAnnuo == nil && vuoto.dal == nil)

        // 2. Scarto rispetto all'alternativa (stima)
        func misura(_ id: String) -> TrackRecord.Misura? { t.voci.first { $0.id == id }?.misura }
        if case .scarto(let s)? = misura("rA") {
            verifica("Track record: valore dell'alternativa (10.000 × 1,01²)", s.valoreAlternativa, 10_201, tolleranza: 0.5)
            verifica("Track record: differenza rispetto all'alternativa", s.differenza, 599, tolleranza: 0.5)
            verifica("Track record: scarto annuo in punti", s.puntiAnnui ?? -1, 2.92, tolleranza: 0.05)
            verifica.vero("Track record: lo scarto è una stima", s.stima)
        } else {
            verifica.vero("Track record: scarto della rA misurato", false)
        }
        if case .scarto(let s)? = misura("rB") {
            verifica("Track record: al ritmo dell'alternativa nessuno scarto", s.differenza, 0, tolleranza: 0.5)
        } else {
            verifica.vero("Track record: scarto della rB misurato", false)
        }
        verifica.vero("Track record: senza riferimento niente scarto", misura("rC") == .senzaRiferimento)
        verifica.vero("Track record: rifiutata e in attesa non si misurano", misura("rD") == .nonAccettata && misura("rE") == .nonAccettata)
        verifica.vero("Track record: posizione chiusa senza valori", misura("rF") == .pochiDati)
        verifica.vero("Track record: riferimento mancante dal 2022", misura("rG") == .riferimentoMancante(dal: 2022))
        verifica.vero("Track record: posizione che non c'è più",
                      MotoreTrackRecord.misura(elenco[0], posizione: nil, tabella: tabella, oggi: oggi) == .posizioneAssente)
        verifica("Track record: misurate", Double(t.misurate), 2)
        // Media pesata sul valore all'alternativa: (2,92 × 10.201 + 0 × 10.201) / 20.402
        verifica("Track record: scarto medio annuo pesato", t.scartoMedioAnnuo ?? -1, 1.46, tolleranza: 0.03)
        verifica("Track record: differenza totale", t.differenzaTotale ?? -1, 599, tolleranza: 1)

        // 3. Immutabilità: si aggiungono solo note e scelte, il resto resta com'era
        let originale = elenco[4]
        var r = originale
        verifica.vero("Track record: la stessa scelta non si ripete", !r.registraScelta(.inAttesa, il: d(2026, 10, 2)))
        verifica.vero("Track record: la scelta nuova si aggiunge", r.registraScelta(.accettata, il: d(2026, 10, 20)))
        verifica.vero("Track record: lo storico delle scelte resta",
                      r.scelte.count == 2 && r.scelte.first?.scelta == .inAttesa && r.scelta == .accettata
                        && r.sceltaIl.map { cal.isDate($0, inSameDayAs: d(2026, 10, 20)) } == true)
        verifica.vero("Track record: una nota vuota non si aggiunge", !r.aggiungiNota("   ", il: d(2026, 10, 21)))
        verifica.vero("Track record: la nota si aggiunge con la data", r.aggiungiNota("Rivista con il cliente", il: d(2026, 10, 21))
                        && r.note.count == 1 && r.note[0].testo == "Rivista con il cliente")
        r.aggiungiNota("Seconda nota", il: d(2026, 10, 22))
        verifica.vero("Track record: le note di prima restano", r.note.count == 2 && r.note[0].testo == "Rivista con il cliente")
        verifica.vero("Track record: i campi registrati non cambiano",
                      r.id == originale.id && r.data == originale.data && r.proposta == originale.proposta
                        && r.cifre == originale.cifre && r.alternativa == originale.alternativa
                        && r.posizioneId == originale.posizioneId && r.motivazione == originale.motivazione)

        // 4. La raccomandazione registrata alla presentazione, con le cifre del momento
        var proposta = Posizione(clienteId: "anna", canale: .indipendente, stato: .proposta, area: .risparmio, nome: "Piano")
        proposta.id = "prop"
        proposta.premio = 450
        proposta.frequenza = .mensile
        proposta.sri = 3
        proposta.esito = .presentata
        let registrata = MotoreTrackRecord.raccomandazione(per: proposta, adeguatezza: nil, scheda: nil, posizioni: posizioni,
                                                           riferimenti: riferimenti, data: d(2026, 11, 3))
        verifica.vero("Track record: una per proposta (id dalla posizione)", registrata.id == "racc-prop" && registrata.posizioneId == "prop")
        verifica.vero("Track record: che cosa è stato proposto", registrata.proposta == "Piano da 450 € al mese")
        verifica.vero("Track record: le cifre del momento",
                      registrata.cifre.indicatori["premio"] == 450 && registrata.cifre.indicatori["premioAnnuo"] == 5_400
                        && registrata.cifre.indicatori["sri"] == 3 && registrata.cifre.righe.contains { $0.etichetta == "Premio" })
        verifica.vero("Track record: alternativa ricavata con il metro della proposta",
                      registrata.alternativa.tipo == .riferimento && registrata.alternativa.serieRiferimento != nil && registrata.alternativa.ricavata)
        verifica.vero("Track record: registrata in attesa, senza note", registrata.scelta == .inAttesa && registrata.note.isEmpty)
        var scheda = SchedaAdeguatezza(posizioneId: "prop", clienteId: "anna", creataIl: d(2026, 11, 1))
        scheda.posizioneSostituitaId = "p1"
        scheda.motivazione = " Più adatto ai suoi obiettivi "
        let sostituisce = MotoreTrackRecord.raccomandazione(per: proposta, adeguatezza: nil, scheda: scheda, posizioni: posizioni,
                                                            riferimenti: riferimenti, data: d(2026, 11, 3))
        verifica.vero("Track record: alternativa «lasciare com'è» la posizione sostituita",
                      sostituisce.alternativa.tipo == .lasciareComE && sostituisce.alternativa.posizioneSostituitaId == "p1"
                        && sostituisce.alternativa.serieRiferimento != nil && sostituisce.motivazione == "Più adatto ai suoi obiettivi")
        var copertura = proposta
        copertura.area = .protezione
        copertura.premio = 0
        copertura.frequenza = .unica
        copertura.capitaleAssicurato = 200_000
        let protezione = MotoreTrackRecord.raccomandazione(per: copertura, adeguatezza: nil, scheda: nil, posizioni: posizioni,
                                                           riferimenti: riferimenti, data: d(2026, 11, 3))
        verifica.vero("Track record: copertura senza riferimento",
                      protezione.alternativa.serieRiferimento == nil && protezione.proposta == "Piano da 200.000 € di capitale")
        verifica.vero("Track record: scelta dall'esito della proposta",
                      MotoreTrackRecord.scelta(.accettata) == .accettata && MotoreTrackRecord.scelta(.rifiutata) == .rifiutata
                        && MotoreTrackRecord.scelta(.presentata) == .inAttesa && MotoreTrackRecord.scelta(.rimandata) == .inAttesa
                        && MotoreTrackRecord.scelta(.bozza) == nil && MotoreTrackRecord.scelta(nil) == nil)

        // 5. Lettura tollerante e codifica
        if let codificata = try? Archivio.codificatore.encode(r), let riletta = try? Archivio.decodificatore.decode(Raccomandazione.self, from: codificata) {
            verifica.vero("Track record: raccomandazione uguale dopo codifica e lettura", riletta == r)
        } else {
            verifica.vero("Track record: raccomandazione codificata e letta", false)
        }
        let json = #"[{"id":"x","data":"2026-02-01T12:00:00Z","clienteId":"anna","scelte":[{"scelta":"accettata","data":"2026-02-02T12:00:00Z"},{"scelta":"forse"}],"alternativa":7},{"id":"senza-cliente","data":"2026-02-01T12:00:00Z"}]"#
        if let lette = try? Archivio.decodificatore.decode(ElencoTollerante<Raccomandazione>.self, from: Data(json.utf8)).elementi {
            verifica.vero("Track record: lettura tollerante (senza cliente scartata, scelta sconosciuta saltata)",
                          lette.count == 1 && lette[0].scelte.count == 1 && lette[0].scelta == .accettata
                            && lette[0].alternativa.serieRiferimento == nil && lette[0].proposta.isEmpty)
        } else {
            verifica.vero("Track record: lettura tollerante", false)
        }
    }
}
