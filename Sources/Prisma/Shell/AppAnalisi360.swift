import SwiftUI

/// App Analisi 360 (.os-app-planning): il centro della consulenza.
/// Quattro aree (previdenza, protezione, investimenti, risparmio) lette insieme per lo stesso
/// cliente. Le ipotesi partono dalle posizioni in essere e si correggono con il cliente;
/// le coperture e i piani sono sempre quelli registrati in Posizioni, sui due canali.
struct AppAnalisi360: View {
    enum Scheda: Hashable { case sintesi, dettaglio, metodo }

    @Environment(StatoShell.self) var stato
    @State var scheda: Scheda = .sintesi
    @State var confermaRicalcolo = false

    var cliente: String { stato.clienteAttivoId }
    var posizioni: [Posizione] { stato.posizioniCliente(cliente) }

    /// L'analisi del cliente; ogni modifica viene salvata nel dossier.
    var analisi: Binding<Analisi360> {
        Binding(get: { stato.analisi360(cliente) }, set: { stato.salvaAnalisi(cliente, $0) })
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        // Il dettaglio che nasce da una card delle aree si apre sopra tutta l'app (Analisi360Apple.swift)
        PresentatoreAree360(stato: stato) {
            cornice
        }
        .onChange(of: stato.areaAnalisi) { nuova in
            scheda = .sintesi
            // Scelta un'area (anche da un'altra app), gli strumenti lasciano il posto all'analisi
            if nuova != nil, stato.strumentoAnalisi != nil { stato.scegliStrumentoAnalisi(nil) }
            // Il campo evidenziato dalla completezza dei dati vale solo nella sua area
            if let f = stato.fuocoAnalisi, f.area != nuova { stato.fuocoAnalisi = nil }
        }
        .alert("Ripartire dalle posizioni?", isPresented: $confermaRicalcolo) {
            Button("Annulla", role: .cancel) {}
            Button("Riparti") { stato.ricalcolaAnalisi(cliente) }
        } message: {
            Text("Le ipotesi modificate a mano per questo cliente verranno sostituite dai dati delle posizioni in essere.")
        }
    }

    private var cornice: some View {
        CorniceStrumento(
            notaStato: "Calcoli eseguiti in locale · conteggi semplificati, da verificare con il cliente e sui contratti",
            notaDestra: stato.analisiSalvata(cliente)
                ? "Analisi aggiornata \(analisi.wrappedValue.aggiornataIl.map { Formati.dataOra.string(from: $0) } ?? "")"
                : "Prima stesura dalle posizioni"
        ) {
            rail
        } contenuto: {
            if stato.strumentoAnalisi != nil {
                // Simulatore, scenari, confronto, TFR (le app accorpate Simulazioni e Confronti)
                StrumentiAnalisi360()
            } else if let area = stato.areaAnalisi {
                vistaArea(area)
            } else {
                // Le quattro aree nel tema Apple: anelli, cifre dai motori e dettagli che nascono dalle card
                Analisi360Apple()
            }
        }
    }

    // MARK: - Elenco laterale

    @ViewBuilder private var rail: some View {
        DossierRail()
        EtichettaRail(testo: "Il percorso")
        VStack(spacing: 0) {
            VoceNavigazione(titolo: "Panoramica", attiva: stato.areaAnalisi == nil && stato.strumentoAnalisi == nil) {
                stato.areaAnalisi = nil
                stato.scegliStrumentoAnalisi(nil)
            }
            ForEach(AreaAnalisi.allCases) { a in
                VoceNavigazione(titolo: a.nome, colore: Colori.Analisi.area(a.areaPosizioni),
                                conteggio: contratti(a).count, attiva: stato.areaAnalisi == a && stato.strumentoAnalisi == nil) {
                    stato.areaAnalisi = a
                    stato.scegliStrumentoAnalisi(nil)
                }
            }
        }
        // Gli strumenti (le app accorpate Simulazioni e Confronti): stessa finestra, stesso cliente
        EtichettaRail(testo: "Strumenti")
        VStack(spacing: 0) {
            ForEach(StrumentoAnalisi.allCases) { s in
                VoceNavigazione(titolo: s.titolo, simbolo: s.simbolo, attiva: stato.strumentoAnalisi == s) {
                    stato.scegliStrumentoAnalisi(s)
                }
            }
        }
        // Le ipotesi delle aree: con uno strumento aperto non servono (meno testo sempre visibile)
        if stato.strumentoAnalisi == nil {
            EtichettaRail(testo: "Le ipotesi")
            Text(stato.analisiSalvata(cliente)
                 ? "Corrette per questo cliente. Le coperture si leggono sempre dalle posizioni."
                 : "Ricavate dalle posizioni in essere e dall'anagrafica: rivedile con il cliente.")
                .font(Tipo.kpiNota)
                .foregroundColor(Colori.Analisi.kpiNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 3)
            if stato.analisiSalvata(cliente) {
                Button { confermaRicalcolo = true } label: {
                    Label("Riparti dalle posizioni", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(StileVetro())
                    .padding(.top, 2)
            }
        }
        CollegatiRail(app: [.posizioni, .prodotti])
    }

    /// Posizioni in essere e proposte aperte dell'area.
    func contratti(_ a: AreaAnalisi) -> [Posizione] {
        posizioni.filter { $0.area == a.areaPosizioni && ($0.stato == .inEssere || propostaAperta($0)) }
    }

    func propostaAperta(_ p: Posizione) -> Bool {
        p.stato == .proposta && p.esito != .accettata && p.esito != .rifiutata
    }

    // MARK: - Un'area

    private func vistaArea(_ area: AreaAnalisi) -> some View {
        // Ipotesi e risultati nello stesso contenitore dell'elenco laterale: testate e piedi alla stessa altezza
        ColonneAffiancate(larghezza: Misure.ColonneStrumento.elenco) {
            pannelloIpotesi(area)
        } flessibile: {
            // La scheda scelta la legge solo la colonna dei risultati (qui passa soltanto il legame): cambiando scheda
            // si ridisegna lei, non l'elenco laterale né i campi delle ipotesi
            RisultatiArea360(opzioni: schede(area), scheda: $scheda,
                             piede: analisi.wrappedValue.confermate.contains(area)
                                ? "Dati confermati con il cliente" : "Ipotesi da verificare con il cliente") {
                if area == .investimenti || area == .risparmio {
                    Button { simula(area) } label: { Label("Apri nel simulatore", systemImage: "slider.horizontal.3") }
                        .buttonStyle(StileVetro(margine: Tema.Misura.Completezza.marginePulsante))
                }
            } contenuto: { scelta in
                switch scelta {
                case .metodo:
                    NotaMetodo(testo: MotoreAnalisi.metodo(area), titolo: "Il metodo · \(area.nome)")
                case .dettaglio:
                    dettaglio(area)
                case .sintesi:
                    sintesi(area)
                }
            }
        }
        // I quattro pannelli approvati passano al tema Apple come in Posizioni: card piatte, caratteri del tema
        // ed etichetta del canale `.chA` / `.chI` (SuperficiApple.swift); contenuti e cifre restano quelli di sempre
        .superficiApple()
    }

    private func schede(_ area: AreaAnalisi) -> [(Scheda, String)] {
        switch area {
        case .protezione: return [(.sintesi, "Sintesi"), (.dettaglio, "Coperture"), (.metodo, "Metodo")]
        case .investimenti: return [(.sintesi, "Sintesi"), (.dettaglio, "Scenari"), (.metodo, "Metodo")]
        case .previdenza, .risparmio: return [(.sintesi, "Sintesi"), (.dettaglio, "Piani"), (.metodo, "Metodo")]
        }
    }

    private func simula(_ area: AreaAnalisi) {
        var s = Simulazione(clienteId: cliente, titolo: area == .investimenti ? "Ipotesi di investimento" : "Piano di risparmio")
        if area == .investimenti {
            let i = analisi.wrappedValue.investimenti
            s.capitale = i.capitale; s.versamentoMensile = i.versamentoMensile; s.anni = i.anni; s.rendimento = i.rendimento
            s.costoIngresso = i.costoIngresso; s.costoAnnuo = i.costoAnnuo; s.aliquota = i.aliquota; s.inflazione = i.inflazione
        } else {
            let r = analisi.wrappedValue.risparmio
            s.capitale = r.capitale; s.versamentoMensile = r.versamentoMensile; s.anni = r.anni; s.rendimento = r.rendimento
            s.costoIngresso = r.costoIngresso; s.costoAnnuo = r.costoAnnuo; s.aliquota = r.aliquota; s.inflazione = r.inflazione
        }
        stato.bozzaSimulazione = s
        // Il simulatore è uno strumento di Analisi 360: si apre qui, senza cambiare finestra
        stato.scegliStrumentoAnalisi(.simulatore)
    }

    // MARK: - Ipotesi

    /// Completezza dei dati: l'ipotesi usata al posto del dato, se la voce è ancora da completare (nil se no).
    private func stimata(_ voce: String) -> String? {
        stato.completezzaCliente(cliente)?.daCompletare.first { $0.id == voce }?.ipotesi
    }

    /// Completezza dei dati: il campo dell'area su cui si è aperta l'analisi.
    private func evidenziato(_ etichetta: String, _ area: AreaAnalisi) -> Bool {
        stato.fuocoAnalisi.map { $0.area == area && $0.campo == etichetta } ?? false
    }

    /// Porta in vista il campo evidenziato, se è di quest'area.
    private func portaInVista(_ proxy: ScrollViewProxy, _ area: AreaAnalisi) {
        guard stato.fuocoAnalisi?.area == area else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.ritardoFuoco) {
            withAnimation(Tema.Moto.sezioneRipiegabile) { proxy.scrollTo(FuocoAnalisi.idCampo, anchor: .center) }
        }
    }

    private func pannelloIpotesi(_ area: AreaAnalisi) -> some View {
        let a = analisi
        let T = TestiCompletezza.self
        return VStack(spacing: 0) {
            HStack {
                Text("Dati e ipotesi").font(Tipo.ipotesiTitolo)
                Spacer()
                Text(stato.analisiSalvata(cliente) ? "Salvate nel dossier" : "Dalle posizioni").font(Tipo.chip)
            }
            .foregroundColor(Colori.ColonneStrumento.testata)
            .testataColonna()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        switch area {
                        case .previdenza:
                            CampoIpotesiIntero(etichetta: T.campoEta, valore: a.previdenza.eta, intervallo: 18...85,
                                               stimata: stimata("nascita"), evidenziato: evidenziato(T.campoEta, area))
                            CampoIpotesiIntero(etichetta: "Età di pensione", valore: a.previdenza.etaPensione, intervallo: 50...75)
                            CampoIpotesi(etichetta: T.campoRedditoDesiderato, valore: a.previdenza.redditoDesiderato, unita: "€/mese",
                                         nota: "netto, in euro di oggi",
                                         stimata: stimata("redditoDesiderato"), evidenziato: evidenziato(T.campoRedditoDesiderato, area))
                            CampoIpotesi(etichetta: T.campoPensionePubblica, valore: a.previdenza.pensionePubblica, unita: "€/mese",
                                         nota: "netta: dall'estratto INPS o dalla stima contributiva",
                                         stimata: stimata("pensionePubblica"), evidenziato: evidenziato(T.campoPensionePubblica, area))
                            CampoIpotesi(etichetta: "Montante dei piani", valore: a.previdenza.capitale, nota: "valore attuale")
                            CampoIpotesi(etichetta: "Versamento", valore: a.previdenza.versamentoMensile, unita: "€/mese")
                            CampoIpotesi(etichetta: "Rendimento netto reale", valore: a.previdenza.rendimentoReale, unita: "%",
                                         nota: "già al netto di costi e inflazione", intervallo: -20...20)
                            CampoIpotesiIntero(etichetta: "Anni di integrazione", valore: a.previdenza.anniIntegrazione, intervallo: 1...50)
                        case .protezione:
                            CampoIpotesi(etichetta: T.campoFabbisogno, valore: a.protezione.fabbisognoMensile, unita: "€/mese",
                                         stimata: stimata("fabbisogno"), evidenziato: evidenziato(T.campoFabbisogno, area))
                            CampoIpotesiIntero(etichetta: "Anni di sostegno", valore: a.protezione.anniSostegno, intervallo: 0...50)
                            CampoIpotesi(etichetta: "Debiti da estinguere", valore: a.protezione.debiti, nota: "dalle posizioni: mutui e prestiti")
                            CampoIpotesi(etichetta: "Spese immediate", valore: a.protezione.speseImmediate)
                            CampoIpotesi(etichetta: "Capitale ai superstiti", valore: a.protezione.capitaleDisponibile,
                                         nota: "liquidità già destinata")
                            CampoIpotesi(etichetta: "Entrate sostitutive", valore: a.protezione.entrateSostitutive, unita: "€/mese",
                                         nota: "in caso di invalidità o malattia")
                            CampoIpotesiIntero(etichetta: "Mesi di riserva", valore: a.protezione.mesiRiserva, unita: "mesi", intervallo: 1...120)
                            CampoIpotesi(etichetta: "Riserva disponibile", valore: a.protezione.riserva)
                        case .investimenti:
                            CampoIpotesi(etichetta: "Capitale", valore: a.investimenti.capitale, nota: "dalle posizioni di investimento")
                            CampoIpotesi(etichetta: "Versamento", valore: a.investimenti.versamentoMensile, unita: "€/mese")
                            CampoIpotesiIntero(etichetta: "Orizzonte", valore: a.investimenti.anni, intervallo: 1...50)
                            CampoIpotesi(etichetta: "Rendimento lordo", valore: a.investimenti.rendimento, unita: "%", intervallo: -30...30)
                            CampoIpotesi(etichetta: "Costo d'ingresso", valore: a.investimenti.costoIngresso, unita: "%", intervallo: 0...50)
                            CampoIpotesi(etichetta: "Costo annuo", valore: a.investimenti.costoAnnuo, unita: "%", intervallo: 0...20)
                            CampoIpotesi(etichetta: "Imposte sul guadagno", valore: a.investimenti.aliquota, unita: "%", intervallo: 0...60)
                            CampoIpotesi(etichetta: "Inflazione", valore: a.investimenti.inflazione, unita: "%", intervallo: 0...20)
                            CampoIpotesi(etichetta: "Calo da mettere alla prova", valore: a.investimenti.calo, unita: "%", intervallo: 0...100)
                        case .risparmio:
                            CampoIpotesi(etichetta: "Obiettivo", valore: a.risparmio.obiettivo, nota: "in euro di oggi")
                            CampoIpotesi(etichetta: "Capitale già da parte", valore: a.risparmio.capitale)
                            CampoIpotesi(etichetta: "Versamento", valore: a.risparmio.versamentoMensile, unita: "€/mese")
                            CampoIpotesiIntero(etichetta: "Anni", valore: a.risparmio.anni, intervallo: 1...50)
                            CampoIpotesi(etichetta: "Rendimento lordo", valore: a.risparmio.rendimento, unita: "%", intervallo: -30...30)
                            CampoIpotesi(etichetta: "Costo d'ingresso", valore: a.risparmio.costoIngresso, unita: "%", intervallo: 0...50)
                            CampoIpotesi(etichetta: "Costo annuo", valore: a.risparmio.costoAnnuo, unita: "%", intervallo: 0...20)
                            CampoIpotesi(etichetta: "Imposte sul guadagno", valore: a.risparmio.aliquota, unita: "%", intervallo: 0...60)
                            CampoIpotesi(etichetta: "Inflazione", valore: a.risparmio.inflazione, unita: "%", intervallo: 0...20)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .onAppear { portaInVista(proxy, area) }
                .onChange(of: stato.fuocoAnalisi) { _ in portaInVista(proxy, area) }
            }
            HStack {
                Toggle("Confermati con il cliente", isOn: Binding(
                    get: { a.wrappedValue.confermate.contains(area) },
                    set: { attiva in
                        var x = a.wrappedValue
                        x.confermate.removeAll { $0 == area }
                        if attiva { x.confermate.append(area) }
                        a.wrappedValue = x
                    }
                ))
                .stileCasella()
                .font(Tipo.ipotesiNota)
                Spacer()
            }
            .foregroundColor(Colori.ColonneStrumento.testata)
            .piedeColonna()
        }
    }

    // MARK: - Sintesi

    @ViewBuilder private func sintesi(_ area: AreaAnalisi) -> some View {
        let a = analisi.wrappedValue
        switch area {
        case .previdenza: sintesiPrevidenza(a.previdenza)
        case .protezione: sintesiProtezione(a.protezione)
        case .investimenti: sintesiInvestimenti(a.investimenti)
        case .risparmio: sintesiRisparmio(a.risparmio)
        }
    }

    /// Versamenti e capitali delle proposte aperte dell'area (per vedere quanto cambierebbe il quadro).
    func proposte(_ area: AreaPosizione) -> (capitale: Double, mensile: Double, conteggio: Int) {
        let elenco = posizioni.filter { $0.area == area && propostaAperta($0) }
        return (elenco.reduce(0) { $0 + $1.versamentoIniziale }, elenco.reduce(0) { $0 + $1.premioAnnuo } / 12, elenco.count)
    }

    // MARK: - Dettaglio (coperture, scenari, piani)

    /// Il nome della persona assicurata da una copertura (il cliente o un familiare).
    private func nomeAssicurato(_ p: Posizione) -> String {
        guard let c = stato.cliente(cliente) else { return p.assicurato.isEmpty ? "—" : p.assicurato }
        let id = MotoreProtezioneFamiglia.assicurato(p, cliente: c)
        if id == c.id { return c.nome }
        return c.famiglia.first { $0.id == id }?.nome ?? c.nome
    }

    @ViewBuilder private func dettaglio(_ area: AreaAnalisi) -> some View {
        if area == .investimenti {
            let e = MotoreAnalisi.investimenti(analisi.wrappedValue.investimenti)
            TitoloStrumento(occhiello: "Tre strade", titolo: "Gli scenari", testo: "Il rendimento spostato di due punti in meno e in più.")
            TabellaStrumento {
                CellaTesta(testo: "Scenario")
                CellaTesta(testo: "Rendimento", larghezza: 100, destra: true)
                CellaTesta(testo: "Netto", larghezza: 120, destra: true)
                CellaTesta(testo: "Guadagno netto", larghezza: 120, destra: true)
                CellaTesta(testo: "In euro di oggi", larghezza: 120, destra: true)
            } righe: {
                ForEach(Array(e.scenari.enumerated()), id: \.offset) { i, s in
                    RigaStrumento(indice: i) {
                        CellaTabella(testo: s.nome, forte: true)
                        CellaTabella(testo: Formati.percentuale(s.rendimento), larghezza: 100, destra: true)
                        CellaTabella(testo: Formati.euro(s.esito.netto), larghezza: 120, destra: true)
                        CellaTabella(testo: Formati.euro(s.esito.guadagnoNetto), larghezza: 120, destra: true,
                                     colore: s.esito.guadagnoNetto < 0 ? Colori.Strumenti.negativo : Colori.Analisi.tabellaTesto)
                        CellaTabella(testo: Formati.euro(s.esito.reale), larghezza: 120, destra: true)
                    }
                }
            }
        }
        let elenco = contratti(area)
        TitoloStrumento(occhiello: "Dalle posizioni", titolo: area == .protezione ? "Le coperture del nucleo" : "I contratti dell'area",
                        testo: "In essere e proposte aperte, sui due canali. Un clic apre la posizione.")
        if elenco.isEmpty {
            Text("Nessuna posizione in quest'area. Aggiungila in Posizioni per vederla qui.")
                .font(Tipo.strumentoTesto)
                .foregroundColor(Colori.Analisi.kpiNota)
        } else {
            TabellaStrumento {
                CellaTesta(testo: "Posizione")
                CellaTesta(testo: "Canale", larghezza: 110)
                CellaTesta(testo: "Stato", larghezza: 90)
                CellaTesta(testo: area == .protezione ? "Capitale" : "Valore", larghezza: 110, destra: true)
                CellaTesta(testo: "Premi annui", larghezza: 100, destra: true)
                CellaTesta(testo: "Scadenza", larghezza: 96, destra: true)
            } righe: {
                ForEach(Array(elenco.enumerated()), id: \.element.id) { i, p in
                    Button { stato.apriPosizione(p) } label: {
                        RigaStrumento(indice: i) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.nome).font(Tipo.tabellaCellaForte).foregroundColor(Colori.Analisi.tabellaTesto)
                                Text(area == .protezione ? "\(p.rischio?.nome ?? "Rischio non indicato") · assicurato: \(nomeAssicurato(p))" : p.tipologia)
                                    .font(Tipo.chip).foregroundColor(Colori.Analisi.kpiNota)
                            }
                            .lineLimit(1)
                            .padding(Misure.Analisi.cellaMargine)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            EtichettaCanale(canale: p.canale, compatta: true).frame(width: 110, alignment: .leading)
                            CellaTabella(testo: p.stato == .proposta ? "Proposta" : "In essere", larghezza: 90)
                            CellaTabella(testo: Formati.euro(area == .protezione ? (p.capitaleAssicurato ?? 0) : (p.stato == .proposta ? p.versamentoIniziale : p.valore)),
                                         larghezza: 110, destra: true)
                            CellaTabella(testo: Formati.euro(p.premioAnnuo), larghezza: 100, destra: true)
                            CellaTabella(testo: p.scadenza.map { Formati.dataBreve.string(from: $0) } ?? "—", larghezza: 96, destra: true,
                                         colore: p.scadeEntro(RiepilogoPosizioni.giorniScadenza) ? Colori.Analisi.attenzioneTesto : Colori.Analisi.tabellaTesto)
                        }
                    }
                    .buttonStyle(StileSemplice())
                }
            }
        }
    }
}

/// La colonna dei risultati di un'area: le schede (Sintesi, Coperture o Scenari o Piani, Metodo), il contenuto della
/// scheda scelta e il piede. Vista a sé, l'unica che legge la scheda: un clic su una scheda rifà questa colonna (e i
/// calcoli della scheda), non tutta l'app con l'elenco laterale e i campi delle ipotesi. La scheda resta in
/// AppAnalisi360, così tornando da uno strumento si ritrova quella di prima.
private struct RisultatiArea360<Azioni: View, Contenuto: View>: View {
    let opzioni: [(AppAnalisi360.Scheda, String)]
    @Binding var scheda: AppAnalisi360.Scheda
    let piede: String
    let azioni: () -> Azioni
    let contenuto: (AppAnalisi360.Scheda) -> Contenuto

    init(opzioni: [(AppAnalisi360.Scheda, String)], scheda: Binding<AppAnalisi360.Scheda>, piede: String,
         @ViewBuilder azioni: @escaping () -> Azioni,
         @ViewBuilder contenuto: @escaping (AppAnalisi360.Scheda) -> Contenuto) {
        self.opzioni = opzioni
        _scheda = scheda
        self.piede = piede
        self.azioni = azioni
        self.contenuto = contenuto
    }

    var body: some View {
        VStack(spacing: 0) {
            SchedeRisultati(opzioni: opzioni, selezione: $scheda) {
                azioni()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    contenuto(scheda)
                }
                .padding(EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18))
            }
            HStack {
                Text(piede)
                Spacer()
            }
            .font(Tipo.chip)
            .foregroundColor(Colori.ColonneStrumento.piedeTesto)
            .piedeColonna()
        }
    }
}
