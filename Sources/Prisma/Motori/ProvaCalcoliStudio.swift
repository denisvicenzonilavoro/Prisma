import Foundation

/// Prove del cruscotto di Studio (chiamate da `ProvaCalcoli.esegui()`, cioè da `Prisma --prova-calcoli`): casi costruiti
/// a mano, oggi fisso al 3 novembre 2026.
/// Le aliquote usate qui sono VALORI DI PROVA scritti in questa prova, non aliquote vere di Alleanza: servono solo a
/// controllare i conti (risparmio 4% nuova produzione e 3% ricorrenti, investimento 2% nuova produzione, protezione 20%
/// nuova produzione e 10% rinnovi, previdenza senza aliquote).
enum ProvaCalcoliStudio {
    static func esegui(_ verifica: VerificaCalcoli) {
        let cal = Calendar(identifier: .gregorian)
        let oggi = AiutiProva.data(2026, 11, 3)
        func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
        func cliente(_ id: String, creato: Date) -> Cliente {
            Cliente(id: id, nome: id.capitalized, iniziali: String(id.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                    telefono: "", preferito: false, nota: "", creatoIl: creato)
        }
        let clienti = [cliente("anna", creato: d(2020, 1, 1)), cliente("bruno", creato: d(2026, 3, 1)),
                       cliente("carla", creato: d(2026, 6, 10)), cliente("dario", creato: d(2025, 12, 31))]

        func alleanza(_ id: String, _ cliente: String, _ area: AreaPosizione, _ modifica: (inout Posizione) -> Void) -> Posizione {
            var p = Posizione(clienteId: cliente, canale: .alleanza, stato: .inEssere, area: area, nome: id)
            p.id = id
            p.creataIl = d(2020, 1, 1)
            modifica(&p)
            return p
        }
        let posizioni = [
            // Risparmio mensile da 100 € dal 15 marzo 2025: nuova produzione su 1.200 € nel marzo 2025, ricorrenti dal 2026
            alleanza("p1", "anna", .risparmio) { $0.premio = 100; $0.frequenza = .mensile; $0.decorrenza = d(2025, 3, 15); $0.scadenza = d(2030, 3, 15) },
            // Premio unico da 10.000 € il 20 maggio 2026
            alleanza("p2", "bruno", .investimento) { $0.versamentoIniziale = 10_000; $0.decorrenza = d(2026, 5, 20) },
            // Copertura annuale da 600 € dal 1° luglio 2024: rinnovi il 1° luglio di ogni anno
            alleanza("p3", "carla", .protezione) { $0.premio = 600; $0.frequenza = .annuale; $0.decorrenza = d(2024, 7, 1) },
            // Previdenza mensile da 200 € dal 1° febbraio 2026: nessuna aliquota di previdenza
            alleanza("p4", "dario", .previdenza) { $0.premio = 200; $0.frequenza = .mensile; $0.decorrenza = d(2026, 2, 1) },
            // Senza decorrenza: non si sa quando matura
            alleanza("p5", "anna", .risparmio) { $0.premio = 50; $0.frequenza = .mensile },
            // Non contano: canale indipendente, area liquidità, proposta
            AiutiProva.posizione("Fondo", .investimento, 50_000) { $0.clienteId = "anna"; $0.decorrenza = d(2026, 2, 1); $0.versamentoIniziale = 50_000 },
            alleanza("p6", "anna", .liquidita) { $0.versamentoIniziale = 5_000; $0.decorrenza = d(2026, 3, 1) },
            alleanza("p7", "bruno", .investimento) { $0.stato = .proposta; $0.versamentoIniziale = 20_000; $0.decorrenza = d(2026, 4, 1) },
        ]
        var studio = ImpostazioniStudio()
        studio.aliquote[.risparmio] = AliquoteProvvigione(nuovaProduzione: 4, ricorrenti: 3)
        studio.aliquote[.investimento] = AliquoteProvvigione(nuovaProduzione: 2)
        studio.aliquote[.protezione] = AliquoteProvvigione(nuovaProduzione: 20, rinnovi: 10)

        // Appuntamenti: contano i conclusi dell'anno fino a oggi e quelli con un incontro collegato
        func app(_ id: String, _ cliente: String, _ inizio: Date, _ minuti: Int, _ stato: Appuntamento.Stato,
                 tipo: TipoAppuntamento = .altro) -> Appuntamento {
            Appuntamento(id: id, clienteId: cliente, titolo: "Prova", inizio: inizio, durataMinuti: minuti, luogo: "", note: "",
                         stato: stato, tipo: tipo)
        }
        let appuntamenti = [
            app("a1", "anna", d(2026, 2, 10), 120, .concluso),
            app("a2", "anna", d(2026, 9, 1), 60, .concluso),
            app("a3", "anna", d(2026, 12, 1), 60, .pianificato),      // futuro: non conta
            app("a4", "anna", d(2026, 10, 1), 60, .pianificato),      // passato ma non concluso e senza incontro: non conta
            app("b1", "bruno", d(2026, 6, 1), 90, .pianificato),      // con un incontro collegato: conta
            app("b2", "bruno", d(2025, 10, 1), 600, .concluso),       // anno prima: non conta
            app("c1", "carla", d(2026, 3, 1), 30, .concluso, tipo: .telefonata),
            app("d1", "dario", d(2026, 4, 1), 300, .concluso),
            app("x1", "ignoto", d(2026, 4, 1), 300, .concluso),       // cliente che non c'è: non conta
        ]
        let incontri = [Incontro(clienteId: "bruno", titolo: "Incontro", data: d(2026, 6, 1), appuntamentoId: "b1")]

        // 1. Senza aliquote: nessuna cifra Alleanza, nessuna zona
        let senza = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: incontri,
                                         studio: ImpostazioniStudio(), oggi: oggi, cal: cal)
        verifica.vero("Studio senza aliquote: manca aliquote", senza.mancaAliquote && senza.ricavi.mancaAliquote)
        verifica.vero("Studio senza aliquote: nessuna cifra Alleanza nei ricavi", senza.ricavi.alleanza == nil && senza.ricavi.alleanzaPerMese == nil)
        verifica.vero("Studio senza aliquote: nessuna cifra Alleanza negli incassi",
                      senza.incassi.totaleAlleanza == nil && senza.incassi.mesi.allSatisfy { $0.alleanza == nil })
        verifica("Studio senza aliquote: ricavi totali (nessuna parcella)", senza.ricavi.totale, 0)
        verifica.vero("Studio senza aliquote: nessuna parcella segnalata", senza.ricavi.nessunaParcella && senza.incassi.nessunaParcella)
        verifica.vero("Studio senza aliquote: niente zona «molto tempo, poco valore»",
                      senza.valoreTempo.sogliaOre == nil && senza.valoreTempo.inZona.isEmpty && senza.valoreTempo.ricaviParziali)
        verifica.vero("Studio senza aliquote: niente variazione né anno precedente", senza.variazione == nil && senza.primoAnno)
        verifica("Studio senza aliquote: posizioni Alleanza senza decorrenza", Double(senza.posizioniSenzaDecorrenza), 1)

        // 2. Con le aliquote di prova: ricavi del 2026 fino a oggi
        let c = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: incontri,
                                     studio: studio, oggi: oggi, cal: cal)
        // p1: 8 rate (15 marzo-15 ottobre) × 100 × 3% = 24; p2: 10.000 × 2% = 200; p3: rinnovo 600 × 10% = 60; p4 senza aliquota
        verifica("Studio: provvigioni Alleanza 2026 a oggi", c.ricavi.alleanza ?? -1, 284)
        verifica("Studio: posizioni senza aliquota nel 2026", Double(c.ricavi.posizioniSenzaAliquota), 1)
        verifica.vero("Studio: con un'aliquota mancante la cifra è una stima", c.ricavi.stima && !c.ricavi.mancaAliquote)
        verifica("Studio: maggio (premio unico e rata)", c.ricavi.alleanzaPerMese?[4] ?? -1, 203)
        verifica("Studio: luglio (rinnovo e rata)", c.ricavi.alleanzaPerMese?[6] ?? -1, 63)
        verifica("Studio: novembre (rata del 15 non ancora maturata)", c.ricavi.alleanzaPerMese?[10] ?? -1, 0)
        verifica("Studio: punti cumulati fino a novembre", Double(c.ricavi.cumulati.count), 12)
        verifica("Studio: ultimo cumulato uguale al totale", c.ricavi.cumulati.last ?? -1, 284)
        verifica("Studio: ricavi indipendenti (nessuna parcella)", c.ricavi.indipendente, 0)

        // 3. Anno precedente: nuova produzione di p1 (1.200 × 4% = 48) e rinnovo di p3 (60); niente rate di p1 nella prima annualità
        verifica("Studio: anno precedente intero", c.annoPrecedente.totale, 108)
        verifica("Studio: anno precedente, 13 punti", Double(c.annoPrecedente.cumulati.count), 13)
        verifica("Studio: anno precedente a pari data", c.annoPrecedenteAPariData.totale, 108)
        verifica("Studio: variazione a pari data (284 contro 108)", c.variazione ?? -1, (284.0 - 108) / 108, tolleranza: 0.0001)
        verifica.vero("Studio: con l'anno precedente non è il primo anno", !c.primoAnno)
        let soloP2 = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni.filter { $0.id == "p2" }, appuntamenti: [], incontri: [],
                                          studio: studio, oggi: oggi, cal: cal)
        verifica.vero("Studio: senza ricavi l'anno prima nessuna variazione (non +∞%)", soloP2.variazione == nil && soloP2.primoAnno)

        // 4. Obiettivi: produzione Alleanza 10.000 (p2) + 2.400 (p4) su 50.000; nuovi clienti 2 su 4; consulenza non impostata
        var conObiettivi = studio
        conObiettivi.obiettivi[2026] = ObiettiviStudio(produzioneAlleanza: 50_000, nuoviClienti: 4)
        conObiettivi.obiettivi[2025] = ObiettiviStudio(nuoviClienti: 99)   // un altro anno: non conta
        let o = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: [], incontri: [],
                                     studio: conObiettivi, oggi: oggi, cal: cal).obiettivi
        verifica("Studio: tre voci di obiettivo", Double(o.voci.count), 3)
        verifica("Studio: produzione Alleanza fatta", o.voce(.produzioneAlleanza)?.fatto ?? -1, 12_400)
        verifica("Studio: produzione Alleanza, frazione", o.voce(.produzioneAlleanza)?.frazione ?? -1, 0.248)
        verifica("Studio: nuovi clienti dell'anno", o.voce(.nuoviClienti)?.fatto ?? -1, 2)
        verifica("Studio: nuovi clienti, frazione", o.voce(.nuoviClienti)?.frazione ?? -1, 0.5)
        verifica.vero("Studio: nuovi clienti dalla data di inserimento", o.voce(.nuoviClienti)?.avviso == .dallaDataDiInserimento)
        verifica.vero("Studio: consulenza senza traguardo, nessuna frazione",
                      o.voce(.ricaviConsulenza)?.impostato == false && o.voce(.ricaviConsulenza)?.frazione == nil
                        && o.voce(.ricaviConsulenza)?.avviso == .nessunaParcella)
        verifica("Studio: anelli da disegnare", Double(o.impostati.count), 2)
        var oltre = studio
        oltre.obiettivi[2026] = ObiettiviStudio(produzioneAlleanza: 0, nuoviClienti: 1)
        let o2 = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: [], incontri: [],
                                      studio: oltre, oggi: oggi, cal: cal).obiettivi
        verifica.vero("Studio: obiettivo a 0 = nessun obiettivo (niente divisione per zero)",
                      o2.voce(.produzioneAlleanza)?.impostato == false && o2.voce(.produzioneAlleanza)?.frazione == nil)
        verifica("Studio: oltre il traguardo la cifra supera il 100%", o2.voce(.nuoviClienti)?.frazione ?? -1, 2)
        verifica("Studio: oltre il traguardo l'anello è pieno", o2.voce(.nuoviClienti)?.frazioneAnello ?? -1, 1)
        let senzaObiettivi = MotoreStudio.calcola(clienti: clienti, posizioni: [], appuntamenti: [], incontri: [],
                                                  studio: ImpostazioniStudio(), oggi: oggi, cal: cal).obiettivi
        verifica.vero("Studio: senza obiettivi nessun anello", senzaObiettivi.nessunoImpostato)

        // 5. Imbuto: bozza, presentata, rifiutata, accettata (passata in essere) create nel 2026; una del 2025 esclusa
        func proposta(_ id: String, _ esito: EsitoProposta, creata: Date, presentata: Date? = nil, deciso: Date? = nil) -> Posizione {
            var p = Posizione(clienteId: "anna", canale: .indipendente, stato: esito == .accettata ? .inEssere : .proposta,
                              area: .investimento, nome: id)
            p.id = id
            p.esito = esito
            p.creataIl = creata
            if presentata != nil || deciso != nil {
                var s = SeguitoProposta()
                s.presentataIl = presentata
                s.esitoIl = deciso
                p.seguito = s
            }
            return p
        }
        let proposte = [
            proposta("q1", .bozza, creata: d(2026, 1, 10)),
            proposta("q2", .presentata, creata: d(2026, 2, 10), presentata: d(2026, 2, 20)),
            proposta("q3", .rifiutata, creata: d(2026, 3, 10), presentata: d(2026, 3, 15), deciso: d(2026, 3, 20)),
            proposta("q4", .accettata, creata: d(2026, 4, 1), presentata: d(2026, 4, 1), deciso: d(2026, 4, 21)),
            proposta("q0", .accettata, creata: d(2025, 6, 1), presentata: d(2025, 6, 1), deciso: d(2025, 6, 30)),
        ]
        let i = MotoreStudio.calcola(clienti: clienti, posizioni: proposte, appuntamenti: [], incontri: [],
                                     studio: studio, oggi: oggi, cal: cal).imbuto
        verifica("Studio imbuto: preparate", Double(i.preparate), 4)
        verifica("Studio imbuto: presentate", Double(i.presentate), 3)
        verifica("Studio imbuto: firmate", Double(i.firmate), 1)
        verifica("Studio imbuto: tasso di chiusura", i.tassoChiusura ?? -1, 0.25)
        verifica("Studio imbuto: giorni alla firma (solo le accettate)", i.giorniMediAllaFirma ?? -1, 20)
        verifica.vero("Studio imbuto: si fermano dopo la presentazione", i.fase == .dopoLaPresentazione)
        verifica("Studio imbuto: ferme dopo la presentazione", Double(i.ferme), 2)
        let altre = proposte + [proposta("q5", .accettata, creata: d(2026, 5, 1), presentata: d(2026, 5, 1), deciso: d(2026, 5, 31))]
        let i2 = MotoreStudio.calcola(clienti: clienti, posizioni: altre, appuntamenti: [], incontri: [],
                                      studio: studio, oggi: oggi, cal: cal).imbuto
        verifica("Studio imbuto: media dei giorni alla firma su due accettate", i2.giorniMediAllaFirma ?? -1, 25)
        let ferme = [proposta("r1", .bozza, creata: d(2026, 1, 1)), proposta("r2", .bozza, creata: d(2026, 1, 2)),
                     proposta("r3", .bozza, creata: d(2026, 1, 3)),
                     proposta("r4", .accettata, creata: d(2026, 1, 4))]
        let i3 = MotoreStudio.calcola(clienti: clienti, posizioni: ferme, appuntamenti: [], incontri: [],
                                      studio: studio, oggi: oggi, cal: cal).imbuto
        verifica.vero("Studio imbuto: si fermano prima della presentazione", i3.fase == .primaDellaPresentazione && i3.ferme == 3)
        verifica.vero("Studio imbuto: accettata senza date fuori dalla media", i3.giorniMediAllaFirma == nil && i3.firmateConDate == 0)
        let vuoto = MotoreStudio.calcola(clienti: clienti, posizioni: [], appuntamenti: [], incontri: [], studio: studio, oggi: oggi, cal: cal)
        verifica.vero("Studio imbuto: vuoto senza proposte", vuoto.imbuto.vuoto && vuoto.imbuto.tassoChiusura == nil && vuoto.imbuto.fase == nil)

        // 6. Incassi dei prossimi 12 mesi: da dicembre 2026 a novembre 2027 (a cavallo d'anno)
        let inc = c.incassi
        verifica("Studio incassi: 12 mesi", Double(inc.mesi.count), 12)
        verifica.vero("Studio incassi: si parte dal 1° dicembre 2026",
                      inc.mesi.first.map { cal.isDate($0.inizio, equalTo: d(2026, 12, 1), toGranularity: .month) } == true)
        verifica.vero("Studio incassi: si finisce a novembre 2027",
                      inc.mesi.last.map { cal.isDate($0.inizio, equalTo: d(2027, 11, 1), toGranularity: .month) } == true)
        // p1: 12 rate × 3 = 36; p3: rinnovo del 1° luglio 2027 = 60; p4 senza aliquota (segnalata)
        verifica("Studio incassi: totale Alleanza", inc.totaleAlleanza ?? -1, 96)
        verifica("Studio incassi: dicembre", inc.mesi[0].alleanza ?? -1, 3)
        verifica("Studio incassi: luglio 2027", inc.mesi[7].alleanza ?? -1, 63)
        verifica("Studio incassi: posizioni senza aliquota", Double(inc.posizioniSenzaAliquota), 1)
        verifica("Studio incassi: parcelle future (nessuna)", inc.totaleIndipendente, 0)
        let scade = alleanza("p8", "anna", .risparmio) { $0.premio = 100; $0.frequenza = .mensile; $0.decorrenza = d(2024, 1, 10); $0.scadenza = d(2027, 3, 10) }
        let incScade = MotoreStudio.calcola(clienti: clienti, posizioni: [scade], appuntamenti: [], incontri: [],
                                            studio: studio, oggi: oggi, cal: cal).incassi
        // Rate del 10 dicembre, gennaio e febbraio: quella del 10 marzo 2027 cade alla scadenza e non c'è
        verifica("Studio incassi: rate fino alla scadenza esclusa", incScade.totaleAlleanza ?? -1, 9)

        // 7. Parcelle (struttura per il giro 2): ricavi dell'anno, incassi futuri non incassati, ricavi del cliente
        let parcelle = [RicavoConsulenza(clienteId: "carla", data: d(2026, 2, 15), importo: 1_000, incassata: true),
                        RicavoConsulenza(clienteId: "carla", data: d(2027, 1, 15), importo: 500, incassata: false),
                        RicavoConsulenza(clienteId: "ignoto", data: d(2026, 2, 15), importo: 9_999, incassata: true)]
        let conParcelle = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: incontri,
                                               studio: studio, parcelle: parcelle, oggi: oggi, cal: cal)
        verifica("Studio parcelle: ricavi della consulenza dell'anno", conParcelle.ricavi.indipendente, 1_000)
        verifica("Studio parcelle: febbraio indipendente", conParcelle.ricavi.indipendentePerMese[1], 1_000)
        verifica("Studio parcelle: incasso di gennaio 2027", conParcelle.incassi.mesi[1].indipendente, 500)
        verifica.vero("Studio parcelle: non più «nessuna parcella»", !conParcelle.ricavi.nessunaParcella)

        // 8. Valore e tempo: anna 3 ore, bruno 1,5 (con l'incontro), carla 0,5 (telefonata), dario 5
        let vt = c.valoreTempo
        verifica("Studio valore e tempo: clienti con ore", Double(vt.punti.count), 4)
        verifica.vero("Studio valore e tempo: dal più impegnativo", vt.punti.map(\.cliente.id) == ["dario", "anna", "bruno", "carla"])
        verifica("Studio valore e tempo: ore di anna", vt.punti.first(where: { $0.cliente.id == "anna" })?.ore ?? -1, 3)
        verifica("Studio valore e tempo: ore di bruno (appuntamento con incontro)", vt.punti.first(where: { $0.cliente.id == "bruno" })?.ore ?? -1, 1.5)
        verifica("Studio valore e tempo: ricavi di bruno", vt.punti.first(where: { $0.cliente.id == "bruno" })?.ricavi ?? -1, 200)
        verifica("Studio valore e tempo: ricavi di dario (senza aliquota)", vt.punti.first(where: { $0.cliente.id == "dario" })?.ricavi ?? -1, 0)
        verifica("Studio valore e tempo: mediana delle ore", vt.sogliaOre ?? -1, 2.25)
        verifica("Studio valore e tempo: mediana dei ricavi", vt.sogliaRicavi ?? -1, 42)
        verifica.vero("Studio valore e tempo: in zona dario e anna", vt.inZona.map(\.cliente.id) == ["dario", "anna"])
        let pochi = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti.filter { $0.clienteId == "anna" },
                                         incontri: [], studio: studio, oggi: oggi, cal: cal).valoreTempo
        verifica.vero("Studio valore e tempo: con meno di 3 clienti niente zona", pochi.punti.count == 1 && pochi.sogliaOre == nil && pochi.inZona.isEmpty)
        verifica("Studio: mediana con un numero pari di valori", MotoreStudio.mediana([4, 1, 3, 2]) ?? -1, 2.5)

        // 9. Deterministico: due calcoli uguali danno lo stesso cruscotto
        let ancora = MotoreStudio.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: incontri,
                                          studio: studio, oggi: oggi, cal: cal)
        verifica.vero("Studio: calcolo deterministico", ancora == c)

        // 10. Le impostazioni di Studio tornano uguali da JSON; una chiave sconosciuta e valori negativi si scartano
        if let json = try? Archivio.codificatore.encode(conObiettivi),
           let letto = try? Archivio.decodificatore.decode(ImpostazioniStudio.self, from: json) {
            verifica.vero("Studio: impostazioni uguali dopo codifica e lettura", letto == conObiettivi)
        } else {
            verifica.vero("Studio: impostazioni codificate e lette", false)
        }
        let strano = #"{"aliquote":{"risparmio":{"nuovaProduzione":-3,"ricorrenti":2},"astronavi":{"nuovaProduzione":5}},"obiettivi":{"2026":{"nuoviClienti":5},"anno":{"nuoviClienti":1}}}"#
        let lettoStrano = try? Archivio.decodificatore.decode(ImpostazioniStudio.self, from: Data(strano.utf8))
        verifica.vero("Studio: lettura tollerante delle impostazioni",
                      lettoStrano?.aliquote.count == 1 && lettoStrano?.aliquote[.risparmio]?.nuovaProduzione == nil
                        && lettoStrano?.aliquote[.risparmio]?.ricorrenti == 2 && lettoStrano?.obiettivi.count == 1
                        && lettoStrano?.obiettivi[2026]?.nuoviClienti == 5)
    }
}
