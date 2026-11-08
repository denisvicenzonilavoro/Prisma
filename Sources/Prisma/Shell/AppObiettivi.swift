import SwiftUI

/// App Obiettivi (.os-app-goals): i progetti del cliente con un importo e una data.
/// L'accantonato conta anche il valore delle posizioni collegate; l'app calcola quanto
/// manca e il versamento mensile per arrivare in tempo. Gli eventi di vita suggeriscono gli obiettivi.
struct AppObiettivi: View {
    @Environment(StatoShell.self) var stato
    @State var modulo: Obiettivo?
    @State var confermaEliminazione = false

    private var cliente: String { stato.clienteAttivoId }
    private var elenco: [Obiettivo] { stato.obiettiviCliente(cliente) }
    private var scelto: Obiettivo? { elenco.first { $0.id == stato.obiettivoSelezionato } ?? elenco.first }

    /// Le colonne delle tessere: sul Mac due; sull'iPad quante ne stanno con la larghezza minima della tessera
    /// (in verticale una sola, così cifre e date non si troncano).
    #if os(iOS)
    private static let colonneTessere = [GridItem(.adaptive(minimum: Tema.Misura.DossierCliente.tesseraObiettivoMinima),
                                                  spacing: Tema.Misura.DossierCliente.spazioGriglia)]
    #else
    private static let colonneTessere = [GridItem(.flexible(), spacing: Tema.Misura.DossierCliente.spazioGriglia),
                                         GridItem(.flexible(), spacing: Tema.Misura.DossierCliente.spazioGriglia)]
    #endif

    var body: some View {
        let _ = ContaCorpi.segna()
        CorniceStrumento(
            notaStato: "Calcoli eseguiti in locale · piano a rendimento costante, probabilità da scenari simulati · nessuna garanzia di risultato",
            notaDestra: "\(elenco.count) \(elenco.count == 1 ? "obiettivo" : "obiettivi")"
        ) {
            rail
        } contenuto: {
            if elenco.isEmpty {
                vuoto
            } else {
                HStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            TitoloStrumento(occhiello: "Il quaderno dei progetti", titolo: "Un nome al futuro.",
                                            testo: "Ogni obiettivo ha un importo e una data: Prisma calcola quanto manca e quanto mettere da parte ogni mese.")
                            LazyVGrid(columns: Self.colonneTessere, spacing: Tema.Misura.DossierCliente.spazioGriglia) {
                                ForEach(elenco) { o in
                                    TesseraObiettivo(obiettivo: o, posizioni: stato.posizioniCliente(cliente), attiva: o.id == scelto?.id) {
                                        stato.obiettivoSelezionato = o.id
                                    }
                                }
                            }
                            // Probabilità e posizioni dell'obiettivo scelto: a tutta larghezza, sotto le schede
                            if let o = scelto {
                                lavoroObiettivo(o)
                            }
                            suggerimenti
                        }
                        .padding(EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Il dettaglio nello stesso contenitore dell'elenco laterale, diviso da un filo
                    if let o = scelto {
                        DivisoreColonne()
                        #if os(iOS)
                        // iPad: il dettaglio si stringe fino a `colonnaMinima` perché le schede restino leggibili
                        dettaglio(o)
                            .colonnaFissaAdattiva(Misure.ColonneStrumento.dettaglio)
                        #elseif os(macOS)
                        dettaglio(o)
                            .colonnaFissa(Misure.ColonneStrumento.dettaglio)
                        #endif
                    }
                }
            }
        }
        // Tema Apple (iPhone e iPad; sul Mac gli obiettivi stanno nel dossier): cornice, testate, pannelli e pulsanti
        .strumentiApple()
        .altreAppApple()
        .sheet(item: $modulo) { o in
            ModuloObiettivo(bozza: o, nuovo: !stato.dati.obiettivi.contains { $0.id == o.id }) { stato.salvaObiettivo($0) }
        }
        .alert("Eliminare l'obiettivo?", isPresented: $confermaEliminazione) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) { if let o = scelto { stato.eliminaObiettivo(o.id) } }
        } message: {
            Text("Le posizioni collegate restano in Posizioni.")
        }
    }

    private func nuovo(_ titolo: String = "", area: AreaBisogno = .patrimonio, anno: Int? = nil) {
        modulo = AiutiObiettivi.nuovo(clienteId: cliente, titolo: titolo, area: area, anno: anno)
    }

    // MARK: - Elenco laterale

    @ViewBuilder private var rail: some View {
        DossierRail()
        EtichettaRail(testo: "Obiettivi")
        VStack(spacing: 0) {
            ForEach(elenco) { o in
                VoceNavigazione(titolo: o.titolo, colore: Colori.Bisogni.area(o.area), attiva: o.id == scelto?.id) {
                    stato.obiettivoSelezionato = o.id
                }
            }
        }
        Button { nuovo() } label: { Label("Nuovo obiettivo", systemImage: "plus") }
            .buttonStyle(StileVetro())
            .padding(.top, 4)
        CollegatiRail(app: [.simulazioni, .analisi360, .posizioni])
    }

    private var vuoto: some View {
        VStack(spacing: 10) {
            // Il vuoto che spiega che cos'è un obiettivo e come si comincia
            VuotoGuidato(
                icona: "target",
                titolo: "Nessun obiettivo, per ora",
                perche: "Un obiettivo è un progetto con un importo e una data: la casa, gli studi dei figli, la pensione anticipata. Prisma calcola quanto manca e quanto mettere da parte ogni mese.",
                passi: [
                    ("Dagli un nome e una data", "Con «Nuovo obiettivo», qui sotto."),
                    ("Collega le posizioni che servono", "Quelle che già lavorano per quel progetto."),
                    ("Guarda il versamento mensile", "Prisma dice quanto serve ogni mese."),
                ],
                pulsante: "Nuovo obiettivo",
                azione: { nuovo() }
            )
            suggerimenti.frame(maxWidth: Tema.Misura.DossierCliente.suggerimentiVuoto)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pezzi comuni con la scheda Obiettivi del cliente (ClienteObiettivi.swift)

    /// Obiettivi suggeriti dagli eventi di vita che non ne hanno ancora uno.
    private var suggerimenti: some View {
        SuggerimentiObiettivi(eventi: stato.cliente(cliente)?.bisogni.eventi ?? [], elenco: elenco) { titolo, area, anno in
            nuovo(titolo, area: area, anno: anno)
        }
    }

    static func titoloPerEvento(_ t: EventoVita.Tipo) -> (String, AreaBisogno)? {
        AiutiObiettivi.titoloPerEvento(t)
    }

    /// Sotto le schede, per l'obiettivo scelto: la probabilità di arrivarci con la traiettoria e le posizioni
    /// da accendere o spegnere.
    private func lavoroObiettivo(_ o: Obiettivo) -> some View {
        LavoroObiettivo(obiettivo: o, posizioni: stato.posizioniCliente(cliente))
            .padding(Tema.Misura.MotoriAnalisi.riquadroObiettivo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .riquadroStrumento()
    }

    private func dettaglio(_ o: Obiettivo) -> some View {
        ScrollView {
            DettaglioObiettivo(obiettivo: o, posizioni: stato.posizioniCliente(cliente),
                               modifica: { modulo = o }, elimina: { confermaEliminazione = true })
                .padding(Tema.Misura.DossierCliente.margineDettaglio)
        }
    }
}

/// Barra di avanzamento (.os-progress): capsula nel pozzetto scuro, riempita del colore dell'area.
struct BarraAvanzamento: View {
    let quota: Double
    let colore: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous).fill(Colori.Attivita.progressoFondo)
                Capsule(style: .continuous).fill(colore)
                    .frame(width: max(0, geo.size.width * CGFloat(min(max(quota, 0), 1))))
            }
        }
        .frame(height: Misure.Attivita.progresso)
    }
}

/// Modulo dell'obiettivo.
struct ModuloObiettivo: View {
    @Environment(\.dismiss) var chiudi
    @State var bozza: Obiettivo
    let nuovo: Bool
    let salva: (Obiettivo) -> Void

    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti)

    var body: some View {
        CorniceModulo(titolo: nuovo ? "Nuovo obiettivo" : "Modifica l'obiettivo") {
            VStack(alignment: .leading, spacing: 14) {
                CampoModulo(etichetta: "Il progetto") {
                    TextField("Per esempio Anticipo per la casa", text: $bozza.titolo).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Area di vita") {
                    Picker("", selection: $bozza.area) {
                        ForEach(AreaBisogno.allCases) { Text($0.nome).tag($0) }
                    }
                    .labelsHidden().frame(width: 220)
                }
                CampoModulo(etichetta: "Importo, in euro di oggi") { euro($bozza.importo) }
                CampoModulo(etichetta: "Entro") {
                    DatePicker("", selection: $bozza.scadenza, displayedComponents: .date)
                        .labelsHidden().stileDataCampo().environment(\.locale, Formati.italiano)
                }
                CampoModulo(etichetta: "Priorità") {
                    Picker("", selection: $bozza.priorita) {
                        ForEach([Importanza.bassa, .media, .alta]) { Text($0.nome).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 220)
                }
                CampoModulo(etichetta: "Già da parte (oltre alle posizioni)") { euro($bozza.accantonato) }
                CampoModulo(etichetta: "Rendimento ipotizzato") {
                    HStack(spacing: 6) {
                        TextField("", value: $bozza.rendimento, format: Self.numero)
                            .textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing).frame(width: 70)
                        Text("% annuo, per il versamento necessario").font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
                    }
                }
                CampoModulo(etichetta: "Note") { TextField("", text: $bozza.note).textFieldStyle(.roundedBorder) }
            }
        } piede: {
            Spacer()
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuovo ? "Aggiungi" : "Salva") {
                var o = bozza
                o.titolo = o.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
                o.creatoIl = Appuntamento.alMinuto(o.creatoIl)
                salva(o)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty || bozza.importo <= 0)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: 560, height: 480)
    }

    private func euro(_ valore: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            TextField("0", value: valore, format: Self.numero)
                .textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing).frame(width: 120)
            Text("€").font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
        }
    }
}
