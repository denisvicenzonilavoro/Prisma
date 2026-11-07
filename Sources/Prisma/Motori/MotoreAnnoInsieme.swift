import Foundation

// MARK: - «Un anno insieme» (report per il cliente, tema Apple §4.5.2)
// Il racconto dell'anno solare in corso, dal 1° gennaio a oggi, con le cifre dei motori di Prisma. Qui solo cifre,
// senza SwiftUI e senza `Date()` nascosti (riceve `oggi`):
// - i valori all'inizio dell'anno vengono dallo storico delle posizioni (`MotoreAndamentoPortafoglio.valore`: le
//   rilevazioni, la decorrenza con il versamento iniziale e l'ultimo valore, in linea retta fra due valori noti);
//   oggi è il valore attuale di ogni posizione (`Posizione.valore`, lo stesso del riepilogo);
// - i versamenti dell'anno sono i movimenti registrati o, senza, quelli ricostruiti come nel resoconto
//   (`MotoreResoconto.versamentiRicostruiti`), fino alla data dell'ultimo valore: così valori e versamenti si
//   leggono sullo stesso periodo e l'andamento è il resto;
// - proposte accettate (con la data dell'esito), posizioni nuove, incontri fatti (agenda e incontri conclusi);
// - gli obiettivi con la quota di inizio e di fine anno (stesso calcolo di `AvanzamentoObiettivo`);
// - la protezione dal motore della famiglia (`MotoreProtezioneFamiglia`): coperture e rischi importanti scoperti;
// - i mercati: le crisi del passato cadute in quest'anno (`MotoreResistenza.crisiDelPassato`) applicate alle
//   posizioni di oggi e il calo mensile più forte nei valori registrati;
// - cosa ci aspetta: scadenze dei prossimi 12 mesi, scadenze fiscali, il prossimo incontro o il riesame.
// I rendimenti passati non dicono nulla di quelli futuri: il report lo scrive a ogni pagina.

/// L'anno del cliente, già calcolato: le pagine del report lo raccontano senza rifare conti.
struct AnnoInsieme {
    /// Il tipo di un momento della linea dell'anno (il colore lo sceglie la carta).
    enum TonoMomento {
        case incontro, novita, mercato, traguardo
    }

    /// Un momento sulla linea dell'anno.
    struct Momento: Identifiable {
        let data: Date
        let titolo: String
        let tono: TonoMomento
        var id: String { "\(Int(data.timeIntervalSinceReferenceDate))-\(titolo)" }
    }

    /// Una posizione finanziaria nell'anno: valore al 1° gennaio, versato nell'anno, valore di oggi.
    struct VoceAnno: Identifiable {
        let posizione: Posizione
        let inizio: Double
        let fine: Double
        let versato: Double
        let incassato: Double
        /// Aperta quest'anno (decorrenza dopo il 1° gennaio).
        let nuova: Bool
        var id: String { posizione.id }
    }

    /// Un incontro fatto nell'anno (appuntamento passato o incontro concluso).
    struct IncontroFatto: Identifiable {
        let id: String
        let data: Date
        let titolo: String
    }

    /// Un obiettivo con la quota raggiunta al 1° gennaio e oggi (0–1).
    struct ObiettivoAnno: Identifiable {
        let obiettivo: Obiettivo
        let quotaInizio: Double
        let quotaFine: Double
        let accantonato: Double
        var id: String { obiettivo.id }
        var avvicinato: Bool { quotaFine > quotaInizio + 0.005 }
    }

    /// Una copertura in essere e come ha attraversato l'anno.
    struct CoperturaAnno: Identifiable {
        let posizione: Posizione
        /// Attiva dal 1° gennaio a oggi.
        let tuttoAnno: Bool
        /// Partita quest'anno.
        let nuova: Bool
        var id: String { posizione.id }
    }

    /// Il calo più forte da un mese all'altro nei valori registrati delle posizioni finanziarie.
    struct Calo {
        let data: Date
        /// Frazione persa (0,05 = 5%).
        let quota: Double
        /// true se a oggi il valore è tornato almeno al livello di prima del calo.
        let ripreso: Bool
    }

    /// Una cosa da fare o che arriva nei prossimi 12 mesi.
    struct ScadenzaAnno: Identifiable {
        let id: String
        let data: Date
        let titolo: String
        var canale: Canale? = nil
    }

    let cliente: Cliente
    let anno: Int
    /// Il 1° gennaio dell'anno e il giorno del report.
    let inizio: Date
    let oggi: Date
    /// I canali del cliente (posizioni in essere o in proposta), per l'intestazione.
    let canali: [Canale]

    /// Patrimonio netto (coperture escluse, debiti tolti) al 1° gennaio e oggi.
    let patrimonioInizio: Double
    let patrimonioFine: Double
    /// Le posizioni finanziarie in essere (investimento, risparmio, previdenza), dal valore più alto.
    let voci: [VoceAnno]
    /// I premi mensili attivi oggi sulle posizioni finanziarie (0 se nessuno).
    let versamentoMensile: Double

    let accettate: [Posizione]
    let nuove: [Posizione]
    let incontri: [IncontroFatto]
    let obiettivi: [ObiettivoAnno]

    let coperture: [CoperturaAnno]
    /// Rischi importanti per la famiglia ancora scoperti, e quelli solo in proposta.
    let scoperti: [TutelaRischio]
    let inProposta: [TutelaRischio]
    let fabbisognoVita: Double
    let divarioVita: Double

    /// Le crisi del passato cadute in quest'anno, applicate alle posizioni di oggi (di solito nessuna).
    let crisi: [EsitoCrisi]
    let calo: Calo?
    let momenti: [Momento]

    let scadenze: [ScadenzaAnno]
    let prossimoIncontro: Appuntamento?
    /// Senza un incontro in agenda: entro quando fare il riesame (un anno dall'ultimo incontro).
    let riesameEntro: Date?
    let proposteAperte: [Posizione]

    var variazione: Double { patrimonioFine - patrimonioInizio }
    var finanziarieInizio: Double { voci.reduce(0) { $0 + $1.inizio } }
    var finanziarieFine: Double { voci.reduce(0) { $0 + $1.fine } }
    var versamenti: Double { voci.reduce(0) { $0 + $1.versato } }
    var incassi: Double { voci.reduce(0) { $0 + $1.incassato } }
    /// L'andamento delle posizioni finanziarie al netto di versamenti e incassi.
    var andamento: Double { finanziarieFine - finanziarieInizio - versamenti + incassi }
    /// L'andamento sulla base media del periodo (valore iniziale più metà dei versamenti netti, come Dietz).
    var andamentoPercento: Double? {
        let base = finanziarieInizio + (versamenti - incassi) / 2
        return base > 1 ? andamento / base * 100 : nil
    }
    /// true se ci sono posizioni che seguono i mercati di cui raccontare l'anno.
    var esposte: Bool { !voci.isEmpty }
    /// L'obiettivo da mettere in copertina: il più importante, poi il più vicino.
    var obiettivoPrincipale: ObiettivoAnno? {
        obiettivi.min { (-$0.obiettivo.priorita.rawValue, $0.obiettivo.scadenza) < (-$1.obiettivo.priorita.rawValue, $1.obiettivo.scadenza) }
    }
}

enum MotoreAnnoInsieme {
    /// Un calo da un mese all'altro oltre questa quota diventa un momento dell'anno («Mercati in calo»).
    static let sogliaCalo = 0.03
    /// Le soglie degli obiettivi che diventano un momento quando si superano nell'anno.
    static let traguardi: [Double] = [0.25, 0.5, 0.75, 1]
    /// Momenti al massimo sulla linea dell'anno.
    static let momentiMassimi = 6
    /// Mesi in avanti di «cosa ci aspetta».
    static let mesiAvanti = 12

    static func calcola(cliente: Cliente, posizioni: [Posizione], appuntamenti: [Appuntamento], incontri: [Incontro],
                        obiettivi: [Obiettivo], protezione: EsitoProtezioneFamiglia, oggi: Date) -> AnnoInsieme {
        let cal = Calendar.current
        let anno = cal.component(.year, from: oggi)
        let inizio = cal.date(from: DateComponents(year: anno, month: 1, day: 1)) ?? cal.startOfDay(for: oggi)
        let mie = posizioni.filter { $0.clienteId == cliente.id }
        let inEssere = mie.filter { $0.stato == .inEssere }
        func nellAnno(_ d: Date?) -> Bool { d.map { $0 >= inizio && $0 <= oggi } ?? false }

        // Canali: quelli delle posizioni in essere o in proposta, altrimenti quelli della scheda
        let presenti = Canale.allCases.filter { k in mie.contains { $0.canale == k && $0.stato != .chiusa } }
        let canali = presenti.isEmpty ? (cliente.canali.isEmpty ? [Canale.indipendente] : cliente.canali) : presenti

        // Patrimonio netto: coperture escluse, debiti in negativo (come «Nel tempo» del dossier)
        let patrimoniali = inEssere.filter { $0.area != .protezione }
        func patrimonio(al giorno: Date) -> Double {
            patrimoniali.reduce(0) { somma, p in
                let v = MotoreAndamentoPortafoglio.valore(p, al: giorno)
                return somma + (p.area.passivo ? -v : v)
            }
        }

        // Oggi: il valore attuale di ogni posizione, lo stesso del riepilogo
        let patrimonioOggi = patrimoniali.reduce(0) { $0 + ($1.area.passivo ? -$1.valore : $1.valore) }

        // Le posizioni finanziarie, con i versamenti dell'anno
        let finanziarie = inEssere.filter(\.area.proiettabile)
        let voci = finanziarie.map { p -> AnnoInsieme.VoceAnno in
            let f = flussi(p, da: inizio, a: oggi)
            return AnnoInsieme.VoceAnno(posizione: p, inizio: MotoreAndamentoPortafoglio.valore(p, al: inizio),
                                        fine: p.valore,
                                        versato: f.versati, incassato: f.incassati, nuova: nellAnno(p.decorrenza))
        }
        .sorted { ($0.fine, $0.posizione.nome) > ($1.fine, $1.posizione.nome) }
        let mensile = finanziarie.filter { $0.frequenza == .mensile }.reduce(0) { $0 + $1.premio }

        // Proposte accettate nell'anno (data dell'esito; senza, la decorrenza) e posizioni nuove
        let accettate = mie.filter { p in
            p.esito == .accettata && nellAnno(p.seguito?.esitoIl ?? p.decorrenza)
        }
        let idAccettate = Set(accettate.map(\.id))
        let nuove = inEssere.filter { !idAccettate.contains($0.id) && nellAnno($0.decorrenza) && !$0.area.passivo }

        // Incontri fatti: appuntamenti passati dell'anno e incontri conclusi senza appuntamento
        let passati = appuntamenti.filter { $0.clienteId == cliente.id && $0.inizio >= inizio && $0.inizio < oggi }
        let idAppuntamenti = Set(passati.map(\.id))
        var fatti = passati.map { a in
            AnnoInsieme.IncontroFatto(id: a.id, data: a.inizio, titolo: a.tipo == .altro ? a.titolo : a.tipo.nome)
        }
        for i in incontri where i.clienteId == cliente.id && i.stato == .concluso && i.data >= inizio && i.data < oggi {
            if let a = i.appuntamentoId, idAppuntamenti.contains(a) { continue }
            fatti.append(AnnoInsieme.IncontroFatto(id: i.id, data: i.data, titolo: i.titolo))
        }
        fatti.sort { $0.data < $1.data }

        // Gli obiettivi: quota al 1° gennaio dai valori registrati delle posizioni collegate, oggi come l'avanzamento
        let obiettiviAnno = obiettivi.filter { $0.clienteId == cliente.id }.map { o -> AnnoInsieme.ObiettivoAnno in
            let avanzamento = AvanzamentoObiettivo(o, posizioni: mie)
            return AnnoInsieme.ObiettivoAnno(obiettivo: o, quotaInizio: quota(o, posizioni: mie, al: inizio),
                                             quotaFine: avanzamento.quota, accantonato: avanzamento.accantonato)
        }
        .sorted { ($0.obiettivo.scadenza, $0.obiettivo.titolo) < ($1.obiettivo.scadenza, $1.obiettivo.titolo) }

        // La protezione
        let coperture = inEssere.filter { $0.area == .protezione }.map { p in
            AnnoInsieme.CoperturaAnno(posizione: p, tuttoAnno: (p.decorrenza.map { $0 <= inizio } ?? true),
                                      nuova: nellAnno(p.decorrenza))
        }
        let inProposta = protezione.tutele.filter { $0.importante && $0.stato == .inProposta }

        // I mercati: le crisi del passato di quest'anno e il calo mensile più forte
        let crisi = MotoreResistenza.crisi(mie, profilo: cliente.profilo).filter { $0.crisi.anno == anno && !$0.voci.isEmpty }
        let giorni = giorniDelMese(da: inizio, a: oggi)
        let serie = giorni.map { g in finanziarie.reduce(0) { $0 + MotoreAndamentoPortafoglio.valore($1, al: g) } }
        let calo = caloMaggiore(giorni: giorni, valori: serie)

        // I momenti dell'anno
        var momenti: [AnnoInsieme.Momento] = []
        if let c = calo { momenti.append(AnnoInsieme.Momento(data: c.data, titolo: "Mercati in calo", tono: .mercato)) }
        for p in accettate {
            momenti.append(AnnoInsieme.Momento(data: p.seguito?.esitoIl ?? p.decorrenza ?? oggi, titolo: p.nome, tono: .novita))
        }
        for p in nuove {
            momenti.append(AnnoInsieme.Momento(data: p.decorrenza ?? oggi, titolo: p.nome, tono: .novita))
        }
        for o in obiettivi where o.clienteId == cliente.id {
            if let t = traguardo(o, posizioni: mie, giorni: giorni) {
                momenti.append(AnnoInsieme.Momento(data: t.data, titolo: "\(o.titolo) al \(Int((t.soglia * 100).rounded()))%", tono: .traguardo))
            }
        }
        // Gli incontri riempiono la linea fino al massimo, i più recenti prima
        let posti = max(0, momentiMassimi - momenti.count)
        for i in fatti.suffix(posti) {
            momenti.append(AnnoInsieme.Momento(data: i.data, titolo: i.titolo, tono: .incontro))
        }
        momenti = Array(momenti.sorted { $0.data < $1.data }.prefix(momentiMassimi))

        // Cosa ci aspetta: scadenze delle posizioni e degli obiettivi, scadenze fiscali, il prossimo incontro
        let orizzonte = cal.date(byAdding: .month, value: mesiAvanti, to: oggi) ?? oggi
        let oggiInizio = cal.startOfDay(for: oggi)
        var scadenze: [AnnoInsieme.ScadenzaAnno] = []
        for p in inEssere where !p.area.passivo {
            guard let s = p.scadenza, s >= oggiInizio, s <= orizzonte else { continue }
            scadenze.append(AnnoInsieme.ScadenzaAnno(id: "pos-\(p.id)", data: s, titolo: "Scade «\(p.nome)»", canale: p.canale))
        }
        for o in obiettivi where o.clienteId == cliente.id && o.scadenza >= oggiInizio && o.scadenza <= orizzonte {
            scadenze.append(AnnoInsieme.ScadenzaAnno(id: "ob-\(o.id)", data: o.scadenza, titolo: "Traguardo «\(o.titolo)»"))
        }
        let fisco = MotoreFineAnno.calcola(cliente: cliente, posizioni: mie, oggi: oggi)
        for s in fisco.scadenze where s.data >= oggiInizio && s.data <= orizzonte && (s.importo ?? 0) > 0.5 {
            scadenze.append(AnnoInsieme.ScadenzaAnno(id: "fisco-\(s.id)", data: s.data, titolo: s.titolo))
        }
        scadenze.sort { ($0.data, $0.titolo) < ($1.data, $1.titolo) }

        let prossimo = appuntamenti.filter { $0.clienteId == cliente.id && $0.stato == .pianificato && $0.inizio >= oggi }
            .min { $0.inizio < $1.inizio }
        let ultimo = (appuntamenti.filter { $0.clienteId == cliente.id && $0.inizio < oggi }.map(\.inizio)
                      + incontri.filter { $0.clienteId == cliente.id && $0.data < oggi }.map(\.data)).max()
        let riesame = prossimo == nil ? ultimo.flatMap { cal.date(byAdding: .month, value: MotoreRiesame.mesiRiesame, to: $0) } : nil
        let aperte = mie.filter { $0.stato == .proposta && $0.esito != .accettata && $0.esito != .rifiutata }

        return AnnoInsieme(cliente: cliente, anno: anno, inizio: inizio, oggi: oggi, canali: canali,
                           patrimonioInizio: patrimonio(al: inizio), patrimonioFine: patrimonioOggi,
                           voci: voci, versamentoMensile: mensile,
                           accettate: accettate, nuove: nuove, incontri: fatti, obiettivi: obiettiviAnno,
                           coperture: coperture, scoperti: protezione.scoperti, inProposta: inProposta,
                           fabbisognoVita: protezione.fabbisogno, divarioVita: protezione.divario,
                           crisi: crisi, calo: calo, momenti: momenti,
                           scadenze: scadenze, prossimoIncontro: prossimo, riesameEntro: riesame, proposteAperte: aperte)
    }

    // MARK: - Versamenti dell'anno

    /// Versamenti (+) e incassi (−, restituiti positivi) di una posizione fra `da` e `a`: i movimenti registrati se
    /// c'è almeno un versamento, altrimenti quelli ricostruiti come nel resoconto fino alla data dell'ultimo valore.
    static func flussi(_ p: Posizione, da: Date, a: Date) -> (versati: Double, incassati: Double) {
        let movimenti = (p.movimenti ?? []).filter { $0.importo.isFinite && $0.importo != 0 }
        var elenco: [(data: Date, importo: Double)] = []
        if movimenti.contains(where: { $0.importo > 0 }) {
            elenco = movimenti.map { (data: $0.data, importo: $0.importo) }
        } else if let decorrenza = p.decorrenza ?? movimenti.first?.data, decorrenza <= a {
            let fine = max(min(p.dataValore ?? a, a), decorrenza)
            elenco = MotoreResoconto.versamentiRicostruiti(p, inizio: decorrenza, fine: fine, conRiscatti: movimenti.isEmpty)
            elenco += movimenti.map { (data: $0.data, importo: $0.importo) }
        }
        var versati = 0.0
        var incassati = 0.0
        for f in elenco where f.data >= da && f.data <= a {
            if f.importo > 0 { versati += f.importo } else { incassati -= f.importo }
        }
        return (versati: versati, incassati: incassati)
    }

    // MARK: - Obiettivi

    /// La quota di un obiettivo a una data: il già da parte più il valore delle posizioni collegate a quella data.
    static func quota(_ o: Obiettivo, posizioni: [Posizione], al giorno: Date) -> Double {
        guard o.importo > 0 else { return 1 }
        let collegate = posizioni.filter { o.posizioniCollegate.contains($0.id) && $0.stato == .inEssere }
        let valore = o.accantonato + collegate.reduce(0) { $0 + MotoreAndamentoPortafoglio.valore($1, al: giorno) }
        return min(1, max(0, valore / o.importo))
    }

    /// La soglia più alta superata nell'anno da un obiettivo (25, 50, 75 o 100%) e il mese in cui è successo.
    static func traguardo(_ o: Obiettivo, posizioni: [Posizione], giorni: [Date]) -> (soglia: Double, data: Date)? {
        guard giorni.count > 1 else { return nil }
        let quote = giorni.map { quota(o, posizioni: posizioni, al: $0) }
        guard let prima = quote.first else { return nil }
        var trovato: (soglia: Double, data: Date)? = nil
        for s in traguardi where prima < s {
            if let i = quote.firstIndex(where: { $0 >= s }) { trovato = (soglia: s, data: giorni[i]) }
        }
        return trovato
    }

    // MARK: - Mercati

    /// Il 1° di ogni mese dal 1° gennaio fino al mese in corso, più oggi come ultimo punto.
    static func giorniDelMese(da inizio: Date, a oggi: Date) -> [Date] {
        let cal = Calendar.current
        var giorni: [Date] = []
        var k = 0
        while k < 13, let g = cal.date(byAdding: .month, value: k, to: inizio), g < oggi {
            giorni.append(g)
            k += 1
        }
        giorni.append(oggi)
        return giorni
    }

    /// Il calo più forte da un punto al seguente, se supera la soglia; e se a oggi il valore è tornato al livello di prima.
    static func caloMaggiore(giorni: [Date], valori: [Double]) -> AnnoInsieme.Calo? {
        guard valori.count > 1, giorni.count == valori.count else { return nil }
        var migliore: (indice: Int, quota: Double)? = nil
        for i in 1..<valori.count where valori[i - 1] > 1 {
            let q = (valori[i - 1] - valori[i]) / valori[i - 1]
            if q > sogliaCalo, q > (migliore?.quota ?? 0) { migliore = (indice: i, quota: q) }
        }
        guard let m = migliore, let ultimo = valori.last else { return nil }
        return AnnoInsieme.Calo(data: giorni[m.indice], quota: m.quota, ripreso: ultimo >= valori[m.indice - 1])
    }
}
