#if os(iOS)
import SwiftUI

// Agenda e attività che si scrivono dall'iPhone (13 novembre 2026, giro 2 dell'iPhone): la spunta delle attività,
// i fogli per un appuntamento o un'attività nuovi o da modificare, le azioni nel dettaglio dell'appuntamento.
// Le modifiche vanno nell'archivio dell'iPhone e, con «Prisma ovunque» acceso, al Mac con il giornale del dispositivo
// (appuntamenti e attività sono fra le entità che si sincronizzano: CampiOvunque).

private typealias E = Tema.Apple.Telefono.Elenco
private typealias M = Tema.Apple.Telefono.Moduli

// MARK: - La spunta

/// Il cerchio di un'attività che si tocca: fatta o da fare, con «Annulla» nell'avviso quando la fai.
struct SpuntaAttivitaTelefono: View {
    @Environment(StatoShell.self) var stato
    let attivita: Attivita

    var body: some View {
        Button {
            let id = attivita.id
            let fatta = !attivita.completata
            withAnimation(M.spunta) { stato.alternaCompletata(id) }
            if fatta {
                stato.mostraAvviso("Fatto: \(attivita.titolo)", azione: AzioneAvviso(titolo: "Annulla") {
                    withAnimation(M.spunta) { stato.alternaCompletata(id) }
                })
            }
        } label: {
            CerchioAttivitaTelefono(fatta: attivita.completata)
                .frame(width: M.toccoSpunta, height: M.toccoSpunta)
                .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .disabled(stato.solaLettura)
        .sensoryFeedback(.success, trigger: attivita.completata)
        .accessibilityLabel(Text(attivita.completata ? "Fatta: \(attivita.titolo)" : "Da fare: \(attivita.titolo)"))
        .accessibilityHint(Text(attivita.completata ? "Tocca per riaprirla" : "Tocca per segnarla fatta"))
    }
}

// MARK: - Il cliente

/// La scelta del cliente nei fogli: i clienti in ordine di nome («Nessun cliente» solo dove ha senso).
private struct SceltaClienteTelefono: View {
    @Environment(StatoShell.self) var stato
    @Binding var clienteId: String
    var conNessuno = false

    var body: some View {
        Picker("Cliente", selection: $clienteId) {
            if conNessuno { Text("Nessun cliente").tag("") }
            ForEach(stato.clienti.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }) { c in
                Text(c.nome).tag(c.id)
            }
        }
    }
}

// MARK: - Appuntamento

/// Il foglio di un appuntamento nuovo o da modificare: con chi, che cosa, quando, quanto dura, dove, il canale, le note.
struct ModuloAppuntamentoTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    @State var bozza: Appuntamento
    let nuovo: Bool

    /// Un appuntamento nuovo nel giorno scelto: alle 9:30 o, se oggi è già passato, alla prossima mezz'ora.
    static func nuovo(giorno: Date, clienteId: String, adesso: Date = Date()) -> Appuntamento {
        let cal = Calendar.current
        var inizio = cal.date(bySettingHour: M.oraPredefinita, minute: M.minutoPredefinito, second: 0, of: giorno) ?? giorno
        if inizio < adesso, cal.isDate(giorno, inSameDayAs: adesso) {
            let minuti = cal.component(.minute, from: adesso)
            let avanti = M.passoMinuti - minuti % M.passoMinuti
            inizio = cal.date(byAdding: .minute, value: avanti, to: cal.date(bySetting: .second, value: 0, of: adesso) ?? adesso) ?? adesso
        }
        return Appuntamento(id: "app-\(UUID().uuidString.prefix(8).lowercased())", clienteId: clienteId, titolo: "",
                            inizio: inizio, durataMinuti: M.durataPredefinita, luogo: "", note: "", stato: .pianificato)
    }

    private var valido: Bool {
        !bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty
            && (bozza.tipo == .nonDisponibile || !bozza.clienteId.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titolo (per esempio Il punto sul progetto casa)", text: $bozza.titolo, axis: .vertical)
                    SceltaClienteTelefono(clienteId: $bozza.clienteId, conNessuno: bozza.tipo == .nonDisponibile)
                    Picker("Tipo", selection: $bozza.tipo) {
                        ForEach(TipoAppuntamento.allCases) { Text($0.nome).tag($0) }
                    }
                }
                Section("Quando") {
                    DatePicker("Inizio", selection: $bozza.inizio)
                        .environment(\.locale, Formati.italiano)
                    Picker("Durata", selection: $bozza.durataMinuti) {
                        ForEach(durate, id: \.self) { Text("\($0) min").tag($0) }
                    }
                }
                Section("Dove") {
                    Picker("Presso", selection: $bozza.presso) {
                        Text("Non indicato").tag(LuogoIncontro?.none)
                        ForEach(LuogoIncontro.allCases) { Text($0.nome).tag(Optional($0)) }
                    }
                    TextField("Luogo o indirizzo", text: $bozza.luogo)
                }
                Section {
                    Picker("Canale", selection: $bozza.canale) {
                        Text("Entrambi o non indicato").tag(Canale?.none)
                        ForEach(Canale.allCases) { Text($0.nomeBreve).tag(Optional($0)) }
                    }
                    TextField("Note", text: $bozza.note, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(nuovo ? "Nuovo appuntamento" : "Appuntamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(nuovo ? "Aggiungi" : "Salva") {
                        stato.salvaAppuntamento(bozza)
                        stato.mostraAvviso(nuovo ? "Appuntamento in agenda: \(Formati.dataOra.string(from: bozza.inizio))"
                                                 : "Appuntamento aggiornato")
                        chiudi()
                    }
                    .disabled(!valido || stato.solaLettura)
                }
            }
        }
    }

    /// Le durate proposte, più quella dell'appuntamento se è un'altra.
    private var durate: [Int] {
        M.durate.contains(bozza.durataMinuti) ? M.durate : (M.durate + [bozza.durataMinuti]).sorted()
    }
}

/// Le azioni nel dettaglio dell'appuntamento: modifica, concluso o da riaprire, elimina (con conferma).
struct AzioniAppuntamentoTelefono: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.dismiss) private var indietro
    let appuntamento: Appuntamento
    @State private var modifica: Appuntamento?
    @State private var confermaElimina = false

    var body: some View {
        VStack(spacing: M.spazioAzioni) {
            Button { modifica = appuntamento } label: {
                Label("Modifica", systemImage: "pencil").frame(maxWidth: .infinity, minHeight: M.altezzaAzione)
            }
            .buttonStyle(StileBlu())
            HStack(spacing: M.spazioAzioni) {
                Button { withAnimation(M.spunta) { stato.alternaConcluso(appuntamento.id) } } label: {
                    Label(appuntamento.stato == .concluso ? "Riapri" : "Segna concluso",
                          systemImage: appuntamento.stato == .concluso ? "arrow.uturn.backward" : "checkmark")
                        .frame(maxWidth: .infinity, minHeight: M.altezzaAzione)
                }
                .buttonStyle(StileVetro())
                Button(role: .destructive) { confermaElimina = true } label: {
                    Label("Elimina", systemImage: "trash").frame(maxWidth: .infinity, minHeight: M.altezzaAzione)
                }
                .buttonStyle(StileVetro())
            }
        }
        .disabled(stato.solaLettura)
        .sheet(item: $modifica) { a in
            ModuloAppuntamentoTelefono(bozza: a, nuovo: false).environment(stato)
        }
        .confirmationDialog("Eliminare l'appuntamento?", isPresented: $confermaElimina, titleVisibility: .visible) {
            Button("Elimina", role: .destructive) {
                stato.eliminaAppuntamento(appuntamento.id)
                indietro()
            }
        } message: {
            Text("Le attività collegate restano, senza collegamento.")
        }
    }
}

// MARK: - Attività

/// Il foglio di un'attività nuova o da modificare: che cosa, per chi, entro quando, la priorità, le note; nella
/// modifica anche «Elimina».
struct ModuloAttivitaTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    @State var bozza: Attivita
    let nuova: Bool
    @State private var confermaElimina = false

    private var valida: Bool { !bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty && !bozza.clienteId.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Che cosa c'è da fare", text: $bozza.titolo, axis: .vertical)
                    SceltaClienteTelefono(clienteId: $bozza.clienteId)
                }
                Section {
                    DatePicker("Entro", selection: $bozza.scadenza, displayedComponents: .date)
                        .environment(\.locale, Formati.italiano)
                    Picker("Priorità", selection: $bozza.priorita) {
                        ForEach(Attivita.Priorita.allCases) { Text($0.nome).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if !nuova { Toggle("Fatta", isOn: $bozza.completata) }
                }
                Section {
                    TextField("Note", text: $bozza.note, axis: .vertical)
                        .lineLimit(3...8)
                }
                if !nuova {
                    Section {
                        Button("Elimina l'attività", role: .destructive) { confermaElimina = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(nuova ? "Nuova attività" : "Attività")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(nuova ? "Aggiungi" : "Salva") {
                        var a = bozza
                        a.scadenza = Calendar.current.startOfDay(for: a.scadenza)
                        stato.salvaAttivita(a)
                        if nuova { stato.mostraAvviso("Attività aggiunta: \(a.titolo)") }
                        chiudi()
                    }
                    .disabled(!valida || stato.solaLettura)
                }
            }
            .confirmationDialog("Eliminare l'attività?", isPresented: $confermaElimina, titleVisibility: .visible) {
                Button("Elimina", role: .destructive) {
                    stato.eliminaAttivita(bozza.id)
                    chiudi()
                }
            }
        }
    }
}

/// Il pulsante «＋» nella barra di un'app: apre il foglio di una cosa nuova.
struct PulsanteNuovoTelefono: View {
    let aiuto: String
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Image(systemName: "plus")
                .font(Tipo.Mobile.simboloChiudi)
                .frame(width: Tema.Apple.Telefono.tocco, height: Tema.Apple.Telefono.tocco)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(aiuto))
    }
}
#endif
