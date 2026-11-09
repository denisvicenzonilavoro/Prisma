import SwiftUI

// Il modulo «Nuovo sinistro» di Pratiche › Sinistri («Luce» giro 15, §7.4.4), sul modello di ModuloPosizione: cliente,
// polizza (solo protezione in essere del cliente, con il canale; o «da collegare»), tipo (gli elenchi dei documenti
// scritti dall'utente in Impostazioni › Pratiche: precompila i documenti richiesti, il tipo non si salva), titolo breve,
// giorno dell'accaduto e della denuncia, cosa è successo (breve, senza dati sanitari: decisione 36), stime facoltative,
// numero di sinistro, «Il cliente riceve gli aggiornamenti» (spento di base, D4.7) e «Mostra l'importo pagato». Si apre
// sopra la scheda (anche dal dossier e dalla posizione) e serve anche a cambiare un sinistro. Valori in
// Tema.Apple.Pratiche.ModuloSinistro.

struct ModuloSinistro: View {
    let stato: StatoShell
    let sinistri: StatoSinistri

    @State private var bozza: Sinistro
    @State private var tipo: String? = nil
    private let nuovo: Bool

    private typealias M = Tema.Apple.Pratiche.ModuloSinistro
    private static let numero = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))

    init(stato: StatoShell, sinistri: StatoSinistri) {
        self.stato = stato
        self.sinistri = sinistri
        if let id = sinistri.inModifica, let s = stato.sinistro(id) {
            _bozza = State(initialValue: s)
            nuovo = false
        } else {
            let clienti = stato.clienti
            let attivo = stato.clienteAttivoId
            let dalModulo = sinistri.clienteModulo.flatMap { id in clienti.first(where: { $0.id == id })?.id }
            let scelto = dalModulo ?? clienti.first(where: { $0.id == attivo })?.id ?? clienti.first?.id ?? ""
            let adatte = MotoreSinistri.polizzeAdatte(stato.dati.posizioni, clienteId: scelto)
            let polizza = sinistri.polizzaModulo.flatMap { id in adatte.first(where: { $0.id == id })?.id }
            _bozza = State(initialValue: Sinistro(id: "sinistro-\(UUID().uuidString.prefix(8).lowercased())", clienteId: scelto,
                                                  posizioneId: polizza, titolo: "", apertoIl: Appuntamento.alMinuto(Date())))
            nuovo = true
        }
    }

    var body: some View {
        let clienti = stato.clienti.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }
        let polizze = MotoreSinistri.polizzeAdatte(stato.dati.posizioni, clienteId: bozza.clienteId)
        let tipi = stato.dati.impostazioni.pratiche.documentiPerSinistro ?? []
        VStack(alignment: .leading, spacing: M.spazio) {
            Text(nuovo ? TestiSinistri.titoloModulo : TestiSinistri.titoloModifica)
                .carattereApple(M.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            riga("Cliente") {
                Picker("", selection: $bozza.clienteId) {
                    ForEach(clienti) { c in Text(c.nome).tag(c.id) }
                }
                .labelsHidden()
                .disabled(!nuovo)
            }
            riga("Polizza") {
                Picker("", selection: $bozza.posizioneId) {
                    Text(TestiSinistri.nessunaPolizza).tag(String?.none)
                    ForEach(polizze) { p in Text("\(p.nome) · \(p.canale == .alleanza ? "Alleanza" : "indipendente")").tag(Optional(p.id)) }
                }
                .labelsHidden()
            }
            if nuovo {
                riga(TestiSinistri.tipo) {
                    Picker("", selection: $tipo) {
                        Text(TestiSinistri.nessunTipo).tag(String?.none)
                        ForEach(tipi) { t in Text(t.tipo).tag(Optional(t.id)) }
                    }
                    .labelsHidden()
                    .disabled(tipi.isEmpty)
                }
                if tipi.isEmpty {
                    Text(TestiSinistri.notaTipi)
                        .carattereApple(M.nota)
                        .foregroundColor(M.coloreNota)
                }
            }
            riga("Titolo") {
                HStack(spacing: M.spazioCampi) {
                    TextField("Infortunio, furto, danni da acqua…", text: $bozza.titolo)
                        .textFieldStyle(.roundedBorder)
                    contatore(bozza.titolo.count, MotoreSinistri.lunghezzaTitolo)
                }
            }
            riga("Accaduto il") {
                DatePicker("", selection: Binding(get: { bozza.accadutoIl ?? bozza.apertoIl }, set: { bozza.accadutoIl = $0 }),
                           displayedComponents: .date)
                    .labelsHidden()
            }
            riga("Denuncia del") {
                DatePicker("", selection: $bozza.apertoIl, displayedComponents: .date)
                    .labelsHidden()
            }
            riga("Cosa è successo") {
                HStack(spacing: M.spazioCampi) {
                    TextField("Un fatto breve", text: $bozza.descrizione)
                        .textFieldStyle(.roundedBorder)
                    contatore(bozza.descrizione.count, MotoreSinistri.lunghezzaTesto)
                }
            }
            Text(TestiSinistri.notaBreve)
                .carattereApple(M.nota)
                .foregroundColor(M.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            riga("Stima") {
                HStack(spacing: M.spazioCampi) {
                    Text("da")
                    TextField("facoltativa", value: $bozza.stimaMinima, format: Self.numero)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: M.campoImporto)
                    Text("a")
                    TextField("facoltativa", value: $bozza.stimaMassima, format: Self.numero)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: M.campoImporto)
                    Text("€")
                    Spacer(minLength: 0)
                }
            }
            riga("Numero di sinistro") {
                TextField("dato dalla compagnia", text: Binding(get: { bozza.numeroSinistro ?? "" }, set: { bozza.numeroSinistro = $0 }))
                    .textFieldStyle(.roundedBorder)
            }
            Toggle(TestiSinistri.riceveAggiornamenti, isOn: Binding(get: { bozza.mostraAlCliente == true },
                                                                   set: { bozza.mostraAlCliente = $0 ? true : nil }))
                .toggleStyle(.apple)
            Toggle(TestiSinistri.mostraImporto, isOn: Binding(get: { bozza.importoAlCliente == true },
                                                             set: { bozza.importoAlCliente = $0 ? true : nil }))
                .toggleStyle(.apple)
                .disabled(bozza.mostraAlCliente != true)
            HStack(spacing: M.spazioCampi) {
                Spacer(minLength: 0)
                Button("Annulla") { chiudi() }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button(nuovo ? "Apri il sinistro" : "Salva") { salva() }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!valido(clienti))
            }
        }
        .padding(M.padding)
        .frame(width: M.larghezza)
        .superficieApple(M.superficie, raggio: M.raggio)
        .onChange(of: bozza.clienteId) { _, _ in bozza.posizioneId = nil }
    }

    private func riga<C: View>(_ etichetta: String, @ViewBuilder _ campo: () -> C) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: M.spazioCampi) {
            Text(etichetta)
                .carattereApple(M.etichetta)
                .foregroundColor(M.coloreEtichetta)
                .frame(width: M.colonnaEtichetta, alignment: .leading)
            campo()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func contatore(_ n: Int, _ massimo: Int) -> some View {
        Text("\(n)/\(massimo)")
            .carattereApple(M.contatore)
            .foregroundColor(n > massimo ? Tema.Apple.Colore.arancio : M.coloreContatore)
            .fixedSize()
    }

    private func valido(_ clienti: [Cliente]) -> Bool {
        !stato.solaLettura && clienti.contains { $0.id == bozza.clienteId }
            && !bozza.titolo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func chiudi() {
        sinistri.moduloAperto = false
        sinistri.inModifica = nil
        sinistri.clienteModulo = nil
        sinistri.polizzaModulo = nil
    }

    private func salva() {
        var s = bozza
        if nuovo {
            // Il primo fatto è la denuncia; i documenti dal tipo scelto (elenchi dell'utente), tutti da ricevere
            s.fase = .denuncia
            s.eventi = [EventoSinistro(id: "evento-\(UUID().uuidString.prefix(8).lowercased())", data: s.apertoIl,
                                       testo: TestiSinistri.fattoDellaFase(.denuncia, pagato: nil), fase: .denuncia)]
            if let t = tipo, let elenco = stato.dati.impostazioni.pratiche.documentiPerSinistro?.first(where: { $0.id == t }) {
                let nomi = elenco.documenti.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                s.documenti = nomi.enumerated().map { i, nome in
                    DocumentoSinistro(id: "documento-\(i)-\(UUID().uuidString.prefix(6).lowercased())",
                                      titolo: MotoreSinistri.breve(nome, limite: MotoreSinistri.lunghezzaTitolo),
                                      ricevutoIl: nil, documentoId: nil)
                }
            }
        }
        if s.mostraAlCliente != true { s.importoAlCliente = nil }
        stato.salvaSinistro(s)
        chiudi()
    }
}
