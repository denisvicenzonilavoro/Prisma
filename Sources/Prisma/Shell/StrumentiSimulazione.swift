import SwiftUI

/// Il simulatore delle ipotesi («e se…?»): testata con «Parti da una posizione», «Nuova ipotesi», «Confronta»
/// e «Salva scenario»; console a sinistra, cifra principale e grafico a destra. Senza cornice: sul Mac sta
/// negli strumenti di Analisi 360, su iPhone e iPad anche nell'app Simulazioni.
struct SimulatoreIpotesi: View {
    @EnvironmentObject var stato: StatoShell
    /// Dentro Analisi 360: «Confronta» passa allo strumento Confronto nella stessa finestra.
    var inAnalisi = false
    @State private var salvataggio: Simulazione?
    @State private var mostraMetodo = false

    private typealias M = Tema.Misura.StrumentiAnalisi
    private typealias K = Tema.Colore.StrumentiAnalisi
    private typealias F = Tema.Testo.StrumentiAnalisi
    private typealias A = Tema.Apple.Strumenti360

    private var cliente: String { stato.clienteAttivoId }
    private var salvate: [Simulazione] { stato.simulazioniCliente(cliente) }

    /// Ipotesi sul tavolo: quella in lavorazione per il cliente o una nuova.
    private var bozza: Binding<Simulazione> {
        Binding(
            get: {
                if let b = stato.bozzaSimulazione, b.clienteId == cliente { return b }
                return Self.nuova(per: cliente, stato: stato)
            },
            set: { stato.bozzaSimulazione = $0 }
        )
    }

    /// Nuova ipotesi: parte dalla liquidità del cliente, come nel template.
    static func nuova(per cliente: String, stato: StatoShell) -> Simulazione {
        var s = Simulazione(clienteId: cliente, titolo: "Nuova ipotesi")
        let liquidita = stato.posizioniCliente(cliente)
            .filter { $0.stato == .inEssere && $0.area == .liquidita }
            .reduce(0) { $0 + $1.valore }
        s.capitale = min((liquidita / 1_000).rounded() * 1_000, 10_000_000)
        s.versamentoMensile = 0
        s.anni = 10
        s.rendimento = 3
        return s
    }

    var body: some View {
        VStack(spacing: 0) {
            testata
            corpo
        }
        .sheet(item: $salvataggio) { s in
            ModuloScenario(bozza: s) { salvato in
                stato.salvaSimulazione(salvato)
                stato.bozzaSimulazione = salvato
                stato.scenariConfrontati.insert(salvato.id)
            }
        }
    }

    // MARK: - Testata

    private func titolo(_ b: Simulazione, caricato: Simulazione?) -> String {
        if let c = caricato { return "Scenario · \(c.titolo)" }
        return b.posizioneId != nil ? "Dalla posizione · \(b.titolo)" : "Nuova ipotesi"
    }

    private var testata: some View {
        let b = bozza.wrappedValue
        let caricato = salvate.first { $0.id == b.id }
        return HStack(spacing: M.spazioTestata) {
            SpiaStrumentoApple()
            VStack(alignment: .leading, spacing: M.spazioTitoloTestata) {
                Text(titolo(b, caricato: caricato))
                    .titoloTestataStrumentoApple()
                if let c = caricato, !c.stesseIpotesi(b) {
                    Text("Ipotesi modificate: salvale come nuovo scenario")
                        .carattereApple(A.notaTestata)
                        .foregroundColor(A.coloreNotaTestata)
                        .lineLimit(1)
                }
            }
            .layoutPriority(-1)
            Spacer(minLength: M.spazioTestata)
            menuPosizioni(b)
            ViewThatFits(in: .horizontal) {
                pulsanti(b, caricato: caricato, soloIcone: false)
                pulsanti(b, caricato: caricato, soloIcone: true)
            }
        }
        .testataColonna()
    }

    /// «Parti da una posizione»: le posizioni proiettabili del cliente (l'ex elenco laterale di Simulazioni).
    @ViewBuilder private func menuPosizioni(_ b: Simulazione) -> some View {
        let posizioni = stato.posizioniCliente(cliente).filter { $0.area.proiettabile && $0.stato != .chiusa }
        if !posizioni.isEmpty {
            let opzioni: [(String?, String)] = [(nil, "Parti da una posizione…")]
                + posizioni.map { p -> (String?, String) in (p.id, (p.stato == .proposta ? "Proposta · " : "") + p.nome) }
            MenuTendina(selezione: Binding<String?>(
                            get: { posizioni.contains(where: { $0.id == b.posizioneId }) ? b.posizioneId : nil },
                            set: { id in
                                guard let id, let p = posizioni.first(where: { $0.id == id }) else { return }
                                parti(da: p)
                            }),
                        opzioni: opzioni, larghezza: M.menuPosizioni)
                .help("Le ipotesi di una posizione del cliente: importi, durata, rendimento e costi")
        }
    }

    /// Le ipotesi della posizione sul tavolo (come `stato.simula(_:)`, senza cambiare finestra).
    private func parti(da p: Posizione) {
        stato.bozzaSimulazione = Simulazione(posizione: p, orizzonteCliente: stato.cliente(p.clienteId)?.profilo.orizzonteAnni)
    }

    private func etichetta(_ testo: String, _ simbolo: String, soloIcone: Bool) -> some View {
        Group {
            if soloIcone { Image(systemName: simbolo) } else { Label(testo, systemImage: simbolo) }
        }
        .help(testo)
    }

    private func pulsanti(_ b: Simulazione, caricato: Simulazione?, soloIcone: Bool) -> some View {
        HStack(spacing: M.spazioTestata) {
            Button {
                stato.bozzaSimulazione = Self.nuova(per: cliente, stato: stato)
            } label: {
                etichetta("Nuova ipotesi", "plus", soloIcone: soloIcone)
            }
            .buttonStyle(.apple)
            if let c = caricato, c.stesseIpotesi(b) {
                Button {
                    stato.confrontoA = .simulazione(c.id)
                    if stato.confrontoB == stato.confrontoA { stato.confrontoB = nil }
                    if inAnalisi { stato.scegliStrumentoAnalisi(.confronto) } else { stato.apri(.confronti) }
                } label: {
                    etichetta("Confronta", "arrow.left.arrow.right", soloIcone: soloIcone)
                }
                .buttonStyle(.apple)
            }
            Button {
                var s = b
                s.id = "sim-\(UUID().uuidString.prefix(8).lowercased())"
                s.creataIl = Appuntamento.alMinuto(Date())
                if caricato != nil || s.titolo == "Nuova ipotesi" {
                    s.titolo = "Piano \(s.anni) \(s.anni == 1 ? "anno" : "anni") · \(Formati.percentuale(s.rendimento))"
                }
                salvataggio = s
            } label: {
                etichetta("Salva scenario", "square.and.arrow.down", soloIcone: soloIcone)
            }
            .buttonStyle(.applePrimario)
        }
        .fixedSize()
    }

    // MARK: - Console e risultati

    /// Sull'iPad i risultati vogliono più spazio delle altre colonne: sotto questa larghezza vanno sotto i comandi.
    #if os(iOS)
    private static let flessibileMinimaRisultati: CGFloat? = Tema.Misura.Mobile.flessibileMinimaSimulatore
    #else
    private static let flessibileMinimaRisultati: CGFloat? = nil
    #endif

    private var corpo: some View {
        let b = bozza
        let esito = MotoreProiezione.calcola(b.wrappedValue.parametri)
        let impatto = MotoreProiezione.impattoCosti(b.wrappedValue.parametri)
        // Comandi e risultati nello stesso contenitore dell'elenco laterale, divisi da un filo
        return ColonneAffiancate(larghezza: Misure.ColonneStrumento.comandi, flessibileMinima: Self.flessibileMinimaRisultati) {
            ScrollView {
                VStack(alignment: .leading, spacing: M.spazioConsole) {
                    ComandoSimulatore(etichetta: "Capitale iniziale", valore: b.capitale, unita: "€", intervallo: 0...10_000_000, passo: 1_000,
                                      fineCursore: 500_000)
                    ComandoSimulatore(etichetta: "Versamento mensile", valore: b.versamentoMensile, unita: "€", intervallo: 0...100_000, passo: 50,
                                      fineCursore: 3_000)
                    ComandoSimulatore(etichetta: "Orizzonte",
                                      valore: Binding(get: { Double(b.wrappedValue.anni) }, set: { b.wrappedValue.anni = max(1, Int($0.rounded())) }),
                                      unita: "anni", intervallo: 1...40, passo: 1)
                    ComandoSimulatore(etichetta: "Rendimento annuo", valore: b.rendimento, unita: "%", intervallo: -10...20, passo: 0.1, decimali: 1)
                    Rectangle().fill(A.filo).frame(height: Tema.Misura.filo)
                    ComandoSimulatore(etichetta: "Costo d'ingresso", valore: b.costoIngresso, unita: "%", intervallo: 0...10, passo: 0.5, decimali: 1)
                    ComandoSimulatore(etichetta: "Costo annuo", valore: b.costoAnnuo, unita: "%", intervallo: 0...5, passo: 0.05, decimali: 2)
                    ComandoSimulatore(etichetta: "Imposte sul guadagno", valore: b.aliquota, unita: "%", intervallo: 0...43, passo: 0.5, decimali: 1)
                    ComandoSimulatore(etichetta: "Inflazione", valore: b.inflazione, unita: "%", intervallo: 0...10, passo: 0.1, decimali: 1)
                    VStack(alignment: .leading, spacing: M.spazioCanale) {
                        Text("Canale dell'ipotesi")
                            .carattereApple(A.etichettaScelta)
                            .foregroundColor(A.coloreEtichettaScelta)
                        SegmentiAnalisi(opzioni: [(Canale?.none, "Nessuno"), (.alleanza, "Alleanza"), (.indipendente, "Indip.")],
                                        selezione: b.canale)
                    }
                }
                .padding(M.margineConsole)
            }
        } flessibile: {
            ScrollView {
                VStack(alignment: .leading, spacing: M.spazioRisultati) {
                    // La cifra principale in alto, poi il grafico; il metodo resta a un clic
                    risultato(b.wrappedValue, esito, impatto)
                    GraficoProiezione(serie: [.init(id: "valore", punti: esito.punti, colore: Colori.Analisi.linea, principale: true)])
                    HStack(spacing: M.spazioLegenda) {
                        LegendaLinea(colore: Colori.Analisi.linea, testo: "Capitale ipotetico (prima delle imposte)")
                        LegendaLinea(colore: Colori.Analisi.lineaTratteggiata, testo: "Totale versato", tratteggio: true)
                        Spacer()
                        Button { mostraMetodo.toggle() } label: {
                            Label(mostraMetodo ? "Nascondi il metodo" : "Come viene calcolato?",
                                  systemImage: mostraMetodo ? "chevron.up" : "questionmark.circle")
                        }
                        .buttonStyle(.appleSobrio)
                    }
                    if mostraMetodo {
                        NotaMetodo(testo: "Il rendimento è annuo effettivo e diventa mensile equivalente: (1 + r)^(1/12) − 1. I versamenti entrano a inizio mese al netto del costo d'ingresso, che si applica anche al capitale iniziale; ogni mese si paga la quota del costo annuo. Alla fine le imposte si applicano alla sola parte che supera il versato, e il valore in euro di oggi divide il netto per l'inflazione cumulata. Rendimento costante: niente volatilità né probabilità. È lo stesso motore delle Posizioni. Le ipotesi non sono previsioni: per i prodotti reali usa costi e rendimenti del KID o del prospetto, e verifica la fiscalità specifica.",
                                   titolo: "La formula, senza scorciatoie")
                    }
                    scenariRendimento(b.wrappedValue)
                }
                // I figli si adattano alla colonna invece di allargarla
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(M.margineRisultati)
            }
        }
    }

    /// La cifra principale che si conta, i quattro dettagli in una tessera e, sotto, le ipotesi del calcolo.
    private func risultato(_ s: Simulazione, _ e: EsitoProiezione, _ impatto: Double) -> some View {
        let segno: FormatoCifra = .personalizzato({ v in (v > 0 ? "+" : "") + Formati.euro(v) })
        let crescita: String = e.guadagnoNetto < 0 ? "Variazione netta" : "Crescita netta"
        let coloreCrescita: Color = e.guadagnoNetto < 0 ? A.negativo : A.positivo
        let anni: String = s.anni == 1 ? "anno" : "anni"
        return VStack(spacing: A.spazioRisultato) {
            VStack(spacing: A.spazioCifra) {
                Text("CAPITALE FINALE IPOTETICO, AL NETTO")
                    .carattereApple(A.occhiello)
                    .foregroundColor(A.coloreOcchiello)
                NumeroCheConta(e.netto, formato: .personalizzato({ Formati.euro($0) }))
                    .carattereApple(A.cifra)
                    .foregroundColor(A.coloreCifra)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: Tema.Apple.Misura.Spazio.etichettaCanale) {
                    Text("Al termine di \(s.anni) \(anni)")
                    if let c = s.canale { EtichettaCanale(canale: c, compatta: true) }
                }
                .carattereApple(A.nota)
                .foregroundColor(A.coloreNota)
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 0) {
                dettaglio("Totale versato", e.versato, formato: .personalizzato({ Formati.euro($0) }), indice: 1)
                dettaglio(crescita, e.guadagnoNetto, formato: segno, indice: 2, colore: coloreCrescita)
                dettaglio("In euro di oggi", e.reale, formato: .personalizzato({ Formati.euro($0) }), indice: 3)
                dettaglio("Costi e imposte", e.costi + e.imposte, formato: .personalizzato({ Formati.euro($0) }), indice: 4,
                          nota: "i costi tolgono \(Formati.euro(impatto))", ultimo: true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .superficieApple(A.riquadroDettagli)
            Text(Self.ipotesi(s))
                .carattereApple(A.ipotesi)
                .foregroundColor(A.coloreIpotesi)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Le ipotesi del calcolo, scritte sotto i risultati (le stesse della console).
    static func ipotesi(_ s: Simulazione) -> String {
        "Ipotesi: rendimento \(Formati.percentuale(s.rendimento)) l'anno costante · costo d'ingresso "
            + "\(Formati.percentuale(s.costoIngresso)) · costo annuo \(Formati.percentuale(s.costoAnnuo)) · imposte "
            + "\(Formati.percentuale(s.aliquota)) sul guadagno · inflazione \(Formati.percentuale(s.inflazione)). "
            + "Stesso motore delle Posizioni; non è una previsione."
    }

    private func dettaglio(_ etichetta: String, _ valore: Double, formato: FormatoCifra, indice: Int,
                           colore: Color? = nil, nota: String? = nil, ultimo: Bool = false) -> some View {
        VStack(spacing: A.spazioDettaglio) {
            Text(etichetta)
                .carattereApple(A.etichettaDettaglio)
                .foregroundColor(A.coloreEtichettaDettaglio)
            NumeroCheConta(valore, formato: formato, indice: indice)
                .carattereApple(A.valoreDettaglio)
                .foregroundColor(colore ?? A.coloreValoreDettaglio)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let nota {
                Text(nota)
                    .carattereApple(A.notaDettaglio)
                    .foregroundColor(A.coloreEtichettaDettaglio)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, A.margineDettaglio)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .trailing) {
            if !ultimo {
                Rectangle().fill(A.filoDettagli).frame(width: Tema.Misura.filo).padding(.vertical, A.margineFiloDettaglio)
            }
        }
    }

    private func scenariRendimento(_ s: Simulazione) -> some View {
        let scenari = MotoreProiezione.scenari(s.parametri)
        return TabellaStrumento {
            CellaTesta(testo: "Se il rendimento fosse")
            CellaTesta(testo: "Rendimento", larghezza: 100, destra: true)
            CellaTesta(testo: "Netto", larghezza: 120, destra: true)
            CellaTesta(testo: "Guadagno netto", larghezza: 120, destra: true)
            CellaTesta(testo: "In euro di oggi", larghezza: 120, destra: true)
        } righe: {
            ForEach(Array(scenari.enumerated()), id: \.offset) { i, sc in
                RigaStrumento(indice: i) {
                    CellaTabella(testo: sc.nome, forte: true)
                    CellaTabella(testo: Formati.percentuale(sc.rendimento), larghezza: 100, destra: true)
                    CellaTabella(testo: Formati.euro(sc.esito.netto), larghezza: 120, destra: true)
                    CellaTabella(testo: Formati.euro(sc.esito.guadagnoNetto), larghezza: 120, destra: true,
                                 colore: sc.esito.guadagnoNetto < 0 ? A.negativo : A.coloreCella)
                    CellaTabella(testo: Formati.euro(sc.esito.reale), larghezza: 120, destra: true)
                }
            }
        }
    }
}

/// Gli scenari salvati nel dossier: elenco, poi fino a tre a confronto (grafico e tabella).
/// Senza cornice: negli strumenti di Analisi 360 e nell'app Simulazioni di iPhone e iPad.
struct ScenariSalvati: View {
    @EnvironmentObject var stato: StatoShell
    /// Dentro Analisi 360: «Carica» e «Nuova ipotesi» passano allo strumento Simulatore nella stessa finestra.
    var inAnalisi = false

    private typealias M = Tema.Misura.StrumentiAnalisi
    private typealias K = Tema.Colore.StrumentiAnalisi
    private typealias F = Tema.Testo.StrumentiAnalisi
    private typealias A = Tema.Apple.Strumenti360

    private var cliente: String { stato.clienteAttivoId }
    private var salvate: [Simulazione] { stato.simulazioniCliente(cliente) }

    private var scelti: [Simulazione] {
        let ids = stato.scenariConfrontati.isEmpty ? Set(salvate.prefix(3).map(\.id)) : stato.scenariConfrontati
        return salvate.filter { ids.contains($0.id) }.prefix(3).map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            testata
            contenuto
        }
    }

    /// Torna al simulatore (nella stessa finestra, dentro Analisi 360).
    private func alSimulatore() {
        if inAnalisi { stato.scegliStrumentoAnalisi(.simulatore) } else { stato.schedaSimulazioni = .simulatore }
    }

    private func nuovaIpotesi() {
        stato.bozzaSimulazione = SimulatoreIpotesi.nuova(per: cliente, stato: stato)
        alSimulatore()
    }

    private var testata: some View {
        HStack(spacing: M.spazioTestata) {
            SpiaStrumentoApple()
            Text("Scenari nel dossier · \(salvate.count)")
                .titoloTestataStrumentoApple()
            Spacer(minLength: M.spazioTestata)
            Button { nuovaIpotesi() } label: {
                Label("Nuova ipotesi", systemImage: "plus")
            }
            .buttonStyle(.apple)
        }
        .testataColonna()
    }

    @ViewBuilder private var contenuto: some View {
        if salvate.isEmpty {
            // Il vuoto che spiega a che cosa serve una simulazione e come si comincia
            VuotoGuidato(
                icona: "waveform.path.ecg",
                titolo: "Niente da simulare, per ora",
                perche: "Una simulazione risponde a «e se…?»: quanto diventa un capitale con un certo rendimento, costi e tasse, in euro di oggi.",
                passi: [
                    ("Scegli «Nuova ipotesi»", "Oppure parti da una posizione del cliente."),
                    ("Cambia i numeri", "Importi, anni e rendimento."),
                    ("«Salva scenario»", "E confrontalo con altri due."),
                ],
                pulsante: "Nuova ipotesi",
                azione: { nuovaIpotesi() }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let confrontati = scelti
            ScrollView {
                VStack(alignment: .leading, spacing: M.spazioContenuto) {
                    TitoloStrumento(occhiello: "Fino a tre a confronto", titolo: "Le ipotesi messe da parte")
                    TabellaStrumento {
                        CellaTesta(testo: "", larghezza: 34)
                        CellaTesta(testo: "Scenario")
                        CellaTesta(testo: "Canale", larghezza: 110)
                        CellaTesta(testo: "Ipotesi", larghezza: 210)
                        CellaTesta(testo: "", larghezza: A.colonnaAzioniScenari)
                    } righe: {
                        ForEach(Array(salvate.enumerated()), id: \.element.id) { i, s in
                            RigaStrumento(indice: i) {
                                let scelto = confrontati.contains { $0.id == s.id }
                                Button { alternaScelta(s.id, scelto: scelto) } label: {
                                    Image(systemName: scelto ? "checkmark.square.fill" : "square")
                                        .foregroundColor(scelto ? A.coloreScelto : A.coloreNonScelto)
                                        .frame(width: 34)
                                }
                                .buttonStyle(StileSemplice())
                                .help(scelto ? "Togli dal confronto" : "Metti a confronto (fino a tre)")
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(s.titolo).carattereApple(A.cellaForte).foregroundColor(A.coloreCella)
                                    Text("Salvato il \(Formati.dataEstesa.string(from: s.creataIl))")
                                        .carattereApple(A.cellaNota)
                                        .foregroundColor(A.coloreCellaNota)
                                }
                                .lineLimit(1)
                                .padding(Misure.Analisi.cellaMargine)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Group {
                                    if let c = s.canale { EtichettaCanale(canale: c, compatta: true) } else { Text("—").foregroundColor(A.coloreCellaNota) }
                                }
                                .frame(width: 110, alignment: .leading)
                                CellaTabella(testo: "\(Formati.euro(s.capitale)) + \(Formati.euro(s.versamentoMensile))/mese · \(s.anni) a · \(Formati.percentuale(s.rendimento))",
                                             larghezza: 210)
                                HStack(spacing: 6) {
                                    Button("Carica") {
                                        stato.bozzaSimulazione = s
                                        alSimulatore()
                                    }
                                    Button("Elimina") { stato.eliminaSimulazione(s.id) }
                                }
                                .buttonStyle(.apple)
                                .frame(width: A.colonnaAzioniScenari)
                            }
                        }
                    }
                    if !confrontati.isEmpty {
                        PannelloAnalisi(titolo: "Le ipotesi selezionate",
                                        nota: "Durate e versamenti possono differire") {
                            EmptyView()
                        } contenuto: {
                            VStack(alignment: .leading, spacing: 12) {
                                GraficoProiezione(serie: confrontati.enumerated().map { i, s in
                                    .init(id: s.id, punti: MotoreProiezione.calcola(s.parametri).punti,
                                          colore: Colori.Strumenti.serie[i % Colori.Strumenti.serie.count], principale: i == 0)
                                })
                                HStack(spacing: M.spazioLegenda) {
                                    ForEach(Array(confrontati.enumerated()), id: \.element.id) { i, s in
                                        LegendaLinea(colore: Colori.Strumenti.serie[i % Colori.Strumenti.serie.count], testo: s.titolo)
                                    }
                                }
                                tabellaConfronto(confrontati)
                            }
                        }
                    }
                }
                .padding(M.margineContenuto)
            }
        }
    }

    private func alternaScelta(_ id: String, scelto: Bool) {
        var ids = Set(scelti.map(\.id))
        if scelto {
            ids.remove(id)
        } else if ids.count < 3 {
            ids.insert(id)
        } else {
            stato.mostraAvviso("Puoi confrontare fino a tre scenari: deselezionane uno.")
            return
        }
        stato.scenariConfrontati = ids
    }

    private func tabellaConfronto(_ elenco: [Simulazione]) -> some View {
        TabellaStrumento {
            CellaTesta(testo: "Scenario")
            CellaTesta(testo: "Versato", larghezza: 110, destra: true)
            CellaTesta(testo: "Costi", larghezza: 100, destra: true)
            CellaTesta(testo: "Netto", larghezza: 120, destra: true)
            CellaTesta(testo: "Variazione", larghezza: 110, destra: true)
            CellaTesta(testo: "In euro di oggi", larghezza: 120, destra: true)
        } righe: {
            ForEach(Array(elenco.enumerated()), id: \.element.id) { i, s in
                let e = MotoreProiezione.calcola(s.parametri)
                RigaStrumento(indice: i) {
                    HStack(spacing: 7) {
                        Circle().fill(Colori.Strumenti.serie[i % Colori.Strumenti.serie.count]).frame(width: 8, height: 8)
                        Text(s.titolo).carattereApple(A.cellaForte).foregroundColor(A.coloreCella).lineLimit(1)
                    }
                    .padding(Misure.Analisi.cellaMargine)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    CellaTabella(testo: Formati.euro(e.versato), larghezza: 110, destra: true)
                    CellaTabella(testo: Formati.euro(e.costi), larghezza: 100, destra: true)
                    CellaTabella(testo: Formati.euro(e.netto), larghezza: 120, destra: true, forte: true)
                    CellaTabella(testo: (e.guadagnoNetto > 0 ? "+" : "") + Formati.euro(e.guadagnoNetto), larghezza: 110, destra: true,
                                 colore: e.guadagnoNetto < 0 ? A.negativo : A.positivo)
                    CellaTabella(testo: Formati.euro(e.reale), larghezza: 120, destra: true)
                }
            }
        }
    }
}
