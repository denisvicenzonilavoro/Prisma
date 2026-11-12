import SwiftUI

/// Una richiesta di aprire «Il prodotto sul cliente» (per `.sheet(item:)`).
struct RichiestaProdottoCliente: Identifiable, Equatable {
    let id = UUID()
    var prodottoId: String?
    var stato: StatoPosizione
    /// Aperto da Prodotti: il cliente si sceglie nel modulo.
    var clienteScelto = false
}

/// «Il prodotto sul cliente» (12 novembre 2026): dal catalogo al cliente in due passi, per Alleanza e per la
/// consulenza indipendente. 1) Scegli il prodotto (ricerca, canale). 2) Scrivi solo i dati del cliente
/// (`MotoreProdottoCliente.campi`): costi, rendimento, rischio, garanzie e condizioni vengono dalla scheda.
/// «Tutti i campi…» porta la stessa posizione nel modulo intero. Si apre da Posizioni («Dal catalogo») e dalla
/// scheda in Prodotti («Metti su un cliente»).
struct ModuloProdottoSulCliente: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) private var stato
    /// Il prodotto già scelto (da Prodotti): si parte dal secondo passo.
    let prodottoIniziale: String?
    /// Il cliente può cambiare solo aprendo da Prodotti (in Posizioni è quello del dossier).
    let clienteScelto: Bool
    /// «Tutti i campi…»: la posizione già compilata passa al modulo intero (nil: pulsante nascosto).
    let tuttiICampi: ((Posizione) -> Void)?

    @State private var prodottoId: String?
    @State private var clienteId: String
    @State private var valori: MotoreProdottoCliente.Valori
    @State private var ricerca = ""
    @State private var canale: Canale?
    @State private var avviato = false

    /// Tutto dallo stato iniziale (anche nelle istantanee, che non aspettano `onAppear`): il prodotto già scelto
    /// parte con frequenza e durata della sua scheda.
    init(prodotto: Prodotto?, statoIniziale: StatoPosizione, clienteId: String, clienteScelto: Bool,
         tuttiICampi: ((Posizione) -> Void)? = nil) {
        prodottoIniziale = prodotto?.id
        self.clienteScelto = clienteScelto
        self.tuttiICampi = tuttiICampi
        _prodottoId = State(initialValue: prodotto?.id)
        _clienteId = State(initialValue: clienteId)
        var v = prodotto.map { MotoreProdottoCliente.valoriIniziali(per: $0, cliente: nil, stato: statoIniziale) }
            ?? MotoreProdottoCliente.Valori()
        v.stato = statoIniziale
        _valori = State(initialValue: v)
    }

    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.italiano)
    private typealias M = Tema.Misura.ProdottoCliente
    private typealias C = Tema.Colore.ProdottoCliente

    var body: some View {
        let _ = ContaCorpi.segna()
        CorniceModulo(titolo: prodotto == nil ? "Dal catalogo: scegli il prodotto" : "Dal catalogo: i dati del cliente") {
            VStack(alignment: .leading, spacing: 20) {
                if let p = prodotto {
                    secondoPasso(p)
                } else {
                    primoPasso
                }
            }
        } piede: {
            if prodotto != nil && prodottoIniziale == nil {
                Button { prodottoId = nil } label: { Label("Altro prodotto", systemImage: "chevron.left") }
                    .buttonStyle(StileVetro())
            }
            if let p = prodotto, let tutti = tuttiICampi {
                Button("Tutti i campi…") {
                    chiudi()
                    tutti(MotoreProdottoCliente.posizione(da: p, clienteId: clienteId, valori: valori))
                }
                .buttonStyle(StileVetro())
                .help("Apri la stessa posizione nel modulo completo: persone, fiscalità, dati per l'analisi")
            }
            Spacer()
            if let p = prodotto, let manca = MotoreProdottoCliente.mancante(valori, per: p) {
                Text(manca).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            }
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(valori.stato == .proposta ? "Aggiungi la proposta" : "Aggiungi la posizione") { aggiungi() }
                .buttonStyle(StileBlu())
                .disabled(!pronto)
                .opacity(pronto ? 1 : 0.5)
                .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.modulo.width, height: M.modulo.height)
        .onAppear(perform: avvia)
    }

    // MARK: - Stato

    private var prodotto: Prodotto? { prodottoId.flatMap { id in stato.dati.prodotti.first { $0.id == id } } }

    private var pronto: Bool {
        guard let p = prodotto, !clienteId.isEmpty, !stato.solaLettura else { return false }
        return MotoreProdottoCliente.mancante(valori, per: p) == nil
    }

    /// All'apertura: con l'età del cliente la durata di un piano previdenziale arriva alla pensione.
    private func avvia() {
        guard !avviato else { return }
        avviato = true
        if let id = prodottoIniziale { scegli(id) }
    }

    private func scegli(_ id: String) {
        prodottoId = id
        guard let p = prodotto else { return }
        let statoScelto = valori.stato
        valori = MotoreProdottoCliente.valoriIniziali(per: p, cliente: stato.cliente(clienteId), stato: statoScelto)
    }

    private func aggiungi() {
        guard pronto, let p = prodotto else { return }
        let pos = MotoreProdottoCliente.posizione(da: p, clienteId: clienteId, valori: valori)
        stato.salvaPosizione(pos)
        chiudi()
        stato.apriPosizione(pos)
        let chi = stato.cliente(clienteId)?.nome ?? "il cliente"
        stato.mostraAvviso("\(p.nome) aggiunto a \(chi) \(valori.stato == .proposta ? "come proposta" : "in essere"), con i costi della scheda.")
    }

    // MARK: - Primo passo: il prodotto

    private var schede: [Prodotto] {
        let testo = ricerca.trimmingCharacters(in: .whitespaces).lowercased()
        return stato.dati.prodotti
            .filter { canale == nil || $0.canale == canale }
            .filter { p in
                testo.isEmpty || [p.nome, p.emittente, p.tipologia, p.area.nome].contains { $0.lowercased().contains(testo) }
            }
            .sorted { a, b in
                a.canale == b.canale ? a.nome.localizedCaseInsensitiveCompare(b.nome) == .orderedAscending : a.canale == .alleanza
            }
    }

    private var primoPasso: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("Cerca per nome, compagnia o tipo", text: $ricerca)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: M.ricerca)
                Picker("", selection: $canale) {
                    Text("Tutti").tag(Canale?.none)
                    ForEach(Canale.allCases) { Text($0.nomeBreve).tag(Optional($0)) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
            }
            if stato.dati.prodotti.isEmpty {
                Text("Il catalogo è vuoto: crea le schede in Prodotti (anche dal KID), poi tornano qui.")
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            } else if schede.isEmpty {
                Text("Nessun prodotto con «\(ricerca)».")
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            }
            VStack(spacing: 4) {
                ForEach(schede) { p in
                    Button { scegli(p.id) } label: { rigaProdotto(p) }
                        .buttonStyle(StileSemplice())
                }
            }
        }
    }

    private func rigaProdotto(_ p: Prodotto) -> some View {
        HStack(spacing: M.spazioRiga) {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.nome).font(Tipo.campoValore).foregroundColor(Tema.Colore.inchiostro)
                Text(sottotitolo(p)).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario).lineLimit(1)
            }
            Spacer()
            Text(cifre(p)).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario).lineLimit(1)
            EtichettaCanale(canale: p.canale, compatta: true)
            Image(systemName: "chevron.right").font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
        }
        .padding(M.margineRiga)
        .frame(minHeight: M.altezzaRiga)
        .contentShape(Rectangle())
        .background(RoundedRectangle(cornerRadius: Tema.Raggio.ProdottoCliente.riga, style: .continuous).fill(C.riquadro))
    }

    private func sottotitolo(_ p: Prodotto) -> String {
        let compagnia = p.canale == .alleanza && p.emittente.isEmpty ? "Alleanza Assicurazioni" : p.emittente
        return [p.area.nome, p.tipologia, compagnia].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Le cifre della scheda in una riga: costo annuo, rendimento atteso, SRI.
    private func cifre(_ p: Prodotto) -> String {
        var parti: [String] = []
        if let c = p.costoAnnuo { parti.append("costo \(Formati.percentuale(c))/anno") }
        if let r = p.rendimentoAtteso { parti.append("rend. \(Formati.percentuale(r))") }
        if let s = p.sri { parti.append("SRI \(s)") }
        return parti.joined(separator: " · ")
    }

    // MARK: - Secondo passo: i dati del cliente

    @ViewBuilder private func secondoPasso(_ p: Prodotto) -> some View {
        riquadroProdotto(p)
        sezione("Per chi") {
            CampoModulo(etichetta: "Cliente") {
                if clienteScelto {
                    MenuTendina(selezione: $clienteId,
                                opzioni: stato.clienti.map { ($0.id, $0.nome) },
                                larghezza: M.tendinaCliente)
                } else {
                    Text(stato.cliente(clienteId)?.nome ?? "—").font(Tipo.campoValore)
                }
            }
            CampoModulo(etichetta: "Stato") {
                Picker("", selection: $valori.stato) {
                    Text("Proposta").tag(StatoPosizione.proposta)
                    Text("In essere").tag(StatoPosizione.inEssere)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        sezione("I dati del cliente") {
            ForEach(MotoreProdottoCliente.campi(per: p, stato: valori.stato)) { campo in
                riga(campo, p)
            }
            Text("Costi, rendimento, rischio, garanzie e fiscalità vengono dalla scheda «\(p.nome)». Il resto si completa con «Tutti i campi…».")
                .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func riquadroProdotto(_ p: Prodotto) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(p.nome).font(Tipo.campoValore).foregroundColor(Tema.Colore.inchiostro)
                EtichettaCanale(canale: p.canale, compatta: true)
                Spacer()
            }
            Text(sottotitolo(p)).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            HStack(spacing: M.spazioCifre) {
                if let v = p.costoIngresso { cifra("Ingresso", Formati.percentuale(v)) }
                if let v = p.costoAnnuo { cifra("Costo annuo", Formati.percentuale(v)) }
                if let v = p.rendimentoAtteso { cifra("Rendimento", Formati.percentuale(v)) }
                if let v = p.sri { cifra("SRI", "\(v)") }
                if let v = p.periodoConsigliato { cifra("Periodo KID", "\(v) anni") }
            }
            if p.daVerificare {
                Text("Scheda da riverificare sul KID in vigore.")
                    .font(Tipo.campoEtichetta).foregroundColor(C.avviso)
            }
        }
        .padding(M.margineRiquadro)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Tema.Raggio.ProdottoCliente.riga, style: .continuous).fill(C.riquadro))
    }

    private func cifra(_ etichetta: String, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(etichetta).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            Text(valore).font(Tipo.campoValore).foregroundColor(Tema.Colore.inchiostro)
        }
    }

    @ViewBuilder private func riga(_ campo: MotoreProdottoCliente.Campo, _ p: Prodotto) -> some View {
        switch campo {
        case .versamentoIniziale:
            CampoModulo(etichetta: p.area == .previdenza ? "Trasferimento iniziale"
                        : p.area == .liquidita || p.area == .immobili ? "Importo" : "Premio unico") {
                euro($valori.versamentoIniziale)
            }
        case .premio:
            CampoModulo(etichetta: p.area == .previdenza ? "Contributo" : "Premio periodico") {
                HStack(spacing: 10) {
                    euro($valori.premio)
                    MenuTendina(selezione: $valori.frequenza,
                                opzioni: Frequenza.allCases.filter { $0 != .unica }.map { ($0, $0.nome) },
                                larghezza: M.tendinaFrequenza)
                }
            }
        case .durata:
            CampoModulo(etichetta: "Durata") {
                HStack(spacing: 6) {
                    TextField("—", value: $valori.anni, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: M.campoAnni)
                    Text(p.area == .previdenza ? "anni, fino alla pensione" : "anni")
                        .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                }
            }
        case .decorrenza:
            CampoModulo(etichetta: "Decorrenza") {
                DatePicker("", selection: $valori.decorrenza, displayedComponents: .date)
                    .labelsHidden()
                    .stileDataCampo()
                    .environment(\.locale, Formati.italiano)
            }
        case .controvalore:
            CampoModulo(etichetta: "Valore di oggi") { euroFacoltativo($valori.controvalore) }
        case .capitaleAssicurato:
            CampoModulo(etichetta: "Capitale assicurato") { euroFacoltativo($valori.capitaleAssicurato) }
        case .tfr:
            CampoModulo(etichetta: "TFR conferito") { euroFacoltativo($valori.tfr, unita: "€ l'anno") }
        case .contributoDatore:
            CampoModulo(etichetta: "Contributo datore") { euroFacoltativo($valori.contributoDatore, unita: "€ l'anno") }
        case .numeroContratto:
            CampoModulo(etichetta: "Numero di contratto") {
                TextField("", text: $valori.numeroContratto).textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Pezzi

    private func sezione<V: View>(_ titolo: String, @ViewBuilder _ contenuto: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            OcchielloSezione(titolo: titolo)
            contenuto()
        }
    }

    private func euro(_ valore: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            TextField("0", value: valore, format: Self.numero)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: M.campoEuro)
            Text("€").font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
        }
    }

    private func euroFacoltativo(_ valore: Binding<Double?>, unita: String = "€") -> some View {
        HStack(spacing: 6) {
            TextField("—", value: valore, format: Self.numero)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: M.campoEuro)
            Text(unita).font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
        }
    }
}
