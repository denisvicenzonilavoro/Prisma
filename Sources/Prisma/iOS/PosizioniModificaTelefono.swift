#if os(iOS)
import SwiftUI

// Le posizioni che si scrivono dall'iPhone (13 novembre 2026, giro 4 dell'iPhone): un prodotto del catalogo sul
// cliente in due passi (lo stesso MotoreProdottoCliente del Mac: si scrivono solo i dati del cliente, il resto viene
// dalla scheda) e l'aggiornamento di una posizione (valore di oggi, versato, premio, esito della proposta). Con
// «Prisma ovunque» acceso arrivano al Mac con il giornale (EntitaOvunque.posizione). Dall'iPhone non si eliminano.

private typealias M = Tema.Apple.Telefono.Moduli
private typealias E = Tema.Apple.Telefono.Elenco

/// «Dal catalogo» sull'iPhone: l'elenco dei prodotti (ricerca, canale), poi i dati del cliente.
struct ProdottoSulClienteTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    let clienteId: String
    var statoIniziale: StatoPosizione = .proposta
    @State private var ricerca = ""
    @State private var canale: Canale?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Canale", selection: $canale) {
                        Text("Tutti").tag(Canale?.none)
                        ForEach(Canale.allCases) { Text($0.nomeBreve).tag(Optional($0)) }
                    }
                    .pickerStyle(.segmented)
                }
                if prodotti.isEmpty {
                    Text(stato.dati.prodotti.isEmpty ? "Il catalogo è vuoto: le schede si creano in Prodotti sul Mac (anche dal KID)."
                                                     : "Nessun prodotto con «\(ricerca)».")
                        .foregroundColor(.secondary)
                }
                ForEach(prodotti) { p in
                    NavigationLink {
                        DatiClienteProdottoTelefono(prodotto: p, clienteIniziale: clienteId, statoIniziale: statoIniziale) { chiudi() }
                    } label: {
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(p.nome).carattereApple(E.nome)
                            Text(sottotitolo(p)).carattereApple(E.dettaglio).foregroundColor(.secondary)
                            EtichettaCanaleApple(canale: p.canale, compatta: true)
                        }
                        .padding(.vertical, E.spazioTesto)
                    }
                }
            }
            .searchable(text: $ricerca, prompt: "Nome, compagnia o tipo")
            .navigationTitle("Dal catalogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
            }
        }
    }

    private var prodotti: [Prodotto] {
        let t = ricerca.trimmingCharacters(in: .whitespaces).lowercased()
        return stato.dati.prodotti
            .filter { canale == nil || $0.canale == canale }
            .filter { p in t.isEmpty || [p.nome, p.emittente, p.tipologia, p.area.nome].contains { $0.lowercased().contains(t) } }
            .sorted { a, b in a.canale == b.canale ? a.nome.localizedCaseInsensitiveCompare(b.nome) == .orderedAscending : a.canale == .alleanza }
    }

    private func sottotitolo(_ p: Prodotto) -> String {
        var parti = [p.area.nome]
        if let c = p.costoAnnuo { parti.append("costo \(Formati.percentuale(c))/anno") }
        if let s = p.sri { parti.append("SRI \(s)") }
        return parti.joined(separator: " · ")
    }
}

/// Il secondo passo: per chi, proposta o in essere, e i soli dati del cliente di questo tipo di prodotto.
private struct DatiClienteProdottoTelefono: View {
    @Environment(StatoShell.self) var stato
    let prodotto: Prodotto
    let fatto: () -> Void
    @State private var clienteId: String
    @State private var valori: MotoreProdottoCliente.Valori

    init(prodotto: Prodotto, clienteIniziale: String, statoIniziale: StatoPosizione, fatto: @escaping () -> Void) {
        self.prodotto = prodotto
        self.fatto = fatto
        _clienteId = State(initialValue: clienteIniziale)
        _valori = State(initialValue: MotoreProdottoCliente.valoriIniziali(per: prodotto, cliente: nil, stato: statoIniziale))
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: E.spazioTesto) {
                    Text(prodotto.nome).carattereApple(E.nome)
                    Text(cifre).carattereApple(E.dettaglio).foregroundColor(.secondary)
                }
                Picker("Cliente", selection: $clienteId) {
                    ForEach(stato.clienti.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }) {
                        Text($0.nome).tag($0.id)
                    }
                }
                Picker("Stato", selection: $valori.stato) {
                    Text("Proposta").tag(StatoPosizione.proposta)
                    Text("In essere").tag(StatoPosizione.inEssere)
                }
                .pickerStyle(.segmented)
            }
            Section {
                ForEach(MotoreProdottoCliente.campi(per: prodotto, stato: valori.stato)) { campo in riga(campo) }
            } header: {
                Text("I dati del cliente")
            } footer: {
                Text(MotoreProdottoCliente.mancante(valori, per: prodotto)
                     ?? "Costi, rendimento, rischio, garanzie e fiscalità vengono dalla scheda del prodotto.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(prodotto.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Aggiungi") {
                    let pos = MotoreProdottoCliente.posizione(da: prodotto, clienteId: clienteId, valori: valori)
                    stato.salvaPosizione(pos)
                    let chi = stato.cliente(clienteId)?.nome ?? "il cliente"
                    stato.mostraAvviso("\(prodotto.nome) aggiunto a \(chi) \(valori.stato == .proposta ? "come proposta" : "in essere")")
                    fatto()
                }
                .disabled(clienteId.isEmpty || stato.solaLettura || MotoreProdottoCliente.mancante(valori, per: prodotto) != nil)
            }
        }
        .onAppear {
            // Con l'età del cliente la durata di un piano previdenziale arriva alla pensione
            guard prodotto.area == .previdenza, let c = stato.cliente(clienteId) else { return }
            let v = MotoreProdottoCliente.valoriIniziali(per: prodotto, cliente: c, stato: valori.stato)
            if valori.anni == MotoreProdottoCliente.valoriIniziali(per: prodotto, cliente: nil, stato: valori.stato).anni { valori.anni = v.anni }
        }
    }

    private var cifre: String {
        var parti: [String] = []
        if let v = prodotto.costoIngresso { parti.append("ingresso \(Formati.percentuale(v))") }
        if let v = prodotto.costoAnnuo { parti.append("costo \(Formati.percentuale(v))/anno") }
        if let v = prodotto.rendimentoAtteso { parti.append("rend. \(Formati.percentuale(v))") }
        if let v = prodotto.sri { parti.append("SRI \(v)") }
        return parti.joined(separator: " · ")
    }

    @ViewBuilder private func riga(_ campo: MotoreProdottoCliente.Campo) -> some View {
        switch campo {
        case .versamentoIniziale:
            CampoEuroTelefono(etichetta: prodotto.area == .previdenza ? "Trasferimento iniziale" : "Premio unico",
                              valore: $valori.versamentoIniziale)
        case .premio:
            CampoEuroTelefono(etichetta: prodotto.area == .previdenza ? "Contributo" : "Premio periodico", valore: $valori.premio)
            Picker("Frequenza", selection: $valori.frequenza) {
                ForEach(Frequenza.allCases.filter { $0 != .unica }) { Text($0.nome).tag($0) }
            }
        case .durata:
            Stepper(value: Binding(get: { valori.anni ?? 0 }, set: { valori.anni = $0 > 0 ? $0 : nil }), in: 0...60) {
                Text(valori.anni.map { "Durata: \($0) anni" } ?? "Senza scadenza")
            }
        case .decorrenza:
            DatePicker("Decorrenza", selection: $valori.decorrenza, displayedComponents: .date)
                .environment(\.locale, Formati.italiano)
        case .controvalore:
            CampoEuroFacoltativoTelefono(etichetta: "Valore di oggi", valore: $valori.controvalore)
        case .capitaleAssicurato:
            CampoEuroFacoltativoTelefono(etichetta: "Capitale assicurato", valore: $valori.capitaleAssicurato)
        case .tfr:
            CampoEuroFacoltativoTelefono(etichetta: "TFR conferito l'anno", valore: $valori.tfr)
        case .contributoDatore:
            CampoEuroFacoltativoTelefono(etichetta: "Contributo del datore l'anno", valore: $valori.contributoDatore)
        case .numeroContratto:
            TextField("Numero di contratto", text: $valori.numeroContratto)
        }
    }
}

/// «Aggiorna» nel dettaglio di una posizione: il valore di oggi e la sua data, il totale versato, il premio, l'esito
/// della proposta. Il valore di prima resta nello storico (StatoShell.salvaPosizione).
struct ModuloValorePosizioneTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    @State var bozza: Posizione

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CampoEuroFacoltativoTelefono(etichetta: bozza.area == .debiti ? "Debito residuo" : "Valore di oggi",
                                                 valore: $bozza.controvalore)
                    DatePicker("Valore al", selection: Binding(get: { bozza.dataValore ?? Date() }, set: { bozza.dataValore = $0 }),
                               displayedComponents: .date)
                        .environment(\.locale, Formati.italiano)
                    CampoEuroFacoltativoTelefono(etichetta: "Totale versato", valore: $bozza.totaleVersato)
                } header: {
                    Text(bozza.nome)
                }
                Section("Versamenti") {
                    CampoEuroTelefono(etichetta: "Premio unico", valore: $bozza.versamentoIniziale)
                    CampoEuroTelefono(etichetta: "Premio periodico", valore: $bozza.premio)
                    Picker("Frequenza", selection: $bozza.frequenza) {
                        ForEach(Frequenza.allCases) { Text($0.nome).tag($0) }
                    }
                }
                if bozza.stato == .proposta {
                    Section("La proposta") {
                        Picker("Esito", selection: Binding(get: { bozza.esito ?? .bozza }, set: { bozza.esito = $0 })) {
                            ForEach(EsitoProposta.allCases) { Text($0.nome).tag($0) }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Aggiorna")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        var p = bozza
                        if p.controvalore != nil && p.dataValore == nil { p.dataValore = Calendar.current.startOfDay(for: Date()) }
                        if p.premio <= 0 { p.premio = 0 }
                        stato.salvaPosizione(p)
                        stato.mostraAvviso("\(p.nome) aggiornata")
                        chiudi()
                    }
                    .disabled(stato.solaLettura)
                }
            }
        }
    }
}

// MARK: - Campi in euro

/// Un importo in euro in una riga del modulo: l'etichetta a sinistra, la cifra a destra.
struct CampoEuroTelefono: View {
    let etichetta: String
    @Binding var valore: Double
    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.italiano)

    var body: some View {
        HStack {
            Text(etichetta)
            Spacer()
            TextField("0", value: $valore, format: Self.numero)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("€").foregroundColor(.secondary)
        }
    }
}

/// Un importo facoltativo («—» se non indicato).
struct CampoEuroFacoltativoTelefono: View {
    let etichetta: String
    @Binding var valore: Double?
    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.italiano)

    var body: some View {
        HStack {
            Text(etichetta)
            Spacer()
            TextField("—", value: $valore, format: Self.numero)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("€").foregroundColor(.secondary)
        }
    }
}
#endif
