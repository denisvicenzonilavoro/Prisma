#if os(iOS)
import SwiftUI

// I clienti che si scrivono dall'iPhone (13 novembre 2026, giro 3 dell'iPhone): la scheda del cliente si modifica
// (anagrafica e recapiti), dal dossier si chiama, si scrive un messaggio o un'e-mail e si aggiungono una nota,
// un'attività o un appuntamento per quel cliente. Con «Prisma ovunque» acceso arrivano al Mac con il giornale
// (EntitaOvunque.anagrafica e .nota); il resto del cliente (profilo, consensi, famiglia, IBAN) resta del Mac.

private typealias M = Tema.Apple.Telefono.Moduli

/// Il foglio della scheda del cliente: nome, recapiti, indirizzo, professione, stato civile, nascita, motto, note.
struct ModuloClienteTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    @State var bozza: Cliente

    private var valido: Bool { !bozza.nome.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome e cognome", text: $bozza.nome)
                        .textContentType(.name)
                    TextField("Il suo motto (per esempio Una casa, un nuovo inizio)", text: $bozza.tema)
                    Toggle("Preferito", isOn: $bozza.preferito)
                }
                Section("Recapiti") {
                    TextField("Telefono", text: $bozza.telefono)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("E-mail", text: $bozza.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Indirizzo", text: $bozza.indirizzo, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                }
                Section("Chi è") {
                    TextField("Professione", text: $bozza.professione)
                    Picker("Stato civile", selection: $bozza.statoCivile) {
                        Text("Non indicato").tag(StatoCivile?.none)
                        ForEach(StatoCivile.allCases) { Text($0.nome).tag(Optional($0)) }
                    }
                    Toggle("Data di nascita", isOn: Binding(get: { bozza.dataNascita != nil },
                                                            set: { bozza.dataNascita = $0 ? (bozza.dataNascita ?? Formati.dataPredefinitaNascita) : nil }))
                    if bozza.dataNascita != nil {
                        DatePicker("Nato il", selection: Binding(get: { bozza.dataNascita ?? Formati.dataPredefinitaNascita },
                                                                 set: { bozza.dataNascita = $0 }),
                                   displayedComponents: .date)
                            .environment(\.locale, Formati.italiano)
                    }
                }
                Section("Note") {
                    TextField("Note sul cliente", text: $bozza.nota, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Scheda del cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        var c = bozza
                        c.nome = c.nome.trimmingCharacters(in: .whitespacesAndNewlines)
                        c.iniziali = Cliente.iniziali(di: c.nome)
                        stato.salvaCliente(c)
                        stato.mostraAvviso("Scheda di \(c.nome) aggiornata")
                        chiudi()
                    }
                    .disabled(!valido || stato.solaLettura)
                }
            }
        }
    }
}

/// Il foglio di una nota nuova del cliente (o da modificare).
struct ModuloNotaTelefono: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) var stato
    @State var bozza: Nota
    let nuova: Bool
    @FocusState private var nelTesto: Bool

    private var valida: Bool {
        !bozza.testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titolo", text: $bozza.titolo)
                    TextField("Scrivi la nota", text: $bozza.testo, axis: .vertical)
                        .lineLimit(5...14)
                        .focused($nelTesto)
                    Toggle("In evidenza", isOn: $bozza.fissata)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(nuova ? "Nuova nota" : "Nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(nuova ? "Aggiungi" : "Salva") {
                        var n = bozza
                        n.titolo = n.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
                        n.aggiornataIl = Nota.adesso
                        if let i = stato.dati.note.firstIndex(where: { $0.id == n.id }) {
                            stato.dati.note[i] = n
                        } else {
                            stato.dati.note.append(n)
                        }
                        if nuova { stato.mostraAvviso("Nota aggiunta") }
                        chiudi()
                    }
                    .disabled(!valida || stato.solaLettura)
                }
            }
            .onAppear { if nuova { nelTesto = true } }
        }
    }
}

/// Le azioni rapide del dossier: chiama, messaggio, e-mail (solo se c'è il recapito), poi «＋» per una nota,
/// un'attività o un appuntamento del cliente. Chiamata, messaggio ed e-mail aprono le app di sistema: Prisma non
/// spedisce nulla da solo.
struct AzioniClienteTelefono: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.openURL) private var apriURL
    let cliente: Cliente
    @State private var nota: Nota?
    @State private var attivita: Attivita?
    @State private var appuntamento: Appuntamento?

    var body: some View {
        HStack(spacing: M.spazioAzioni) {
            let numero = cliente.telefono.filter { $0.isNumber || $0 == "+" }
            if !numero.isEmpty {
                azione("Chiama", "phone.fill") { if let u = URL(string: "tel:\(numero)") { apriURL(u) } }
                azione("Messaggio", "message.fill") { if let u = URL(string: "sms:\(numero)") { apriURL(u) } }
            }
            let email = cliente.email.trimmingCharacters(in: .whitespaces)
            if !email.isEmpty {
                azione("E-mail", "envelope.fill") { if let u = URL(string: "mailto:\(email)") { apriURL(u) } }
            }
            Menu {
                Button { nota = Nota(clienteId: cliente.id, titolo: "", testo: "") } label: { Label("Nuova nota", systemImage: "note.text") }
                Button { attivita = .nuova(clienteId: cliente.id) } label: { Label("Nuova attività", systemImage: "checklist") }
                Button {
                    appuntamento = ModuloAppuntamentoTelefono.nuovo(giorno: Calendar.current.startOfDay(for: Date()), clienteId: cliente.id)
                } label: { Label("Nuovo appuntamento", systemImage: "calendar.badge.plus") }
            } label: {
                etichetta("Aggiungi", "plus")
            }
            .disabled(stato.solaLettura)
        }
        .sheet(item: $nota) { n in ModuloNotaTelefono(bozza: n, nuova: true).environment(stato) }
        .sheet(item: $attivita) { a in ModuloAttivitaTelefono(bozza: a, nuova: true).environment(stato) }
        .sheet(item: $appuntamento) { a in ModuloAppuntamentoTelefono(bozza: a, nuovo: true).environment(stato) }
    }

    private func azione(_ titolo: String, _ simbolo: String, _ fai: @escaping () -> Void) -> some View {
        Button(action: fai) { etichetta(titolo, simbolo) }
            .buttonStyle(StileSemplice())
    }

    private func etichetta(_ titolo: String, _ simbolo: String) -> some View {
        VStack(spacing: Tema.Apple.Telefono.Elenco.spazioTesto) {
            Image(systemName: simbolo)
                .font(Tipo.Mobile.simboloChiudi)
                .foregroundColor(Tema.Apple.Colore.accento)
            Text(titolo)
                .carattereApple(Tema.Apple.Telefono.Elenco.dettaglio)
                .foregroundColor(Tema.Apple.Colore.accento)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: M.altezzaAzione + Tema.Apple.Telefono.Elenco.spazioRiga)
        .superficieApple(Tema.Apple.Telefono.Elenco.superficie, raggio: Tema.Apple.Telefono.Elenco.raggio)
        .contentShape(Rectangle())
    }
}
#endif
