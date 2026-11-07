import Foundation

/// Prove della linea della vita (Clienti › Dossier, Orizzonte giro 4): il passo annuo, gli eventi una volta e per
/// N anni, il prelievo in pensione, l'esaurimento prima dei 90, i limiti dei gettoni, la coerenza con i motori di
/// prima (patrimonio, versamenti, pensione pubblica) e la velocità. Chiamate da `ProvaCalcoli.esegui()`.
/// Rendimento 0 dove serve per avere cifre tonde da verificare a mano.
enum ProvaCalcoliLineaVita {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 4)
        func ingresso(eta: Int = 40, pensione: Int = 67, patrimonio: Double = 100_000, risparmio: Double = 10_000,
                      rendimento: Double = 0, reddito: Double? = 2_200, pensioneMensile: Double? = 1_400,
                      movimenti: [MovimentoLineaVita] = []) -> IngressoLineaVita {
            IngressoLineaVita(etaOggi: eta, etaPensione: pensione, patrimonioIniziale: patrimonio, risparmioAnnuo: risparmio,
                              rendimentoReale: rendimento, redditoDesiderato: reddito,
                              pensionePerEta: pensioneMensile.map { [pensione: $0] } ?? [:], movimenti: movimenti)
        }

        // LV1. Passo annuo con rendimento 0: 26 anni di risparmio (41…66), dal 67 il prelievo di 10.400 € l'anno.
        do {
            let e = MotoreLineaVita.calcola(ingresso())
            verifica("LV1 Punti da 40 a 90 anni", Double(e.punti.count), 51)
            verifica("LV1 Massimo a 66 anni: 100.000 + 26 × 10.000", e.massimo, 360_000)
            verifica("LV1 Età del massimo", Double(e.etaMassimo), 66)
            verifica("LV1 Alla pensione (67, primo prelievo): 349.600 €", e.allaPensione, 349_600)
            verifica("LV1 A 90 anni: 360.000 − 24 × 10.400", e.valore(90) ?? -1, 110_400)
            verifica.vero("LV1 Basta oltre i 90 anni", e.basta && e.etaEsaurimento == nil)
            // Con il rendimento: un anno di crescita al 2% reale
            let r = MotoreLineaVita.calcola(ingresso(risparmio: 0, rendimento: 2))
            verifica("LV1 Rendimento reale 2%: dopo un anno 102.000 €", r.valore(41) ?? -1, 102_000)
        }

        // LV2. Evento per N anni: −4.000 da 41 per 22 anni tocca 41…62 e non il 63.
        do {
            let senza = MotoreLineaVita.calcola(ingresso())
            let con = MotoreLineaVita.calcola(ingresso(movimenti: [MovimentoLineaVita(id: "figlio", eta: 41, importo: -4_000, perAnni: 22)]))
            func scarto(_ eta: Int) -> Double { (con.valore(eta) ?? 0) - (senza.valore(eta) ?? 0) }
            verifica("LV2 Primo anno: −4.000", scarto(41), -4_000)
            verifica("LV2 Ultimo anno (62): −88.000", scarto(62), -88_000)
            verifica("LV2 Il 63 non è toccato", scarto(63) - scarto(62), 0)
            // Un'entrata una volta sola sposta tutto ciò che viene dopo
            let eredita = MotoreLineaVita.calcola(ingresso(movimenti: [MovimentoLineaVita(id: "eredita", eta: 50, importo: 80_000)]))
            verifica("LV2 Eredità di 80.000 a 50 anni: +80.000 da lì in poi", (eredita.valore(70) ?? 0) - (senza.valore(70) ?? 0), 80_000)
            verifica("LV2 Prima dei 50 nulla cambia", (eredita.valore(49) ?? 0) - (senza.valore(49) ?? 0), 0)
            // Un evento a oggi è già nel patrimonio di partenza: non conta
            let adesso = MotoreLineaVita.calcola(ingresso(movimenti: [MovimentoLineaVita(id: "oggi", eta: 40, importo: -50_000)]))
            verifica.vero("LV2 Evento all'età di oggi: ignorato", adesso == senza)
        }

        // LV3. Esaurimento prima dei 90: 100.000 € a 65 anni in pensione, prelievo 10.400 € l'anno → sotto zero a 75.
        do {
            let e = MotoreLineaVita.calcola(ingresso(eta: 65, pensione: 65, risparmio: 0))
            verifica("LV3 Finisce a 75 anni", Double(e.etaEsaurimento ?? -1), 75)
            verifica.vero("LV3 Non basta", !e.basta)
            // LV8. Esattamente 0 non è esaurimento: con 104.000 € a 75 resta 0, finisce a 76
            let zero = MotoreLineaVita.calcola(ingresso(eta: 65, pensione: 65, patrimonio: 104_000, risparmio: 0))
            verifica("LV8 A 75 anni esattamente 0", zero.valore(75) ?? -1, 0)
            verifica("LV8 Zero non è esaurimento: finisce a 76", Double(zero.etaEsaurimento ?? -1), 76)
            // Spostare la pensione più tardi allunga la linea
            let tardi = MotoreLineaVita.calcola(ingresso(eta: 60, pensione: 67, patrimonio: 50_000, risparmio: 10_000))
            let presto = MotoreLineaVita.calcola(ingresso(eta: 60, pensione: 61, patrimonio: 50_000, risparmio: 10_000))
            verifica.vero("LV3 Pensione più presto: finisce prima", (presto.etaEsaurimento ?? 99) < (tardi.etaEsaurimento ?? 99))
        }

        // LV4. Limiti dei gettoni: un evento fra età + 1 e 88, la pensione fra 55 e 72.
        do {
            verifica("LV4 Evento sotto l'età di oggi: l'anno prossimo", Double(MotoreLineaVita.limitaEtaEvento(30, etaOggi: 40)), 41)
            verifica("LV4 Evento oltre 88: 88", Double(MotoreLineaVita.limitaEtaEvento(95, etaOggi: 40)), 88)
            verifica("LV4 Pensione a 50: 55", Double(MotoreLineaVita.limitaEtaPensione(50)), 55)
            verifica("LV4 Pensione a 80: 72", Double(MotoreLineaVita.limitaEtaPensione(80)), 72)
        }

        // LV5. Prelievo: reddito desiderato 2.200, pensione netta 1.400 → 800 × 13 = 10.400; pensione più alta → 0.
        do {
            verifica("LV5 Prelievo 800 × 13", ingresso().prelievoAnnuo ?? -1, 10_400)
            verifica("LV5 Pensione sopra il reddito desiderato: prelievo 0, non negativo", ingresso(pensioneMensile: 2_500).prelievoAnnuo ?? -1, 0)
            verifica.vero("LV5 Senza reddito desiderato: nessun prelievo inventato", ingresso(reddito: nil).prelievoAnnuo == nil
                          && MotoreLineaVita.calcola(ingresso(reddito: nil)).dopoPensioneIndicativa)
            verifica.vero("LV5 Senza pensione stimata: nessun prelievo", ingresso(pensioneMensile: nil).prelievoAnnuo == nil)
            var tabella = ingresso()
            tabella.pensionePerEta = [60: 1_000, 67: 1_400]
            tabella.etaPensione = 72
            verifica("LV5 Età fuori tabella: la più vicina (67)", tabella.pensione(72) ?? -1, 1_400)
        }

        // Il cliente di prova: nato il 4 novembre 1986 (40 anni il 4 novembre 2026), conto e fondo con versamenti.
        var c = Cliente(id: "vita", nome: "Vita Prova", iniziali: "VP", tinta: .verde, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: oggi)
        c.dataNascita = AiutiProva.data(1986, 11, 4)
        var conto = AiutiProva.posizione("Conto", .liquidita, 20_000)
        conto.clienteId = "vita"
        var fondo = AiutiProva.posizione("Fondo", .investimento, 30_000) { $0.rendimentoAtteso = 4; $0.costoAnnuo = 1; $0.premio = 100; $0.frequenza = .mensile }
        fondo.clienteId = "vita"
        var casaVecchia = AiutiProva.posizione("Casa", .immobili, 300_000)
        casaVecchia.clienteId = "vita"
        let posizioni = [conto, fondo, casaVecchia]

        // LV7. Dati mancanti: senza data di nascita non si calcola e si dice perché.
        do {
            var senza = c
            senza.dataNascita = nil
            let p = MotoreLineaVita.prepara(cliente: senza, posizioni: posizioni, obiettivi: [], eventi: [], analisi: nil, oggi: oggi)
            verifica.vero("LV7 Senza data di nascita: nessun calcolo e il motivo", p.ingresso == nil && p.motivoAssente?.contains("data di nascita di Vita") == true)
        }

        // LV9. Coerenza con i motori di prima.
        do {
            let p = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [], eventi: [], analisi: nil, oggi: oggi)
            let finanziarie = [conto, fondo]
            let patrimonio = MotorePatrimonio.calcola(finanziarie, oggi: oggi)
            verifica("LV9 Età di oggi dalla data di nascita", Double(p.ingresso?.etaOggi ?? -1), 40)
            verifica("LV9 Patrimonio di partenza = MotorePatrimonio (senza immobili)", p.ingresso?.patrimonioIniziale ?? -1, patrimonio.nettoOggi)
            verifica("LV9 Risparmio = versamenti delle posizioni (1.200 € l'anno)", p.ingresso?.risparmioAnnuo ?? -1, patrimonio.versamentiAnnui)
            verifica("LV9 Versamenti delle posizioni", patrimonio.versamentiAnnui, 1_200)
            verifica.vero("LV9 Risparmio libero non indicato: avviso", p.avvisi.contains { $0.hasPrefix("Risparmio libero non indicato") })
            verifica.vero("LV9 Senza Analisi 360 salvata: reddito desiderato non inventato", p.ingresso?.redditoDesiderato == nil)
            verifica.vero("LV9 Età di pensione non indicata: 67 come ipotesi", p.ingresso?.etaPensione == 67 && p.etaPensioneIpotizzata)
            verifica("LV9 Rendimento reale medio: (4 − 1) netto d'imposta, tolta l'inflazione, pesato sul valore",
                     p.ingresso?.rendimentoReale ?? -1, MotoreLineaVita.rendimentoRealeMedio(finanziarie) ?? -2, tolleranza: 1e-9)
            verifica("LV9 Rendimento reale medio a mano", MotoreLineaVita.rendimentoRealeMedio(finanziarie) ?? -1,
                     ((1 + 0.6 * 3 * 0.74 / 100) / 1.02 - 1) * 100, tolleranza: 1e-9)

            // Con il lavoro: la pensione per età di uscita è quella di MotorePensionePubblica
            var conLavoro = c
            conLavoro.profilo.lavoro = DatiLavoro(tipo: .dipendente, redditoLavoro: 40_000, anniContributi: 15)
            conLavoro.profilo.risparmioAnnuo = 6_000
            let l = MotoreLineaVita.prepara(cliente: conLavoro, posizioni: posizioni, obiettivi: [], eventi: [], analisi: nil, oggi: oggi)
            let stima = MotorePensionePubblica.stima(lavoro: conLavoro.profilo.lavoro!, eta: 40, etaPensione: 67, reddito: nil)
            verifica("LV9 Pensione a 67 = MotorePensionePubblica", l.ingresso?.pensione(67) ?? -1, MotoreFiscale.centesimi(stima?.nettaMensile ?? -2))
            verifica.vero("LV9 Più tardi si esce, più alta la pensione", (l.ingresso?.pensione(70) ?? 0) > (l.ingresso?.pensione(62) ?? 0))
            verifica("LV9 Risparmio libero sommato ai versamenti", l.ingresso?.risparmioAnnuo ?? -1, 7_200)

            // Con l'Analisi 360 salvata: reddito desiderato, pensione inserita e rendimento reale del cliente
            var a = Analisi360()
            a.previdenza.redditoDesiderato = 2_500
            a.previdenza.pensionePubblica = 1_600
            a.previdenza.rendimentoReale = 1
            a.previdenza.etaPensione = 65
            let s = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [], eventi: [], analisi: a, oggi: oggi)
            verifica("LV9 Analisi 360: prelievo (2.500 − 1.600) × 13", s.ingresso?.prelievoAnnuo ?? -1, 11_700)
            verifica("LV9 Analisi 360: rendimento reale del cliente", s.ingresso?.rendimentoReale ?? -1, 1)
            verifica("LV9 Analisi 360: età di pensione", Double(s.ingresso?.etaPensione ?? -1), 65)
        }

        // LV6. Eventi dell'archivio e obiettivi: età dall'anno, nessun doppio conteggio, eventi senza cifra.
        do {
            let annoEvento = EventoLineaVita(clienteId: "vita", tipo: .figlio, anno: 2030)
            verifica("LV6 Età dall'anno: 40 + (2030 − 2026)", Double(annoEvento.etaEvento(etaOggi: 40, annoOggi: 2026) ?? -1), 44)
            let casa = EventoLineaVita(clienteId: "vita", tipo: .casa, eta: 43, importo: -40_000)
            let senzaCifra = EventoLineaVita(clienteId: "vita", tipo: .annoSabbatico, eta: 50)
            let altrui = EventoLineaVita(clienteId: "altro", tipo: .eredita, eta: 60, importo: 100_000)
            var obiettivo = Obiettivo(clienteId: "vita", titolo: "Anticipo casa", area: .casa, importo: 45_000, scadenza: AiutiProva.data(2029, 12, 1))
            obiettivo.accantonato = 5_000
            let conEvento = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [obiettivo], eventi: [casa, senzaCifra, altrui], analisi: nil, oggi: oggi)
            verifica("LV6 Casa: evento e obiettivo uguali → un'uscita sola", Double(conEvento.ingresso?.movimenti.count ?? -1), 1)
            verifica("LV6 Evento senza cifra: si conta a parte", Double(conEvento.eventiSenzaCifra), 1)
            let soloObiettivo = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [obiettivo], eventi: [], analisi: nil, oggi: oggi)
            let m = soloObiettivo.ingresso?.movimenti.first
            verifica("LV6 Obiettivo come uscita: importo meno l'accantonato", m?.importo ?? 0, -40_000)
            verifica("LV6 Obiettivo all'età della scadenza (43)", Double(m?.eta ?? -1), 43)
            let senzaObiettivi = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [obiettivo], eventi: [], analisi: nil,
                                                          conObiettivi: false, oggi: oggi)
            verifica("LV6 Senza obiettivi: nessuna uscita", Double(senzaObiettivi.ingresso?.movimenti.count ?? -1), 0)
            let eredita = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: [],
                                                  eventi: [EventoLineaVita(clienteId: "vita", tipo: .eredita, eta: 60, importo: 100_000)], analisi: nil, oggi: oggi)
            verifica.vero("LV6 Eredità: avviso dell'imposta di successione", eredita.avvisi.contains { $0.contains("successione") })
            // Gli eventi spostano il patrimonio: la casa a 43 anni abbassa la linea da lì in poi di 40.000 € (più il rendimento perso)
            if let i1 = conEvento.ingresso, let i0 = senzaObiettivi.ingresso {
                let con = MotoreLineaVita.calcola(i1), senza = MotoreLineaVita.calcola(i0)
                verifica("LV6 Prima della casa nulla cambia", (con.valore(42) ?? 0) - (senza.valore(42) ?? 0), 0)
                verifica.vero("LV6 Dopo la casa il patrimonio è più basso di almeno 40.000 €", (senza.valore(43) ?? 0) - (con.valore(43) ?? 0) >= 40_000 - 0.01)
            }
        }

        // LV10. Velocità: un ricalcolo (a ogni passo del trascinamento) ben sotto i 5 ms.
        do {
            var i = ingresso(rendimento: 1.5, movimenti: (0..<8).map { MovimentoLineaVita(id: "m\($0)", eta: 42 + $0 * 5, importo: -5_000, perAnni: 3) })
            let inizio = DispatchTime.now().uptimeNanoseconds
            var somma = 0.0
            for passo in 0..<200 {
                i.etaPensione = 55 + passo % 18
                somma += MotoreLineaVita.calcola(i).allaPensione
            }
            let ms = Double(DispatchTime.now().uptimeNanoseconds - inizio) / 1_000_000 / 200
            print("Linea della vita: un ricalcolo in \(String(format: "%.3f", ms)) ms")
            verifica.vero("LV10 Un ricalcolo sotto i 5 ms", ms < 5 && somma.isFinite)
        }
    }
}
