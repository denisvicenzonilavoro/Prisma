import SwiftUI

/// Le cifre con il segno nelle viste dell'app: il meno attaccato all'importo come in `Formati`
/// («−57 €», «+2.039 €»). I documenti su carta restano con `CifreDoc` («− 57 €»).
enum CifreVista {
    /// «+2.039 €», «−620 €», «+0 €».
    static func euroSegno(_ v: Double) -> String {
        v.rounded() < 0 ? Formati.euro(v) : "+" + Formati.euro(abs(v))
    }

    /// Una sottrazione: «−57 €» anche se l'importo è positivo.
    static func togli(_ v: Double) -> String { Formati.euro(-abs(v)) }
}

// MARK: - Riscatto anno per anno

/// Il riscatto anno per anno di una polizza o di un fondo: quanto incasserebbe il cliente chiudendo il
/// contratto ogni anno, con penali, costo d'uscita, mesi di blocco, imposte e bollo, e il primo anno
/// in cui riprende almeno quanto ha versato.
struct PannelloRiscatto: View {
    let esito: EsitoRiscatto
    @State private var tutti = false
    @State private var mostraMetodo = false

    private typealias M = Tema.Misura.MotoriPosizioni
    private typealias C = Tema.Colore.MotoriPosizioni

    private var proposta: Bool { esito.posizione.stato == .proposta }

    /// Le righe da mostrare: i primi anni, il primo senza perdite, il primo senza penali e l'ultimo
    /// (tutte, se richiesto).
    private var righe: [RiscattoAnno] {
        let tutte = esito.righe
        guard !tutti, tutte.count > M.righeRiscatto + 1 else { return tutte }
        let evidenza = Set([esito.primoRecupero?.anni, esito.primoSenzaPenali?.anni, tutte.last?.anni].compactMap { $0 })
        return tutte.filter { $0.anni < M.righeRiscatto || evidenza.contains($0.anni) }
    }

    var body: some View {
        PannelloAnalisi(
            titolo: "Se riscatti, anno per anno",
            nota: "Quanto incasseresti chiudendo il contratto ogni anno, al rendimento atteso: una stima, non una previsione"
        ) {
            HStack(spacing: 8) {
                pillola
                Button { mostraMetodo.toggle() } label: {
                    Label(mostraMetodo ? "Nascondi il metodo" : "Come si calcola?",
                          systemImage: mostraMetodo ? "chevron.up" : "questionmark.circle")
                }
                .buttonStyle(StileCollegamento())
            }
        } contenuto: {
            VStack(alignment: .leading, spacing: M.spazioSezioni) {
                FasciaKPI {
                    kpiRecupero
                    kpiPenali
                    kpiBlocco
                    kpiFine
                }
                tabella
                if esito.righe.count > M.righeRiscatto + 1 {
                    Button { tutti.toggle() } label: {
                        Label(titoloTutti, systemImage: tutti ? "chevron.up" : "chevron.down")
                    }
                    .buttonStyle(StileCollegamento())
                }
                Text(frase)
                    .font(Tipo.kpiNota)
                    .foregroundColor(Colori.Analisi.kpiNota)
                    .fixedSize(horizontal: false, vertical: true)
                if mostraMetodo {
                    NotaMetodo(testo: EsitoRiscatto.criterio + "\n" + EsitoRiscatto.metodo, titolo: "Come si calcola")
                }
            }
        }
    }

    private var titoloTutti: String {
        tutti ? "Mostra solo gli anni principali" : "Mostra tutti gli anni (\(esito.righe.count))"
    }

    @ViewBuilder private var pillola: some View {
        if let r = esito.primoRecupero {
            if r.anni == 0 {
                Pillola(testo: proposta ? "Senza perdite da subito" : "Già senza perdite", tono: .ok)
            } else {
                Pillola(testo: "Senza perdite dal \(Formati.dataBreve.string(from: r.data))", tono: .ok)
            }
        } else {
            Pillola(testo: "Non riprende il versato", tono: .attenzione)
        }
    }

    // MARK: Indicatori

    private var kpiRecupero: some View {
        let r = esito.primoRecupero
        let valore: String = r.map { $0.anni == 0 ? (proposta ? "Alla firma" : "Oggi") : Formati.dataBreve.string(from: $0.data) } ?? "—"
        return KPI(titolo: "Primo riscatto senza perdite", valore: valore) {
            if let r {
                Text("\(r.annoContratto)° anno di contratto · \(Formati.euro(r.netto)) netti")
            } else {
                Text("non nei \(esito.righe.last?.anni ?? 0) anni mostrati")
            }
        }
    }

    private var kpiPenali: some View {
        let conPenali = esito.annoSenzaPenali > 1
        let valore: String = conPenali ? (esito.senzaPenaliDal.map { Formati.dataBreve.string(from: $0) } ?? "\(esito.annoSenzaPenali)° anno") : "Nessuna"
        return KPI(titolo: conPenali ? "Senza penali dal" : "Penali di riscatto", valore: valore) {
            if esito.costoUscita > 0 {
                Text("resta il costo d'uscita del \(CifreDoc.percento(esito.costoUscita, decimali: 2))")
            } else if conPenali {
                Text("dal \(esito.annoSenzaPenali)° anno di contratto")
            } else {
                Text("il contratto non le prevede")
            }
        }
    }

    private var kpiBlocco: some View {
        let valore: String = esito.riscattabileDal.map { "dal \(Formati.dataBreve.string(from: $0))" } ?? (proposta && esito.mesiBlocco != nil ? "Dopo il blocco" : "Subito")
        return KPI(titolo: "Riscatto possibile", valore: valore) {
            if let m = esito.mesiBlocco, m > 0 {
                Text("blocco di \(m) mesi dalla \(proposta ? "firma" : "decorrenza")")
            } else {
                Text("nessun periodo di blocco")
            }
        }
    }

    private var kpiFine: some View {
        let ultima = esito.righe.last
        let anni = ultima?.anni ?? 0
        return KPI(titolo: "Dopo \(anni) \(anni == 1 ? "anno" : "anni")", valore: ultima.map { Formati.euro($0.netto) } ?? "—", ultimo: true) {
            if let u = ultima {
                Text("netti · guadagno \(CifreVista.euroSegno(u.guadagno))")
            } else {
                Text("netti")
            }
        }
    }

    // MARK: Tabella

    private var tabella: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                testa("Quando", nil)
                testa("Contratto", M.colonnaContratto)
                testa("Versato", M.colonnaImporto)
                testa("Valore", M.colonnaImporto)
                testa("Penale", M.colonnaPenale)
                testa("Imposte", M.colonnaImporto)
                    .help("Imposte e bollo")
                testa("Netto", M.colonnaNetto)
                testa("Guadagno", M.colonnaImporto)
            }
            .background(Colori.Analisi.tabellaTestaAlto)
            .bordoBasso(Colori.Analisi.tabellaTestaBordo)
            ForEach(Array(righe.enumerated()), id: \.element.id) { i, r in
                riga(r)
                    .background(sfondo(r, alternata: i % 2 == 1))
                    .bordoBasso(Colori.Analisi.tabellaRiga)
            }
        }
        .contornoTabella()
        // iPad stretto: la tabella scorre in orizzontale (sul Mac non cambia niente)
        .scorreSeStretto()
    }

    private func sfondo(_ r: RiscattoAnno, alternata: Bool) -> Color {
        if r.anni == esito.primoRecupero?.anni { return C.rigaEvidenza }
        return alternata ? Colori.Analisi.tabellaAlternata : Colori.Analisi.principale
    }

    private func riga(_ r: RiscattoAnno) -> some View {
        let colore = r.possibile ? Colori.Analisi.tabellaTesto : C.rigaSpenta
        let quando: String = r.anni == 0 ? (proposta ? "Alla firma" : "Oggi") : "Tra \(r.anni) \(r.anni == 1 ? "anno" : "anni")"
        let tasse = r.imposta + r.bollo
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(quando).font(Tipo.tabellaCellaForte).foregroundColor(colore)
                Text(Formati.dataBreve.string(from: r.data)).font(Tipo.chip).foregroundColor(Colori.Analisi.kpiNota)
            }
            .lineLimit(1)
            .padding(Misure.Analisi.cellaMargine)
            .frame(maxWidth: .infinity, alignment: .leading)
            cella("\(r.annoContratto)° anno", M.colonnaContratto, colore: colore)
            cella(Formati.euro(r.versato), M.colonnaImporto, colore: colore)
            cella(Formati.euro(r.valore), M.colonnaImporto, colore: colore)
            cella(r.penalePercento > 0 ? CifreDoc.percento(r.penalePercento) : "—", M.colonnaPenale, colore: colore)
            cella(tasse > 0.5 ? CifreVista.togli(tasse) : "—", M.colonnaImporto, colore: colore)
            if r.possibile {
                cella(Formati.euro(r.netto), M.colonnaNetto, colore: colore, forte: true)
                cella(CifreVista.euroSegno(r.guadagno), M.colonnaImporto,
                      colore: r.guadagno.rounded() < 0 ? C.negativo : colore)
            } else {
                cella("non riscattabile", M.colonnaNetto, colore: C.rigaSpenta)
                cella("—", M.colonnaImporto, colore: C.rigaSpenta)
            }
        }
    }

    private func testa(_ t: String, _ larghezza: CGFloat?) -> some View {
        Text(t)
            .font(Tipo.tabellaTesta)
            .foregroundColor(Colori.Analisi.tabellaTesta)
            .lineLimit(1)
            .padding(Misure.Analisi.testaMargine)
            .frame(maxWidth: larghezza ?? .infinity, alignment: larghezza == nil ? .leading : .trailing)
            .frame(width: larghezza)
    }

    private func cella(_ t: String, _ larghezza: CGFloat, colore: Color, forte: Bool = false) -> some View {
        Text(t)
            .font(forte ? Tipo.tabellaCellaForte : Tipo.numeroTabella)
            .foregroundColor(colore)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(Misure.Analisi.cellaMargine)
            .frame(width: larghezza, alignment: .trailing)
    }

    // MARK: Frase

    private var frase: String {
        var parti: [String] = []
        if let d = esito.riscattabileDal {
            parti.append("Fino al \(Formati.dataBreve.string(from: d)) il riscatto non si può chiedere (blocco di \(esito.mesiBlocco ?? 0) mesi): le cifre di quegli anni sono in grigio.")
        }
        if let r = esito.primoRecupero {
            if r.anni == 0 {
                parti.append(proposta
                    ? "Già alla firma il netto non scende sotto quanto versato."
                    : "Chiudendo oggi si riprende già almeno quanto versato: \(Formati.euro(r.netto)) netti su \(Formati.euro(r.versato)).")
            } else {
                parti.append("Dal \(Formati.dataBreve.string(from: r.data)) (\(r.annoContratto)° anno di contratto) il netto restituisce almeno quanto versato fino a quel momento; prima, tra costi e penali, resta sotto.")
            }
        } else {
            parti.append("Negli anni mostrati il netto non torna a quanto versato: conviene tenerlo fino alla fine o rivederlo.")
        }
        if esito.annoSenzaPenali > 1, let d = esito.senzaPenaliDal {
            parti.append("Le penali finiscono il \(Formati.dataBreve.string(from: d)).")
        }
        return parti.joined(separator: " ")
    }
}

// MARK: - Gestione separata

/// La gestione separata di una polizza rivalutabile di Ramo I a colpo d'occhio: il lordo che diventa
/// accreditato (barra), le tessere del rendimento reale, del trattenuto in euro e del garantito a scadenza,
/// la garanzia e il consolidamento come gettoni. Le spiegazioni stanno nei tooltip.
/// Per una multiramo a due parti è la sola parte in gestione separata: le cifre in euro valgono sul suo valore.
struct PannelloGestioneSeparata: View {
    let esito: EsitoGestioneSeparata
    let posizione: Posizione
    /// «La gestione separata» o, per la parte di una multiramo, «La parte in gestione separata · 40%».
    var titolo = "La gestione separata"
    /// Per la parte di una multiramo: gli euro della parte, «24.800 €» (nil per il Ramo I).
    var notaQuota: String? = nil

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo

    /// true se il pannello mostra la parte in gestione separata di una multiramo.
    private var parte: Bool { notaQuota != nil }

    var body: some View {
        let nota = notaQuota.map { "Quanto rende al cliente ogni anno, su \($0)" } ?? "Quanto rende al cliente, ogni anno"
        return PannelloAnalisi(titolo: titolo, nota: nota) {
            if esito.minimoDecisivo {
                Pillola(testo: "Decide il minimo", tono: .attenzione)
            }
        } contenuto: {
            VStack(alignment: .leading, spacing: M.spazioSezioniPannello) {
                TrattoRendimento(lordo: esito.lordo, netto: esito.accreditato, colore: C.gestione, costo: costo)
                    .help(frase)
                FasciaKPI {
                    tesseraReale
                    if esito.trattenutoEuro >= 0.5 {
                        TesseraCifra(titolo: "Trattenuto in un anno", valore: Formati.euro(esito.trattenutoEuro),
                                     nota: parte ? "sul valore della parte" : (posizione.stato == .inEssere ? "sul valore di oggi" : "sul versato"))
                    }
                    if let g = esito.garantitoAScadenza {
                        TesseraCifra(titolo: "Garantito a scadenza", valore: Formati.euro(g), nota: "prima delle imposte",
                                     icona: "lock.shield")
                    }
                }
                DisposizioneAcapoRicerca(spazio: M.spazioGettoni) {
                    GettoniGaranzia.garanzia(minimo: esito.minimoGarantito, consolidamento: esito.consolidamento)
                    if let c = GettoniGaranzia.consolidamento(esito.consolidamento) { c }
                    GettoneMultiramo(icona: "questionmark.circle", testo: "Lordo ipotizzato",
                                     aiuto: "Il lordo è un'ipotesi: verificalo sul rendiconto della gestione.")
                }
            }
        }
        .help(MotoreGestioneSeparata.metodo)
    }

    /// Il rendimento tolta l'inflazione: in rosso, con la freccia in giù, se perde potere d'acquisto.
    private var tesseraReale: some View {
        let perde = esito.reale < 0
        return TesseraCifra(
            titolo: "Tolta l'inflazione",
            valore: CifreDoc.variazione(esito.reale, decimali: 2),
            nota: perde ? "perde potere d'acquisto" : "inflazione al \(CifreDoc.condizione(esito.inflazione))",
            colore: perde ? C.negativo : C.cifra,
            icona: perde ? "arrow.down.right" : "arrow.up.right")
            .help("Rendimento accreditato tolta l'inflazione ipotizzata del \(CifreDoc.condizione(esito.inflazione)) l'anno")
    }

    /// Didascalia sotto la barra: «trattenuto 1,30 punti» o «retrocede l'85% del lordo».
    private var costo: String {
        if let r = esito.retrocessione {
            return "retrocede il \(CifreDoc.percento(r, decimali: 0)) del lordo"
                + (esito.trattenutoIndicato.map { " · almeno \(Self.punti($0))" } ?? "")
        }
        return esito.trattenutoIndicato.map { "trattenuto \(Self.punti($0))" } ?? "trattenuto non indicato"
    }

    /// La spiegazione, nel tooltip della barra.
    private var frase: String {
        var parti = [parte
            ? "Sulla parte in gestione separata va al cliente il rendimento della gestione meno quanto trattiene la compagnia; i fondi seguono i mercati per conto loro."
            : "Al cliente va il rendimento della gestione meno quanto trattiene la compagnia."]
        if esito.minimoDecisivo {
            parti.append("Qui il minimo garantito alza l'accreditato sopra il \(Self.percento(esito.netto)) che resterebbe.")
        }
        if esito.reale < 0 {
            // Senza consolidamento annuo la garanzia vale solo a scadenza o al decesso
            let garanzia = esito.consolidamento == false
                ? "la garanzia vale solo a scadenza o al decesso"
                : (parte ? "il capitale della parte è garantito" : "il capitale è garantito")
            parti.append("Tolta l'inflazione ipotizzata il rendimento è negativo: \(garanzia), il potere d'acquisto no.")
        }
        parti.append("Il lordo è un'ipotesi: verificalo sul rendiconto della gestione.")
        return parti.joined(separator: " ")
    }

    /// "2,50%"
    static func percento(_ v: Double) -> String { CifreDoc.percento(v, decimali: 2) }

    /// "1,30 punti"
    static func punti(_ v: Double) -> String { "\(String(CifreDoc.percento(v, decimali: 2).dropLast())) punti" }
}

/// I gettoni della garanzia di una gestione separata (Ramo I o parte di una multiramo), con la spiegazione
/// nel tooltip.
enum GettoniGaranzia {
    /// «Capitale garantito», «Minimo 0,50%» o, senza consolidamento annuo, «Garanzia solo a scadenza».
    static func garanzia(minimo: Double?, consolidamento: Bool?) -> GettoneMultiramo {
        if consolidamento == false {
            return GettoneMultiramo(icona: "lock.open", testo: "Garanzia solo a scadenza", tono: .attenzione,
                                    aiuto: "Rivalutazione anche negativa: la garanzia vale solo a scadenza o al decesso, prima il valore può scendere.")
        }
        guard let m = minimo else {
            return GettoneMultiramo(icona: "lock.shield", testo: "Capitale garantito", tono: .ok,
                                    aiuto: "Minimo garantito non indicato: si considera garantito il capitale.")
        }
        if m > 0 {
            let testo = CifreDoc.percento(m, decimali: 2)
            return GettoneMultiramo(icona: "lock.shield", testo: "Minimo \(testo)", tono: .ok,
                                    aiuto: "Minimo garantito: ogni anno si accredita almeno il \(testo).")
        }
        return GettoneMultiramo(icona: "lock.shield", testo: "Capitale garantito", tono: .ok,
                                aiuto: "Minimo garantito 0%: è garantito il capitale.")
    }

    /// «Consolida ogni anno» (nil senza consolidamento annuo: lo dice già il gettone della garanzia).
    static func consolidamento(_ c: Bool?) -> GettoneMultiramo? {
        switch c {
        case .some(true):
            return GettoneMultiramo(icona: "checkmark.seal", testo: "Consolida ogni anno", tono: .ok,
                                    aiuto: "Consolidamento annuo: ogni anno l'accreditato resta acquisito.")
        case .none:
            return GettoneMultiramo(icona: "checkmark.seal", testo: "Consolidamento annuo", tono: .neutro,
                                    aiuto: "Consolidamento non indicato: si considera annuo.")
        case .some(false):
            return nil
        }
    }
}

// MARK: - Composizione di una multiramo

/// Le due parti di una multiramo a colpo d'occhio: la barra con quote ed euro, una tessera per parte con il
/// lordo che diventa netto, la garanzia della gestione separata e la scala SRI dei fondi, la media ponderata
/// come barre pesate, il ribilanciamento e l'SRI della combinazione come gettoni, gli avvisi sui dati mancanti.
struct PannelloComposizione: View {
    let posizione: Posizione
    /// SRI massimo del profilo del cliente: se i soli fondi lo superano ma la combinazione no, un gettone lo dice.
    var sriMassimo: Int? = nil
    /// Apre il modulo della posizione («Completa i dati») per una multiramo senza i dati delle due parti.
    var completa: (() -> Void)? = nil

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo
    private typealias T = Tema.Testo.Multiramo

    var body: some View {
        let p = posizione
        return PannelloAnalisi(
            titolo: "Composizione: gestione separata e fondi",
            nota: p.multiramoDivisa ? "Due parti con rendimenti, costi e rischio propri" : "Per ora calcolata come un comparto unico"
        ) {
            if p.quotaGestioneStimata {
                Pillola(testo: "Quota stimata", tono: .attenzione)
            }
        } contenuto: {
            VStack(alignment: .leading, spacing: M.spazioSezioniPannello) {
                BarraComposizione(gestione: p.parteGestione, euroGestione: euro(p.parteGestione), euroFondi: euro(p.parteFondi))
                if p.multiramoDivisa {
                    divisa
                } else {
                    compartoUnico
                }
                if p.quotaGestioneStimata {
                    nota("Quota in gestione separata non indicata: stimata al \(Formati.percentuale(Posizione.quotaGestionePredefinita)).",
                         colore: C.avviso)
                }
            }
        }
        .help(MotoreMultiramo.metodo)
    }

    // MARK: Le due parti

    @ViewBuilder private var divisa: some View {
        Affiancati(soglia: SoglieAffiancati.pannello, spazio: M.spazioTessere) {
            tesseraGestione
            tesseraFondi
        }
        .fixedSize(horizontal: false, vertical: true)
        EquazioneMediaPonderata(posizione: posizione)
        if let avviso = avvisoQuote {
            nota(avviso, colore: C.avviso)
        }
        DisposizioneAcapoRicerca(spazio: M.spazioGettoni) {
            gettoneRibilanciamento
            if let g = gettoneSRI { g }
        }
    }

    private var compartoUnico: some View {
        VStack(alignment: .leading, spacing: M.spazioPannello) {
            nota("Oggi Prisma calcola questa polizza come un comparto unico: indica i rendimenti della gestione separata e dei fondi per calcoli separati.",
                 colore: C.avviso)
            if let completa {
                Button { completa() } label: { Label("Completa i dati", systemImage: "pencil") }
                    .buttonStyle(StileVetro(margine: M.margineAzione))
                    .help("Apre il modulo della posizione: i dati delle due parti sono nella sezione «Composizione»")
            }
        }
    }

    /// Il lordo più alto delle due parti: le due barre lordo → netto sulla stessa scala.
    private var scala: Double { max(posizione.lordoGestione(), posizione.lordoFondi(), 0) }

    private var tesseraGestione: some View {
        let p = posizione
        return VStack(alignment: .leading, spacing: M.spazioTessera) {
            testata(C.gestione, "Gestione separata", quota: p.parteGestione)
            TrattoRendimento(lordo: p.lordoGestione(), netto: p.accreditatoGestione(), colore: C.gestione,
                             costo: costoGestione, scala: scala)
            DisposizioneAcapoRicerca(spazio: M.spazioGettoni) {
                GettoniGaranzia.garanzia(minimo: p.minimoGarantito, consolidamento: p.consolidamento)
                if let c = GettoniGaranzia.consolidamento(p.consolidamento) { c }
                if let o = origine(p.rendimentoGestione, altro: p.rendimentoFondiIndicato, quota: p.parteGestione) {
                    gettoneStimato(o)
                }
            }
        }
        .modifier(TesseraParte())
    }

    private var tesseraFondi: some View {
        let p = posizione
        return VStack(alignment: .leading, spacing: M.spazioTessera) {
            testata(C.fondi, "Fondi", quota: p.parteFondi)
            TrattoRendimento(lordo: p.lordoFondi(), netto: p.nettoFondi, colore: C.fondi,
                             costo: costoFondi, scala: scala, nomeNetto: "netto")
                .help(aiutoCostiFondi)
            sriFondi
            DisposizioneAcapoRicerca(spazio: M.spazioGettoni) {
                if let a = p.quotaAzionariaFondi {
                    GettoneMultiramo(icona: "chart.pie", testo: "Azioni \(Formati.percentuale(a))",
                                     aiuto: "Quota azionaria della parte in fondi")
                }
                gettoneVolatilita
                if p.bolloFondi > 0 {
                    GettoneMultiramo(icona: "doc.text", testo: "Bollo \(CifreDoc.percento(p.bolloFondi, decimali: 2))",
                                     aiuto: "Imposta di bollo annua sulla parte in fondi")
                }
                if let o = origine(p.rendimentoFondiIndicato, altro: p.rendimentoGestione, quota: p.parteFondi) {
                    gettoneStimato(o)
                }
            }
        }
        .modifier(TesseraParte())
    }

    /// Pallino, nome e quota della parte; sotto, i suoi euro.
    private func testata(_ colore: Color, _ nome: String, quota: Double) -> some View {
        VStack(alignment: .leading, spacing: M.spazioEtichetta) {
            HStack(alignment: .firstTextBaseline, spacing: M.spazioRiga) {
                PallinoParte(colore: colore, testo: nome)
                Spacer(minLength: M.spazioRiga)
                Text(BarraComposizione.percento(quota))
                    .font(T.quotaTessera)
                    .foregroundColor(C.media)
            }
            if let e = euro(quota) {
                Text(Formati.euro(e))
                    .font(T.euroTessera)
                    .foregroundColor(C.etichetta)
            }
        }
    }

    /// La scala SRI 1–7 della parte in fondi, con la «i» del glossario.
    private var sriFondi: some View {
        let p = posizione
        return VStack(alignment: .leading, spacing: M.spazioEtichetta) {
            HStack(spacing: M.spazioIconaGettone) {
                EtichettaConTermine(testo: "SRI dei fondi", font: T.didascalia, colore: C.etichetta)
                if p.sriFondi == nil {
                    Text("stimato").font(T.didascalia).foregroundColor(C.nota)
                }
            }
            ScalaRischio(valore: p.sriParteFondi)
        }
    }

    private var gettoneVolatilita: GettoneMultiramo {
        let p = posizione
        let v = Formati.percentuale((p.volatilitaParteFondi * 10).rounded() / 10)
        let stimata = p.volatilitaFondi == nil
        return GettoneMultiramo(icona: "waveform.path.ecg", testo: "Volatilità \(v)", tono: stimata ? .attenzione : .neutro,
                                aiuto: stimata ? "Volatilità annua della parte in fondi, stimata" : "Volatilità annua della parte in fondi")
    }

    private func gettoneStimato(_ origine: String) -> GettoneMultiramo {
        GettoneMultiramo(icona: "questionmark.circle", testo: "Lordo stimato", tono: .attenzione,
                         aiuto: "Rendimento lordo non indicato per questa parte: \(origine).")
    }

    private var gettoneRibilanciamento: GettoneMultiramo {
        if posizione.ribilanciamento == true {
            return GettoneMultiramo(icona: "arrow.triangle.2.circlepath", testo: "Ribilanciamento annuo", tono: .ok,
                                    aiuto: "Ogni anno le quote tornano al \(Formati.percentuale(posizione.parteGestione * 100)) in gestione separata")
        }
        return GettoneMultiramo(icona: "arrow.left.and.right", testo: "Nessun ribilanciamento",
                                aiuto: "Le quote cambiano con i mercati")
    }

    /// La parte in fondi oltre il profilo del cliente con la combinazione dentro: non è un'incoerenza,
    /// perché per il profilo conta l'SRI della combinazione (quello del KID scelto).
    private var gettoneSRI: GettoneMultiramo? {
        let p = posizione
        guard p.multiramoDivisa, let massimo = sriMassimo, p.sriParteFondi > massimo, p.sriComposto <= massimo else { return nil }
        let aiuto = "La parte in fondi ha SRI \(p.sriParteFondi): la combinazione resta SRI \(p.sriComposto)\(p.sri == nil ? " (stimato)" : ""), dentro il profilo del cliente (fino a \(massimo))."
        return GettoneMultiramo(icona: "checkmark.shield", testo: "Combinazione SRI \(p.sriComposto): nel profilo", tono: .ok, aiuto: aiuto)
    }

    // MARK: Testi brevi

    /// Gli euro di una parte (nil senza valore).
    private func euro(_ quota: Double) -> Double? {
        posizione.valore > 0 ? posizione.valore * quota : nil
    }

    private func nota(_ testo: String, colore: Color) -> some View {
        Text(testo)
            .font(Tipo.kpiNota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// «trattenuto 1,30 punti» o «retrocede l'85% del lordo».
    private var costoGestione: String {
        let p = posizione
        if let r = p.retrocessione {
            return "retrocede il \(CifreDoc.percento(r, decimali: 0)) del lordo"
        }
        return p.trattenuto.map { "trattenuto \(Self.punti($0)) punti" } ?? "trattenuto non indicato"
    }

    /// «costi 2,30%» o «costi non indicati».
    private var costoFondi: String {
        let p = posizione
        guard p.costoFondiElenco != nil || p.costoFondi != nil || p.costoAnnuo != nil else { return "costi non indicati" }
        return "costi \(Self.percento(p.costoParteFondi))"
    }

    /// Da dove vengono i costi dei fondi, nel tooltip.
    private var aiutoCostiFondi: String {
        let p = posizione
        let media = p.fondiIndicati && p.fondi?.contains(where: { $0.rendimento != nil }) == true ? "Lordo: media ponderata dei fondi. " : ""
        if p.costoFondiElenco != nil && p.fondi?.contains(where: { $0.costo != nil }) == true {
            return media + "Costi: media ponderata dei costi dei fondi."
        } else if p.costoFondi != nil {
            return media + "Costi dei fondi indicati nel contratto."
        } else if p.costoAnnuo != nil {
            return media + "Costi presi dal costo annuo del contratto."
        }
        return media + "Costi dei fondi non indicati."
    }

    /// Le quote non tornano al 100%: gestione separata più fondi.
    private var avvisoQuote: String? {
        let p = posizione
        guard p.quoteDaRivedere, let totale = p.totaleQuote else { return nil }
        return "Le quote fanno \(Formati.percentuale((totale * 10).rounded() / 10)) invece del 100%: i fondi pesano in proporzione alle loro quote."
    }

    /// Da dove viene il rendimento lordo di una parte, se non è indicato: ricavato dal complessivo (se c'è
    /// quello dell'altra parte), uguale al complessivo o l'ipotesi predefinita.
    private func origine(_ indicato: Double?, altro: Double?, quota: Double) -> String? {
        guard indicato == nil else { return nil }
        guard posizione.rendimentoAtteso != nil else { return "ipotesi predefinita" }
        return altro != nil && quota >= 0.1 ? "ricavato dal complessivo" : "come il complessivo"
    }

    /// "3,00%"
    static func percento(_ v: Double) -> String { CifreDoc.percento(v, decimali: 2) }

    /// "1,30" (punti percentuali, senza il segno %)
    static func punti(_ v: Double) -> String { String(CifreDoc.percento(v, decimali: 2).dropLast()) }
}

/// Tessera di vetro di una parte della multiramo: margini, larghezza piena e altezza pari alla vicina.
private struct TesseraParte: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Tema.Misura.Multiramo.margineTessera)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .vetro(.sottile, forma: .arrotondata(Tema.Misura.Multiramo.raggioTessera))
    }
}
