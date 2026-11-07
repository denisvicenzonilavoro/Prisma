import SwiftUI

// Il modulo «Nuova parcella» di Studio › Parcelle e fatture (Design/template-novita-specifica.md §4.1; il template ha
// solo il toast). Nel tema Apple: titolo come il dettaglio, sezioni `.lbl`, campi del tema, il riquadro delle voci
// fiscali calcolate da MotoreFattura con il regime del consulente, «Salva come bozza» e «Emetti».
// - Il cliente (il cliente aperto già scelto) e, se si vuole, la consulenza da cui nasce: un incontro o una proposta
//   indipendente del cliente. Le parcelle sono sempre del canale indipendente.
// - Una o più righe: descrizione e importo (imponibile). Data del documento, scadenza (di base i giorni scritti in
//   Impostazioni › Studio, se ci sono), ricorrente.
// - Le voci fiscali compaiono solo con il regime completo: nessuna aliquota, contributo, ritenuta o bollo predefinito.
//   Senza regime si può emettere lo stesso (con conferma): l'importo resta provvisorio e il file XML aspetta i dati.
// Valori in DesignSystem/Apple/Tema.Apple+Parcelle.swift (`Parcelle.Modulo`).

struct ModuloParcella: View {
    @EnvironmentObject var stato: StatoShell
    @State private var bozza: Parcella
    @State private var confermaEmissione = false
    let nuova: Bool
    let salva: (Parcella, Bool) -> Void
    let chiudi: () -> Void

    private typealias M = Tema.Apple.Parcelle.Modulo

    init(parcella: Parcella, nuova: Bool, salva: @escaping (Parcella, Bool) -> Void, chiudi: @escaping () -> Void) {
        _bozza = State(initialValue: parcella)
        self.nuova = nuova
        self.salva = salva
        self.chiudi = chiudi
    }

    /// Le righe con qualcosa scritto (le righe vuote non si salvano).
    private var pulita: Parcella {
        var p = bozza
        p.righe = p.righe.filter { !$0.descrizione.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.importo != 0 }
        p.descrizione = p.descrizione.trimmingCharacters(in: .whitespacesAndNewlines)
        return p
    }

    /// Si può emettere: righe con la descrizione e un importo positivo.
    private var emettibile: Bool {
        MotoreFattura.mancantiParcella(pulita).allSatisfy { $0.codice == "parcella.numero" }
    }

    private var regimeCompleto: Bool { MotoreFattura.mancantiRegime(stato.datiFatturazione.regime).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: M.fraVoci) {
                Text(nuova ? "Nuova parcella" : "Modifica la bozza")
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
                Text("Consulenza indipendente: la parcella è sempre del canale indipendente.")
                    .carattereApple(M.sottotitolo)
                    .foregroundColor(M.coloreSottotitolo)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: M.spazioSezioni) {
                    sezione("Cliente e consulenza") {
                        campo("Cliente") {
                            MenuTendina(selezione: legameCliente, opzioni: stato.clienti.map { ($0.id, $0.nome) },
                                        larghezza: M.campoMenu)
                        }
                        campo("Dalla consulenza") {
                            MenuTendina(selezione: legameConsulenza, opzioni: consulenze, larghezza: M.campoMenu)
                        }
                        campo("Descrizione") {
                            TextField("Per esempio Piano previdenziale", text: $bozza.descrizione)
                                .campoTesto()
                        }
                    }
                    sezione("Righe") {
                        ForEach($bozza.righe) { $riga in
                            HStack(spacing: M.spazioCampo) {
                                TextField("Descrizione della consulenza", text: $riga.descrizione)
                                    .campoTesto()
                                TextField("", value: $riga.importo, format: Self.formatoImporto, prompt: Text(verbatim: "0"))
                                    .campoTesto()
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: M.campoImporto)
                                Text(verbatim: "€")
                                    .carattereApple(M.etichetta)
                                    .foregroundColor(M.coloreEtichetta)
                                Button { togli(riga.id) } label: {
                                    Image(systemName: "xmark")
                                        .carattereApple(M.togli)
                                        .foregroundColor(M.coloreTogli)
                                }
                                .buttonStyle(StileSemplice())
                                .disabled(bozza.righe.count <= 1)
                                .help("Togli la riga")
                            }
                        }
                        Button {
                            bozza.righe.append(RigaParcella(descrizione: "", importo: 0))
                        } label: {
                            Label("Aggiungi una riga", systemImage: "plus")
                        }
                        .buttonStyle(.appleSobrio)
                    }
                    sezione("Date") {
                        campo("Data del documento") {
                            DatePicker("", selection: $bozza.data, displayedComponents: .date)
                                .labelsHidden()
                                .fixedSize()
                        }
                        campo("Scadenza") {
                            HStack(spacing: M.spazioCampo) {
                                Toggle(isOn: legameConScadenza) { EmptyView() }
                                    .toggleStyle(.appleSenzaEtichetta)
                                    .accessibilityLabel("Con la scadenza del pagamento")
                                if bozza.scadenza != nil {
                                    DatePicker("", selection: legameScadenza, displayedComponents: .date)
                                        .labelsHidden()
                                        .fixedSize()
                                }
                            }
                        }
                        campo("Ricorrente") {
                            Toggle(isOn: $bozza.ricorrente) { EmptyView() }
                                .toggleStyle(.appleSenzaEtichetta)
                                .accessibilityLabel("Consulenza ricorrente")
                        }
                    }
                    sezione("Voci fiscali") {
                        RiquadroVociParcella(bozza: pulita, regime: stato.datiFatturazione.regime)
                    }
                }
                .padding(.top, M.spazioSezioni)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: M.spazioPiede) {
                Button("Annulla") { chiudi() }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Spacer(minLength: 0)
                Button("Salva come bozza") { salva(pulita, false) }
                    .buttonStyle(.apple)
                    .disabled(stato.solaLettura || bozza.clienteId.isEmpty)
                Button("Emetti") {
                    if regimeCompleto {
                        salva(pulita, true)
                    } else {
                        confermaEmissione = true
                    }
                }
                .buttonStyle(.applePrimario)
                .disabled(stato.solaLettura || !emettibile)
            }
            .padding(.top, M.piedeSopra)
        }
        .padding(M.padding)
        .frame(width: M.larghezza, height: M.altezza, alignment: .topLeading)
        .superficieApple(M.superficie, raggio: M.raggio)
        // I menu a tendina nella capsula del tema Apple
        .altreAppApple()
        .alert("Il regime fiscale non è completo", isPresented: $confermaEmissione) {
            Button("Emetti lo stesso") { salva(pulita, true) }
            Button("Non ora", role: .cancel) {}
        } message: {
            Text("La parcella prende il numero con l’importo provvisorio, senza voci fiscali. Il file XML si prepara quando "
                 + "completi i dati per le fatture in Impostazioni › Studio.")
        }
    }

    // MARK: Struttura

    private func sezione<C: View>(_ titolo: String, @ViewBuilder _ contenuto: () -> C) -> some View {
        VStack(alignment: .leading, spacing: M.fraCampi) {
            Text(titolo)
                .carattereApple(M.sezione)
                .foregroundColor(M.coloreSezione)
                .padding(.bottom, M.sottoSezione - M.fraCampi)
            contenuto()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func campo<C: View>(_ etichetta: String, @ViewBuilder _ controllo: () -> C) -> some View {
        HStack(alignment: .center, spacing: M.spazioCampo) {
            Text(etichetta)
                .carattereApple(M.etichetta)
                .foregroundColor(M.coloreEtichetta)
                .frame(width: M.larghezzaEtichetta, alignment: .trailing)
            controllo()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Legami

    /// Cambiando cliente la consulenza scelta (che era dell'altro cliente) si toglie.
    private var legameCliente: Binding<String> {
        Binding(get: { bozza.clienteId }, set: { nuovo in
            guard nuovo != bozza.clienteId else { return }
            bozza.clienteId = nuovo
            bozza.incontroId = nil
            bozza.consulenzaId = nil
        })
    }

    /// Le consulenze del cliente: gli incontri (dal più recente) e le proposte del canale indipendente.
    private var consulenze: [(String?, String)] {
        let id = bozza.clienteId
        let incontri = stato.dati.incontri.filter { $0.clienteId == id }.sorted { $0.data > $1.data }
            .map { (Optional("incontro:" + $0.id), "Incontro · \($0.titolo) · \(TestiFattura.data($0.data))") }
        let proposte = stato.dati.posizioni.filter { $0.clienteId == id && $0.canale == .indipendente }
            .map { (Optional("posizione:" + $0.id), "Indipendente · \($0.nome)") }
        let nessuna: [(String?, String)] = [(nil, "Nessuna in particolare")]
        return nessuna + incontri + proposte
    }

    /// La consulenza scelta: un incontro o una posizione; se la descrizione è vuota prende il suo nome.
    private var legameConsulenza: Binding<String?> {
        let attuale: String? = bozza.incontroId.map { "incontro:" + $0 } ?? bozza.consulenzaId.map { "posizione:" + $0 }
        return Binding(get: { attuale }, set: { nuovo in
            bozza.incontroId = nil
            bozza.consulenzaId = nil
            guard let nuovo else { return }
            var titolo = ""
            if nuovo.hasPrefix("incontro:") {
                let id = String(nuovo.dropFirst("incontro:".count))
                bozza.incontroId = id
                titolo = stato.dati.incontri.first { $0.id == id }?.titolo ?? ""
            } else if nuovo.hasPrefix("posizione:") {
                let id = String(nuovo.dropFirst("posizione:".count))
                bozza.consulenzaId = id
                titolo = stato.dati.posizioni.first { $0.id == id }?.nome ?? ""
            }
            guard !titolo.isEmpty else { return }
            if bozza.descrizione.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { bozza.descrizione = titolo }
            if let i = bozza.righe.firstIndex(where: { $0.descrizione.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                bozza.righe[i].descrizione = titolo
            }
        })
    }

    private var legameConScadenza: Binding<Bool> {
        Binding(get: { bozza.scadenza != nil }, set: { acceso in
            bozza.scadenza = acceso ? (bozza.scadenza ?? scadenzaProposta) : nil
        })
    }

    private var legameScadenza: Binding<Date> {
        Binding(get: { bozza.scadenza ?? scadenzaProposta }, set: { bozza.scadenza = $0 })
    }

    /// I giorni per il pagamento scritti in Impostazioni › Studio dopo la data del documento; senza, la data stessa.
    private var scadenzaProposta: Date {
        let giorni = stato.datiFatturazione.giorniPagamento ?? 0
        return Calendar.current.date(byAdding: .day, value: giorni, to: bozza.data) ?? bozza.data
    }

    private func togli(_ id: String) {
        guard bozza.righe.count > 1 else { return }
        bozza.righe.removeAll { $0.id == id }
    }

    /// Importi all'italiana (punto delle migliaia, virgola dei decimali), al centesimo.
    private static var formatoImporto: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti).precision(.fractionLength(0...2))
    }
}

/// Il riquadro delle voci fiscali del modulo: calcolate con il regime del consulente, oppure che cosa manca.
private struct RiquadroVociParcella: View {
    let bozza: Parcella
    let regime: RegimeFatturazione

    private typealias M = Tema.Apple.Parcelle.Modulo

    var body: some View {
        let esito = MotoreFattura.calcola(righe: bozza.righe, regime: regime)
        let regimeMancante = MotoreFattura.mancantiRegime(regime)
        var conRegime = DatiFatturazione()
        conRegime.regime = regime
        let t = TestiFattura(parcella: bozza, cliente: nil, consulente: conRegime, mancanti: [], prova: false)
        return VStack(alignment: .leading, spacing: M.fraVoci) {
            if esito.voci != nil {
                ForEach(t.voci) { v in riga(v.etichetta, v.valore, carattere: M.rigaVoce, colore: M.coloreRigaSecondaria) }
                riga(t.etichettaTotale, t.totale, carattere: M.rigaTotale, colore: M.coloreRiga)
                ForEach(t.dopoTotale) { v in riga(v.etichetta, v.valore, carattere: M.rigaVoce, colore: M.coloreRigaSecondaria) }
                if let netto = t.netto {
                    riga(TestiFattura.etichettaNetto, netto, carattere: M.rigaTotale, colore: M.coloreRiga)
                }
            } else if !regimeMancante.isEmpty {
                riga("Imponibile", TestiFattura.importo(MotoreParcelle.imponibile(bozza)), carattere: M.rigaVoce,
                     colore: M.coloreRigaSecondaria)
                Text("Le voci fiscali compaiono quando imposti il regime in Impostazioni › Studio.")
                    .carattereApple(M.notaVoci)
                    .foregroundColor(M.coloreNotaVoci)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Mancano: " + TestiParcelle.elenco(regimeMancante, massimo: 4))
                    .carattereApple(M.notaVoci)
                    .foregroundColor(M.coloreAvviso)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Scrivi almeno una riga con la descrizione e l’importo.")
                    .carattereApple(M.notaVoci)
                    .foregroundColor(M.coloreNotaVoci)
            }
        }
        .padding(M.paddingVoci)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.superficieVoci, raggio: M.raggioVoci)
    }

    private func riga(_ etichetta: String, _ valore: String, carattere: Tema.Apple.Carattere, colore: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(etichetta)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: M.spazioCampo)
            Text(valore)
                .lineLimit(1)
        }
        .carattereApple(carattere)
        .foregroundColor(colore)
    }
}
