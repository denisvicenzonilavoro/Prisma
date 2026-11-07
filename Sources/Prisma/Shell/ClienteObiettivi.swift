import SwiftUI

/// Scheda «Obiettivi» del dossier del cliente: l'app accorpata Obiettivi vive qui
/// (`apri(.obiettivi)` porta in Clienti su questa scheda).
/// Gerarchia: in alto il quadro d'insieme (anello della quota coperta, totale, stati a semaforo, quanto serve al
/// mese), poi una tessera per obiettivo (anellino, cifra su obiettivo, stato, scadenza e mese) e un solo dettaglio,
/// quello scelto: cifre, probabilità a pallini con la traiettoria, posizioni che lavorano per lui. Le spiegazioni
/// lunghe restano a richiesta. Sta dentro lo scorrimento del dossier.
struct ObiettiviCliente: View {
    @EnvironmentObject var stato: StatoShell
    let cliente: Cliente
    @State private var modulo: Obiettivo?
    @State private var daEliminare: Obiettivo?

    var body: some View {
        let elenco = stato.obiettiviCliente(cliente.id)
        let posizioni = stato.posizioniCliente(cliente.id)
        let scelto = elenco.first { $0.id == stato.obiettivoSelezionato } ?? elenco.first
        let m = Tema.Misura.DossierCliente.self
        VStack(alignment: .leading, spacing: m.spazioBlocchi) {
            testata(elenco)
            if elenco.isEmpty {
                vuoto(elenco)
            } else {
                quadro(elenco, posizioni: posizioni)
                GrigliaTessereObiettivi(minima: m.tesseraObiettivoMinima, massimoColonne: m.colonneTessereObiettivi,
                                        spazio: m.spazioGriglia) {
                    ForEach(elenco) { o in
                        TesseraObiettivo(obiettivo: o, posizioni: posizioni, attiva: o.id == scelto?.id) {
                            stato.obiettivoSelezionato = o.id
                        }
                    }
                }
                if let o = scelto {
                    ObiettivoScelto(obiettivo: o, posizioni: posizioni,
                                    modifica: { modulo = o }, elimina: { daEliminare = o })
                }
                SuggerimentiObiettivi(eventi: cliente.bisogni.eventi, elenco: elenco) { titolo, area, anno in
                    nuovo(titolo, area: area, anno: anno)
                }
            }
        }
        .sheet(item: $modulo) { o in
            ModuloObiettivo(bozza: o, nuovo: !stato.dati.obiettivi.contains { $0.id == o.id }) { stato.salvaObiettivo($0) }
        }
        .alert("Eliminare l'obiettivo?",
               isPresented: Binding(get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } }),
               presenting: daEliminare) { o in
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) { stato.eliminaObiettivo(o.id) }
        } message: { _ in
            Text("Le posizioni collegate restano in Posizioni.")
        }
    }

    private func nuovo(_ titolo: String = "", area: AreaBisogno = .patrimonio, anno: Int? = nil) {
        modulo = AiutiObiettivi.nuovo(clienteId: cliente.id, titolo: titolo, area: area, anno: anno)
    }

    // MARK: - Testata

    /// Occhiello con il conteggio e «Nuovo obiettivo»; sotto, in una riga leggera, gli obiettivi a parole del
    /// Profilo (si modificano lì).
    private func testata(_ elenco: [Obiettivo]) -> some View {
        let m = Tema.Misura.DossierCliente.self
        return VStack(alignment: .leading, spacing: m.spazioTestata) {
            HStack(spacing: m.spazioSintesi) {
                OcchielloSezione(titolo: "Gli obiettivi",
                                 nota: elenco.isEmpty ? nil : (elenco.count == 1 ? "1 obiettivo" : "\(elenco.count) obiettivi"))
                if !elenco.isEmpty {
                    Button { nuovo() } label: { Label("Nuovo obiettivo", systemImage: "plus") }
                        .buttonStyle(StileVetro(taglia: .compatta))
                        .disabled(stato.solaLettura)
                }
            }
            sintesi
        }
    }

    /// Il campo «Obiettivi principali» del profilo, in una riga senza riquadro.
    @ViewBuilder private var sintesi: some View {
        let testo = cliente.profilo.obiettivi.trimmingCharacters(in: .whitespacesAndNewlines)
        if !testo.isEmpty {
            let m = Tema.Misura.DossierCliente.self
            HStack(alignment: .firstTextBaseline, spacing: m.spazioSintesi) {
                Image(systemName: "quote.opening")
                    .font(Tema.Testo.didascalia)
                    .foregroundColor(Tema.Colore.inchiostroTerziario)
                    .accessibilityHidden(true)
                Text(testo)
                    .font(Tema.Testo.secondario)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(2)
                    .help(testo)
                Spacer(minLength: 0)
                Button { stato.schedaCliente = .profilo } label: { Text("Nel profilo") }
                    .buttonStyle(StileCollegamento())
                    .help("Gli obiettivi principali a parole si modificano nel Profilo")
            }
        }
    }

    // MARK: - Il quadro d'insieme

    /// Il totale degli obiettivi e la quota già coperta (l'anello, una fetta per obiettivo del colore dell'area),
    /// gli obiettivi per stato a semaforo e quanto serve al mese. Un solo riquadro.
    private func quadro(_ elenco: [Obiettivo], posizioni: [Posizione]) -> some View {
        let m = Tema.Misura.DossierCliente.self
        let avanzamenti = elenco.map { ($0, AvanzamentoObiettivo($0, posizioni: posizioni)) }
        let totale = elenco.reduce(0.0) { $0 + max($1.importo, 0) }
        let coperto = avanzamenti.reduce(0.0) { $0 + min($1.1.accantonato, max($1.0.importo, 0)) }
        let mancante = avanzamenti.reduce(0.0) { $0 + $1.1.mancante }
        let quota = totale > 0 ? coperto / totale : 1
        let stati = avanzamenti.map { StatoObiettivo($0.0, avanzamento: $0.1, posizioni: posizioni) }
        let fette = avanzamenti.map { coppia -> AnelloObiettivi.Fetta in
            let (o, a) = coppia
            return AnelloObiettivi.Fetta(id: o.id, quota: totale > 0 ? min(a.accantonato, max(o.importo, 0)) / totale : 0,
                                         colore: Colori.Bisogni.area(o.area))
        }
        let principale = HStack(alignment: .center, spacing: m.spazioCifra) {
            AnelloObiettivi(fette: fette, etichetta: "coperto", valore: "\(Int((quota * 100).rounded()))%")
            VStack(alignment: .leading, spacing: m.spazioTestiCifra) {
                Text("Totale degli obiettivi")
                    .font(Tema.Testo.secondario)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                Text(Formati.euro(totale))
                    .font(Tema.Testo.totale)
                    .tracking(Tema.Testo.spaziaturaTotale)
                    .foregroundColor(Tema.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("mancano \(Formati.euro(mancante))")
                    .font(Tema.Testo.didascalia)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                    .help("\(Formati.euro(coperto)) già da parte")
            }
        }
        let riepilogo = RiepilogoStatiObiettivi(stati: stati)
        let mese = tesseraMese(avanzamenti).fixedSize(horizontal: false, vertical: true)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: m.spazioLavoro) {
                principale
                Spacer(minLength: m.spazioLavoro)
                riepilogo
                mese.frame(width: m.tesseraMese)
            }
            VStack(alignment: .leading, spacing: m.spazioBlocchi) {
                principale
                HStack(alignment: .center, spacing: m.spazioLavoro) {
                    riepilogo
                    Spacer(minLength: 0)
                    mese.frame(width: m.tesseraMese)
                }
            }
        }
        .padding(m.quadroObiettivi)
        .frame(maxWidth: .infinity, alignment: .leading)
        .riquadroStrumento()
    }

    /// Quanto serve al mese per gli obiettivi ancora da raggiungere, con i versamenti già attivi sotto.
    private func tesseraMese(_ avanzamenti: [(Obiettivo, AvanzamentoObiettivo)]) -> some View {
        let aperti = avanzamenti.filter { $0.1.mancante > 0 }
        let servono = aperti.reduce(0.0) { $0 + ($1.1.versamentoNecessario ?? 0) }
        let attivi = aperti.reduce(0.0) { $0 + $1.1.versamentiAttivi }
        return KPI(titolo: "Al mese servono", valore: Formati.euro(servono)) {
            Text(attivi > 0 ? "attivi \(Formati.euro(attivi))" : "nessun versamento attivo")
                .minimumScaleFactor(0.85)
        }
    }

    // MARK: - Vuoto

    private func vuoto(_ elenco: [Obiettivo]) -> some View {
        VStack(spacing: Tema.Misura.DossierCliente.spazioBlocchi) {
            VuotoGuidato(
                icona: "target",
                titolo: "Nessun obiettivo, per ora",
                perche: "Un progetto con un importo e una data: Prisma calcola quanto manca e quanto mettere da parte.",
                passi: [
                    ("Nome e data", "La casa, gli studi, la pensione."),
                    ("Le posizioni", "Quelle che già lavorano per lui."),
                    ("Il mese", "Prisma dice quanto serve."),
                ],
                pulsante: "Nuovo obiettivo",
                azione: { nuovo() }
            )
            SuggerimentiObiettivi(eventi: cliente.bisogni.eventi, elenco: elenco) { titolo, area, anno in
                nuovo(titolo, area: area, anno: anno)
            }
            .frame(maxWidth: Tema.Misura.DossierCliente.suggerimentiVuoto)
        }
        .frame(maxWidth: .infinity)
    }
}

/// L'obiettivo scelto, in un solo riquadro: testata con stato e azioni, le quattro cifre, la probabilità con la
/// traiettoria e le posizioni che lavorano per lui.
struct ObiettivoScelto: View {
    let obiettivo: Obiettivo
    /// Tutte le posizioni del cliente.
    let posizioni: [Posizione]
    let modifica: () -> Void
    let elimina: () -> Void

    var body: some View {
        let o = obiettivo
        let a = AvanzamentoObiettivo(o, posizioni: posizioni)
        let m = Tema.Misura.DossierCliente.self
        let testata = TestataObiettivo(obiettivo: o, stato: StatoObiettivo(o, avanzamento: a, posizioni: posizioni))
        let azioni = AzioniObiettivo(obiettivo: o, modifica: modifica, elimina: elimina)
        VStack(alignment: .leading, spacing: m.spazioBlocchi) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: m.spazioLavoro) {
                    testata
                    Spacer(minLength: m.spazioLavoro)
                    azioni
                }
                VStack(alignment: .leading, spacing: m.spazioDettaglio) {
                    testata
                    azioni
                }
            }
            CifreObiettivo(obiettivo: o, avanzamento: a)
            if o.scadenza > Date() {
                ProbabilitaObiettivo(esito: CacheMotoriAnalisi.scenari(o, posizioni: posizioni), importo: o.importo)
            }
            PosizioniObiettivo(obiettivo: o, posizioni: posizioni)
        }
        .padding(m.margineLavoro)
        .frame(maxWidth: .infinity, alignment: .leading)
        .riquadroStrumento()
    }
}

// MARK: - Stato a semaforo

/// Lo stato di un obiettivo a colpo d'occhio. Raggiunto se il già da parte basta; altrimenti dalla probabilità di
/// arrivarci con le posizioni collegate (gli stessi scenari del dettaglio, ricordati): almeno 7 su 10 «in linea»,
/// almeno 4 su 10 «da rinforzare», sotto «non ci arriva». Scadenza passata senza l'importo: «non ci arriva».
enum StatoObiettivo: CaseIterable {
    case nonCiArriva, daRinforzare, inLinea, raggiunto

    init(_ o: Obiettivo, avanzamento a: AvanzamentoObiettivo, posizioni: [Posizione]) {
        if a.mancante <= 0 {
            self = .raggiunto
        } else if o.scadenza <= Date() {
            self = .nonCiArriva
        } else {
            let p = CacheMotoriAnalisi.scenari(o, posizioni: posizioni).probabilita
            self = p >= 0.7 ? .inLinea : (p >= 0.4 ? .daRinforzare : .nonCiArriva)
        }
    }

    var nome: String {
        switch self {
        case .raggiunto: return "Raggiunto"
        case .inLinea: return "In linea"
        case .daRinforzare: return "Da rinforzare"
        case .nonCiArriva: return "Non ci arriva"
        }
    }

    var tono: Pillola.Tono {
        switch self {
        case .raggiunto, .inLinea: return .ok
        case .daRinforzare: return .attenzione
        case .nonCiArriva: return .errore
        }
    }

    var colore: Color {
        let c = Tema.Colore.DossierCliente.self
        switch self {
        case .raggiunto: return c.statoRaggiunto
        case .inLinea: return c.statoInLinea
        case .daRinforzare: return c.statoDaRinforzare
        case .nonCiArriva: return c.statoNonCiArriva
        }
    }
}

/// Gli obiettivi per stato, uno sotto l'altro: pallino del semaforo, quanti, lo stato. Solo gli stati presenti.
struct RiepilogoStatiObiettivi: View {
    let stati: [StatoObiettivo]

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let presenti = StatoObiettivo.allCases.reversed().filter { s in stati.contains(s) }
        VStack(alignment: .leading, spacing: m.spazioStati) {
            ForEach(presenti, id: \.self) { s in
                HStack(spacing: m.spazioPallinoStato) {
                    Circle().fill(s.colore).frame(width: m.pallinoStato, height: m.pallinoStato)
                    Text("\(stati.filter { $0 == s }.count)")
                        .font(Tema.Testo.DossierCliente.conteggioStato)
                        .foregroundColor(Tema.Colore.inchiostro)
                    Text(s.nome.lowercased())
                        .font(Tema.Testo.secondario)
                        .foregroundColor(Tema.Colore.inchiostroSecondario)
                        .lineLimit(1)
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pezzi comuni (scheda del cliente e app Obiettivi su iPad)

/// Aiuti degli obiettivi: il nuovo obiettivo con i valori di partenza, i suggerimenti dagli eventi di vita, le
/// posizioni che possono lavorare per un obiettivo.
enum AiutiObiettivi {
    /// Un obiettivo nuovo: 20.000 € entro cinque anni, o entro giugno dell'anno dell'evento.
    static func nuovo(clienteId: String, titolo: String = "", area: AreaBisogno = .patrimonio, anno: Int? = nil) -> Obiettivo {
        let cal = Calendar.current
        let scadenza = anno.flatMap { cal.date(from: DateComponents(year: $0, month: 6, day: 30)) }
            ?? cal.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        return Obiettivo(clienteId: clienteId, titolo: titolo, area: area, importo: 20_000, scadenza: cal.startOfDay(for: scadenza))
    }

    static func titoloPerEvento(_ t: EventoVita.Tipo) -> (String, AreaBisogno)? {
        switch t {
        case .acquistoCasa: return ("Anticipo per la casa", .casa)
        case .studiFigli: return ("Studi dei figli", .famiglia)
        case .figlioInArrivo: return ("L'arrivo di un figlio", .famiglia)
        case .avvioAttivita: return ("Avvio dell'attività", .lavoro)
        case .pensione: return ("Capitale per la pensione", .pensione)
        case .matrimonio: return ("Progetti di coppia", .famiglia)
        case .cambioLavoro, .separazione, .eredita, .altro: return nil
        }
    }

    /// Le posizioni in essere che possono lavorare per un obiettivo (niente debiti, coperture, immobili).
    static func posizioniAdatte(_ posizioni: [Posizione]) -> [Posizione] {
        posizioni.filter { $0.stato == .inEssere && !$0.area.passivo && $0.area != .protezione && $0.area != .immobili }
    }
}

/// La tessera di un obiettivo: l'anellino della quota con il colore dell'area, il titolo e la cifra raggiunta
/// su obiettivo; sotto lo stato a semaforo, la scadenza e quanto serve al mese; le posizioni collegate come
/// canali. Il clic la sceglie.
struct TesseraObiettivo: View {
    let obiettivo: Obiettivo
    /// Le posizioni del cliente (servono le collegate).
    let posizioni: [Posizione]
    let attiva: Bool
    let azione: () -> Void

    var body: some View {
        let o = obiettivo
        let a = AvanzamentoObiettivo(o, posizioni: posizioni)
        let m = Tema.Misura.DossierCliente.self
        let colore = Colori.Bisogni.area(o.area)
        Button(action: azione) {
            VStack(alignment: .leading, spacing: m.spazioDettaglio) {
                HStack(alignment: .center, spacing: m.spazioAnelloTessera) {
                    AnelloAvanzamento(quota: a.quota, colore: colore)
                    testi(o, a, colore: colore)
                }
                piede(o, a)
                collegate(o)
            }
            .padding(m.tesseraObiettivo)
            // In griglia le tessere di una riga hanno la stessa altezza (la propone la griglia).
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .schedaColorata(colore, scelta: attiva)
        }
        .buttonStyle(StileSemplice())
    }

    /// Area e priorità, titolo, «24.000 € di 60.000 €».
    private func testi(_ o: Obiettivo, _ a: AvanzamentoObiettivo, colore: Color) -> some View {
        let m = Tema.Misura.DossierCliente.self
        return VStack(alignment: .leading, spacing: m.spazioTestiTessera) {
            HStack(alignment: .top, spacing: m.spazioTesseraObiettivo) {
                Text(o.area.nome.uppercased())
                    .font(Tipo.chip).tracking(m.spaziaturaArea).foregroundColor(colore)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: m.spazioTesseraObiettivo)
                priorita(o)
            }
            Text(o.titolo)
                .font(Tipo.schedaAreaTitolo).foregroundColor(Colori.Strumenti.schedaTitolo)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .help(o.titolo)
            Text("\(Formati.euro(a.accantonato)) di \(Formati.euro(o.importo))")
                .font(Tema.Testo.secondario).foregroundColor(Tema.Colore.inchiostroSecondario)
                .lineLimit(2).minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    /// La capsula della priorità: non si stringe mai.
    private func priorita(_ o: Obiettivo) -> some View {
        Text(o.priorita.nome.uppercased())
            .font(Tipo.bisognoArea).foregroundColor(Tema.Colore.Componenti.testoSuColore)
            .lineLimit(1)
            .padding(Tema.Misura.DossierCliente.priorita)
            .background {
                FormaVetro.arrotondata(Tema.Raggio.Strumenti.priorita).fill(Colori.Bisogni.importanza(o.priorita))
            }
            .fixedSize()
            .help("Priorità \(o.priorita.nome.lowercased())")
    }

    /// Stato a semaforo, scadenza e quanto serve al mese.
    private func piede(_ o: Obiettivo, _ a: AvanzamentoObiettivo) -> some View {
        let m = Tema.Misura.DossierCliente.self
        let stato = StatoObiettivo(o, avanzamento: a, posizioni: posizioni)
        let scadenza = Formati.meseAnno.string(from: o.scadenza)
        let necessario: Double? = a.mancante > 0 ? a.versamentoNecessario : nil
        let mese: String? = necessario.flatMap { v in v > 0 ? "\(Formati.euro(v))/mese" : nil }
        let pillola = Pillola(testo: stato.nome, tono: stato.tono).fixedSize()
        // Le cifre non si troncano mai: su una riga se c'è posto, altrimenti scadenza e mese uno sotto l'altro.
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: m.spazioTesseraObiettivo) {
                pillola
                Spacer(minLength: m.spazioTesseraObiettivo)
                testoPiede(mese.map { "\(scadenza) · \($0)" } ?? scadenza)
            }
            HStack(alignment: .center, spacing: m.spazioTesseraObiettivo) {
                pillola
                Spacer(minLength: m.spazioTesseraObiettivo)
                VStack(alignment: .trailing, spacing: m.spazioTestiTessera) {
                    testoPiede(scadenza)
                    if let mese { testoPiede(mese) }
                }
            }
            VStack(alignment: .leading, spacing: m.spazioTestiTessera) {
                pillola
                testoPiede(scadenza)
                if let mese { testoPiede(mese) }
            }
        }
        .help(mese != nil
              ? "Entro \(scadenza): servono \(Formati.euro(a.versamentoNecessario ?? 0)) al mese"
              : "Entro \(scadenza)")
    }

    /// Una riga del piede (scadenza, mese): intera, mai con i puntini.
    private func testoPiede(_ testo: String) -> some View {
        Text(testo)
            .font(Tema.Testo.didascalia)
            .foregroundColor(Tema.Colore.inchiostroSecondario)
            .lineLimit(1)
            .fixedSize()
    }

    /// Le posizioni collegate: quante e i loro canali (i nomi nell'aiuto).
    @ViewBuilder private func collegate(_ o: Obiettivo) -> some View {
        let m = Tema.Misura.DossierCliente.self
        let elenco = posizioni.filter { o.posizioniCollegate.contains($0.id) }
        if !elenco.isEmpty {
            let canali = Canale.allCases.filter { c in elenco.contains { $0.canale == c } }
            HStack(spacing: m.spazioCollegate) {
                Image(systemName: "link")
                    .font(Tema.Testo.didascalia)
                    .foregroundColor(Tema.Colore.inchiostroTerziario)
                    .accessibilityHidden(true)
                Text(elenco.count == 1 ? "1 posizione" : "\(elenco.count) posizioni")
                    .font(Tema.Testo.didascalia)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                Spacer(minLength: m.spazioCollegate)
                ForEach(canali, id: \.self) { c in
                    EtichettaCanale(canale: c, compatta: true)
                }
            }
            .help(elenco.map(\.nome).joined(separator: ", "))
        }
    }
}

/// Testata dell'obiettivo scelto: area, titolo grande con lo stato, la nota in una riga.
struct TestataObiettivo: View {
    let obiettivo: Obiettivo
    let stato: StatoObiettivo

    var body: some View {
        let o = obiettivo
        let m = Tema.Misura.DossierCliente.self
        VStack(alignment: .leading, spacing: m.spazioTestata) {
            Text(o.area.nome.uppercased())
                .font(Tipo.chip).tracking(m.spaziaturaArea).foregroundColor(Colori.Bisogni.area(o.area))
            HStack(alignment: .center, spacing: m.spazioTitoloStato) {
                Text(o.titolo)
                    .font(Tema.Testo.DossierCliente.titoloObiettivo)
                    .tracking(Tema.Testo.DossierCliente.spaziaturaTitolo)
                    .foregroundColor(Tema.Colore.inchiostro)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Pillola(testo: stato.nome, tono: stato.tono)
            }
            if !o.note.isEmpty {
                Text(o.note)
                    .font(Tema.Testo.secondario)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                    .help(o.note)
            }
        }
    }
}

/// Le azioni dell'obiettivo: Simula (consigliata) e Modifica in vista, le altre nel menu «⋯».
struct AzioniObiettivo: View {
    @EnvironmentObject var stato: StatoShell
    let obiettivo: Obiettivo
    let modifica: () -> Void
    let elimina: () -> Void

    var body: some View {
        let o = obiettivo
        HStack(spacing: Tema.Misura.DossierCliente.spazioAzioni) {
            Button { stato.simula(o) } label: { Label("Simula", systemImage: "slider.horizontal.3") }
                .buttonStyle(StileVetro(accento: true))
                .help("Simula il piano per arrivarci")
            Button(action: modifica) { Label("Modifica", systemImage: "pencil") }
                .buttonStyle(StileVetro())
                .disabled(stato.solaLettura)
            MenuAzioni(voci: { voci(o) }, taglia: .normale) {
                Image(systemName: "ellipsis")
                    .accessibilityLabel("Altre azioni")
            }
            .help("Altre azioni")
        }
        .fixedSize()
    }

    private func voci(_ o: Obiettivo) -> [VoceMenuAzioni] {
        let sola = stato.solaLettura
        return [
            VoceMenuAzioni.azione("Prospetto e report") { stato.apriProspetto(.obiettivo(o.id, report: false)) },
            VoceMenuAzioni.azione("Aggiungi un'attività", attiva: !sola) {
                var t = Attivita.nuova(clienteId: o.clienteId,
                                       scadenza: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
                t.titolo = "Verificare il piano per: \(o.titolo)"
                stato.salvaAttivita(t)
                stato.mostraAvviso("Attività aggiunta: \(t.titolo)")
            },
            VoceMenuAzioni.separatore,
            VoceMenuAzioni.azione("Elimina l'obiettivo…", attiva: !sola) { elimina() },
        ]
    }
}

/// Le quattro cifre dell'obiettivo: quanto e entro quando, già da parte, mancano, al mese.
struct CifreObiettivo: View {
    let obiettivo: Obiettivo
    let avanzamento: AvanzamentoObiettivo
    /// Due per riga (colonna stretta del dettaglio) invece di una fila.
    var aDue = false

    var body: some View {
        if aDue {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tema.Misura.Componenti.spazioTessere,
                                                         alignment: .top),
                                     count: Tema.Misura.DossierCliente.colonneCifre),
                      alignment: .leading, spacing: Tema.Misura.Componenti.spazioTessere) {
                tessere
            }
        } else {
            FasciaKPI { tessere }
        }
    }

    @ViewBuilder private var tessere: some View {
        let o = obiettivo
        let a = avanzamento
        KPI(titolo: "Obiettivo", valore: Formati.euro(o.importo)) {
            Text("entro \(Formati.meseAnno.string(from: o.scadenza))")
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
        KPI(titolo: "Già da parte", valore: Formati.euro(a.accantonato)) {
            Text("\(Int((a.quota * 100).rounded()))% dell'obiettivo")
        }
        KPI(titolo: "Mancano", valore: Formati.euro(a.mancante)) {
            Text(o.mesiMancanti > 0 ? "in \(o.mesiMancanti) mesi" : "scadenza passata")
        }
        KPI(titolo: "Al mese servono", valore: mese) {
            nota
        }
    }

    private var mese: String {
        let a = avanzamento
        if a.mancante <= 0 { return "—" }
        return a.versamentoNecessario.map { Formati.euro($0) } ?? "—"
    }

    /// Sotto il mese: i versamenti già attivi, in arancio se non bastano.
    @ViewBuilder private var nota: some View {
        let a = avanzamento
        if a.mancante <= 0 {
            Text("raggiunto")
        } else if let v = a.versamentoNecessario, v > a.versamentiAttivi {
            Text(a.versamentiAttivi > 0 ? "attivi \(Formati.euro(a.versamentiAttivi))" : "nessun versamento attivo")
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
                .foregroundColor(Colori.Analisi.attenzioneTesto)
                .help("Mancano \(Formati.euro(v - a.versamentiAttivi)) al mese al \(Formati.percentuale(obiettivo.rendimento)) annuo: si allunga la data, si riduce l'importo o si aggiunge un piano.")
        } else {
            Text("attivi \(Formati.euro(a.versamentiAttivi))")
        }
    }
}

/// La probabilità di arrivarci a colpo d'occhio: «4 possibilità su 10» con i dieci pallini, una frase con le
/// cifre e, accanto (sotto se stretto), la traiettoria degli scenari verso l'obiettivo. Il perché e le ipotesi
/// restano a richiesta.
struct ProbabilitaObiettivo: View {
    let esito: EsitoMonteCarlo
    /// L'importo dell'obiettivo, in euro di oggi.
    let importo: Double
    /// false nella colonna stretta: il grafico va sotto e più basso.
    var affianca = true

    /// true se nessuna posizione collegata si muove con i mercati: c'è un solo risultato possibile.
    private var senzaOscillazioni: Bool { esito.p90 - esito.p10 < 1 }

    private var colore: Color {
        let c = Tema.Colore.MotoriAnalisi.self
        if esito.probabilita >= 0.7 { return c.probabilitaAlta }
        if esito.probabilita >= 0.4 { return c.probabilitaMedia }
        return c.probabilitaBassa
    }

    private var titolo: String {
        if senzaOscillazioni { return esito.probabilita >= 0.5 ? "Ci arriva in ogni caso" : "Così non ci arriva" }
        if esito.probabilita >= 0.95 { return "Più di 9 possibilità su 10" }
        if esito.probabilita < 0.05 { return "Meno di 1 possibilità su 10" }
        return "\(esito.suDieci) possibilità su 10"
    }

    /// Una frase breve con le cifre.
    private var sintesi: String {
        let su = "\(Formati.euro(esito.p50)) su \(Formati.euro(esito.traguardo))"
        return senzaOscillazioni ? "A scadenza circa \(su)." : "Nel caso mediano \(su)."
    }

    /// Il perché, per esteso, con i tre casi e il metodo: a richiesta.
    private var dettaglio: [String] {
        let traguardo = Formati.euro(esito.traguardo)
        let oggi = Formati.euro(importo)
        var righe: [String]
        if senzaOscillazioni {
            righe = ["Le posizioni collegate non si muovono con i mercati (conti, gestioni separate o solo il già da parte): alla scadenza ci sarebbero circa \(Formati.euro(esito.p50)) netti, contro i \(traguardo) che servono (i \(oggi) di oggi con l'inflazione). Per una probabilità serve collegare un investimento."]
        } else {
            let quota = Formati.percentuale((esito.probabilita * 100).rounded())
            righe = ["Con le posizioni collegate, i loro versamenti e il già da parte, senza aggiungere altro: su \(CifreAnalisi.numero(Double(esito.traiettorie))) andamenti possibili dei mercati, nel \(quota) dei casi si arriva a \(traguardo) (i \(oggi) di oggi con l'inflazione). È una stima, non una previsione.",
                     "Capitale finale netto: sfavorevole \(Formati.euro(esito.p10)) (1 caso su 10 va peggio), mediano \(Formati.euro(esito.p50)), favorevole \(Formati.euro(esito.p90)) (1 caso su 10 va meglio)."]
        }
        return righe + MotoreMonteCarlo.metodo
    }

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let colonna = indicatore
            .frame(minWidth: m.colonnaProbabilita, idealWidth: m.colonnaProbabilita, maxWidth: m.colonnaProbabilita,
                   alignment: .topLeading)
        if affianca && esito.anni.count >= 2 {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: m.spazioLavoro) {
                    colonna
                    grafico.frame(minWidth: m.graficoMinimo, maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: m.spazioBlocchi) {
                    indicatore
                    grafico
                }
            }
        } else {
            VStack(alignment: .leading, spacing: m.spazioBlocchi) {
                indicatore
                if esito.anni.count >= 2 { grafico }
            }
        }
    }

    /// Occhiello, «4 possibilità su 10», i pallini, la frase e il dettaglio a richiesta.
    private var indicatore: some View {
        let m = Tema.Misura.MotoriAnalisi.self
        return VStack(alignment: .leading, spacing: m.spazioSezioni) {
            Text("PROBABILITÀ DI ARRIVARCI")
                .font(Tipo.incontroOcchiello)
                .tracking(m.spaziaturaOcchiello)
                .foregroundColor(Colori.Strumenti.occhiello)
            Text(titolo)
                .font(Tema.Testo.MotoriAnalisi.probabilita)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            PalliniProbabilita(suDieci: esito.suDieci, colore: colore)
            Text(sintesi)
                .font(Tema.Testo.secondario)
                .foregroundColor(Tema.Colore.inchiostroSecondario)
                .fixedSize(horizontal: false, vertical: true)
                .help("Importi alla scadenza, al netto delle imposte; l'obiettivo è rivalutato con l'inflazione")
            IpotesiApribili(titolo: "Come si legge", righe: dettaglio)
        }
    }

    /// La traiettoria: fascia di 8 casi su 10, mediano e obiettivo tratteggiato, con la legenda.
    private var grafico: some View {
        let c = Tema.Colore.MotoriAnalisi.self
        let m = Tema.Misura.MotoriAnalisi.self
        return VStack(alignment: .leading, spacing: m.spazioValore) {
            GraficoVentaglio(anni: esito.anni, traguardo: esito.traguardo,
                             altezza: affianca ? Tema.Misura.DossierCliente.traiettoria : m.ventaglio)
            HStack(spacing: m.spazioSezioni) {
                LegendaLinea(colore: c.mediana, testo: "Mediano")
                LegendaLinea(colore: c.traguardo, testo: "Obiettivo", tratteggio: true)
                if !senzaOscillazioni {
                    Text("Fascia: 8 casi su 10")
                        .font(Tema.Testo.didascalia)
                        .foregroundColor(c.spiegazione)
                }
            }
        }
    }
}

/// Le posizioni adatte del cliente come capsule da accendere o spegnere: accese lavorano per l'obiettivo.
struct PosizioniObiettivo: View {
    @EnvironmentObject var stato: StatoShell
    let obiettivo: Obiettivo
    /// Tutte le posizioni del cliente: qui restano quelle adatte (`AiutiObiettivi.posizioniAdatte`).
    let posizioni: [Posizione]

    var body: some View {
        let o = obiettivo
        let adatte = AiutiObiettivi.posizioniAdatte(posizioni)
        let m = Tema.Misura.DossierCliente.self
        let accese = adatte.filter { o.posizioniCollegate.contains($0.id) }.count
        VStack(alignment: .leading, spacing: m.spazioSuggerimenti) {
            HStack(spacing: m.spazioSintesi) {
                Text("LAVORANO PER L'OBIETTIVO")
                    .font(Tipo.incontroOcchiello).tracking(m.spaziaturaOcchiello).foregroundColor(Colori.Strumenti.occhiello)
                Spacer(minLength: m.spazioSintesi)
                if !adatte.isEmpty {
                    Text("\(accese) di \(adatte.count)")
                        .font(Tema.Testo.didascalia)
                        .foregroundColor(Tema.Colore.inchiostroTerziario)
                }
            }
            if adatte.isEmpty {
                Text("Nessuna posizione adatta in essere.")
                    .font(Tema.Testo.didascalia).foregroundColor(Tema.Colore.inchiostroSecondario)
            } else {
                DisposizioneAcapoRicerca(spazio: m.spazioCapsule) {
                    ForEach(adatte) { p in
                        capsula(p, collegata: o.posizioniCollegate.contains(p.id))
                    }
                }
            }
        }
    }

    private func capsula(_ p: Posizione, collegata: Bool) -> some View {
        let m = Tema.Misura.DossierCliente.self
        let c = Tema.Colore.DossierCliente.self
        return Button {
            var x = obiettivo
            x.posizioniCollegate.removeAll { $0 == p.id }
            if !collegata { x.posizioniCollegate.append(p.id) }
            stato.salvaObiettivo(x)
        } label: {
            HStack(spacing: m.spazioTestataProdotto) {
                Image(systemName: collegata ? "checkmark.circle.fill" : "circle")
                    .font(Tema.Testo.DossierCliente.simboloCapsula)
                    .foregroundColor(collegata ? c.simboloAcceso : c.simboloSpento)
                Text(p.nome)
                    .font(Tema.Testo.secondario)
                    .foregroundColor(collegata ? Tema.Colore.inchiostro : Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                Text(Formati.euroBreve(p.valore))
                    .font(Tema.Testo.didascalia)
                    .foregroundColor(Tema.Colore.inchiostroTerziario)
                    .lineLimit(1)
                EtichettaCanale(canale: p.canale, compatta: true)
            }
            .padding(m.capsulaPosizione)
            .background { FormaVetro.capsula.fill(collegata ? c.capsulaAccesa : c.capsulaSpenta) }
            .contentShape(FormaVetro.capsula)
        }
        .buttonStyle(StileSemplice())
        .disabled(stato.solaLettura)
        .help(collegata ? "Lavora per l'obiettivo: clic per toglierla" : "Clic perché lavori per l'obiettivo")
        .accessibilityAddTraits(collegata ? .isSelected : [])
    }
}

/// Probabilità con la traiettoria e posizioni che lavorano per l'obiettivo (app Obiettivi su iPad, sotto le
/// tessere).
struct LavoroObiettivo: View {
    let obiettivo: Obiettivo
    /// Tutte le posizioni del cliente.
    let posizioni: [Posizione]

    var body: some View {
        let o = obiettivo
        VStack(alignment: .leading, spacing: Tema.Misura.DossierCliente.spazioBlocchi) {
            if o.scadenza > Date() {
                ProbabilitaObiettivo(esito: CacheMotoriAnalisi.scenari(o, posizioni: posizioni), importo: o.importo)
            }
            PosizioniObiettivo(obiettivo: o, posizioni: posizioni)
        }
    }
}

/// Il dettaglio dell'obiettivo nella colonna stretta (app Obiettivi su iPad): testata con lo stato, le cifre due
/// per riga, le azioni.
struct DettaglioObiettivo: View {
    let obiettivo: Obiettivo
    /// Le posizioni del cliente (servono le collegate).
    let posizioni: [Posizione]
    let modifica: () -> Void
    let elimina: () -> Void

    var body: some View {
        let o = obiettivo
        let a = AvanzamentoObiettivo(o, posizioni: posizioni)
        VStack(alignment: .leading, spacing: Tema.Misura.DossierCliente.spazioDettaglio) {
            TestataObiettivo(obiettivo: o, stato: StatoObiettivo(o, avanzamento: a, posizioni: posizioni))
            CifreObiettivo(obiettivo: o, avanzamento: a, aDue: true)
            AzioniObiettivo(obiettivo: o, modifica: modifica, elimina: elimina)
        }
    }
}

/// Obiettivi suggeriti dagli eventi di vita che non ne hanno ancora uno, con «Crea l'obiettivo».
struct SuggerimentiObiettivi: View {
    let eventi: [EventoVita]
    let elenco: [Obiettivo]
    let crea: (String, AreaBisogno, Int) -> Void

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let proposte = eventi.compactMap { e -> (String, AreaBisogno, Int)? in
            guard let t = AiutiObiettivi.titoloPerEvento(e.tipo) else { return nil }
            let gia = elenco.contains { $0.area == t.1 && Calendar.current.component(.year, from: $0.scadenza) == e.anno }
            return gia ? nil : (t.0, t.1, e.anno)
        }
        if !proposte.isEmpty {
            VStack(alignment: .leading, spacing: m.spazioSuggerimenti) {
                Text("SUGGERITI DAGLI EVENTI DI VITA").font(Tipo.incontroOcchiello).tracking(Tema.Misura.DossierCliente.spaziaturaOcchiello).foregroundColor(Colori.Strumenti.occhiello)
                ForEach(proposte, id: \.0) { p in
                    HStack {
                        Text("\(p.0) · \(String(p.2))").font(Tipo.tabellaCella).foregroundColor(Colori.Analisi.tabellaTesto)
                        Spacer()
                        Button { crea(p.0, p.1, p.2) } label: { Label("Crea l'obiettivo", systemImage: "plus") }
                            .buttonStyle(StileVetro(margine: m.pulsanteSuggerimento))
                    }
                    .padding(.vertical, m.rigaSuggerimento)
                    .bordoBasso(Colori.Analisi.tabellaRiga)
                }
            }
        }
    }
}

/// Griglia delle tessere degli obiettivi: tante colonne quante ne stanno con la larghezza minima (al massimo
/// `massimoColonne` e mai più delle tessere), che si allargano a occupare tutta la riga. Le tessere di una riga
/// hanno la stessa altezza, quella della più alta.
struct GrigliaTessereObiettivi: Layout {
    var minima: CGFloat
    var massimoColonne: Int
    var spazio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let larghezza = larghezzaDisponibile(proposal, quante: subviews.count)
        let (_, _, altezze) = righe(larghezza, subviews: subviews)
        let altezza = altezze.reduce(0, +) + spazio * CGFloat(max(altezze.count - 1, 0))
        return CGSize(width: larghezza, height: altezza)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let (colonne, colonna, altezze) = righe(bounds.width, subviews: subviews)
        var y = bounds.minY
        for (r, altezza) in altezze.enumerated() {
            for c in 0..<colonne {
                let i = r * colonne + c
                guard i < subviews.count else { break }
                let x = bounds.minX + CGFloat(c) * (colonna + spazio)
                subviews[i].place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                                  proposal: ProposedViewSize(width: colonna, height: altezza))
            }
            y += altezza + spazio
        }
    }

    /// La larghezza proposta o, senza proposta, quella delle colonne minime.
    private func larghezzaDisponibile(_ proposal: ProposedViewSize, quante: Int) -> CGFloat {
        if let w = proposal.width, w.isFinite { return w }
        let n = max(1, min(quante, massimoColonne))
        return CGFloat(n) * minima + CGFloat(n - 1) * spazio
    }

    /// Quante colonne, la larghezza di ciascuna e l'altezza di ogni riga.
    private func righe(_ larghezza: CGFloat, subviews: Subviews) -> (Int, CGFloat, [CGFloat]) {
        let possibili = Int(((larghezza + spazio) / (minima + spazio)).rounded(.down))
        let colonne = max(1, min(subviews.count, massimoColonne, possibili))
        let colonna = max(0, (larghezza - spazio * CGFloat(colonne - 1)) / CGFloat(colonne))
        var altezze: [CGFloat] = []
        var inizio = 0
        while inizio < subviews.count {
            let fine = min(inizio + colonne, subviews.count)
            var riga: CGFloat = 0
            for i in inizio..<fine {
                riga = max(riga, subviews[i].sizeThatFits(ProposedViewSize(width: colonna, height: nil)).height)
            }
            altezze.append(riga)
            inizio = fine
        }
        return (colonne, colonna, altezze)
    }
}
