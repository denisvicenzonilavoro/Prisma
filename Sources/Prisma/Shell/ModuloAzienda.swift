import SwiftUI

// Il modulo dell'azienda del cliente (Design/template-luce-specifica.md §9.3.4, «Luce» giro 7), come `ModuloFamiliare`:
// ragione sociale, forma, partita IVA (controllata con `MotoreFattura.partitaIVAValida`), settore, dipendenti, fatturato
// dell'ultimo anno e l'anno, utile, ruolo del cliente (quota, amministratore, titolare), reddito che ne ricava e, per le
// quattro aree, i dati che le valutano: mesi a rischio e coperture collegate (persona chiave), TFM accantonato sì/no
// (nessun calcolo fiscale, decisione 67), le voci di welfare e i passi della continuità scelti dall'utente (Prisma propone
// soltanto dei titoli da aggiungere). Tutto facoltativo tranne la ragione sociale.

struct ModuloAzienda: View {
    @Environment(\.dismiss) var chiudi
    @State var bozza: AziendaCliente
    let nuova: Bool
    let cliente: Cliente
    let posizioni: [Posizione]
    let salva: (AziendaCliente) -> Void
    let elimina: (AziendaCliente) -> Void

    init(modifica: ModificaAzienda, cliente: Cliente, posizioni: [Posizione],
         salva: @escaping (AziendaCliente) -> Void, elimina: @escaping (AziendaCliente) -> Void) {
        _bozza = State(initialValue: modifica.azienda)
        self.nuova = modifica.nuova
        self.cliente = cliente
        self.posizioni = posizioni
        self.salva = salva
        self.elimina = elimina
    }

    private var valido: Bool { !bozza.ragioneSociale.trimmingCharacters(in: .whitespaces).isEmpty }

    private var nome: String { TestiAzienda.nome(cliente) }

    /// Le posizioni in essere che possono coprire la persona chiave: protezione, o con un capitale assicurato.
    private var coperturePossibili: [Posizione] {
        posizioni.filter { $0.stato == .inEssere && ($0.area == .protezione || ($0.capitaleAssicurato ?? 0) > 0) }
    }

    var body: some View {
        CorniceModulo(titolo: nuova ? "Aggiungi l'azienda di \(nome)" : "Modifica l'azienda") {
            VStack(alignment: .leading, spacing: 12) {
                CampoModulo(etichetta: "Ragione sociale") {
                    TextField("", text: $bozza.ragioneSociale).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Forma") {
                    MenuTendina(selezione: $bozza.forma,
                                opzioni: [(FormaAzienda?.none, "Non indicata")] + FormaAzienda.allCases.map { (Optional($0), $0.nome) },
                                larghezza: 220)
                }
                CampoModulo(etichetta: "Partita IVA") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: testo(\.partitaIVA)).textFieldStyle(.roundedBorder)
                        if let p = bozza.partitaIVA, !p.isEmpty, !MotoreFattura.partitaIVAValida(p) {
                            Text("La partita IVA non sembra valida: 11 cifre con il carattere di controllo.")
                                .font(Tema.Testo.Inserimento.nota).foregroundColor(Colori.Rubrica.pericolo)
                        }
                    }
                }
                CampoModulo(etichetta: "Settore") {
                    TextField("", text: testo(\.settore)).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Dipendenti") {
                    CampoInteroFacoltativo(valore: $bozza.dipendenti, unita: "persone")
                }
                CampoModulo(etichetta: "Fatturato") {
                    HStack(spacing: Tema.Misura.Inserimento.spazioRiga) {
                        CampoCifraFacoltativa(valore: $bozza.fatturato, unita: "€ nell'anno", larghezza: Tema.Misura.Inserimento.campoEuro)
                        CampoInteroFacoltativo(valore: $bozza.annoFatturato, unita: "", larghezza: Tema.Apple.Azienda.campoAnno)
                    }
                }
                CampoModulo(etichetta: "Utile") {
                    CampoCifraFacoltativa(valore: $bozza.utile, unita: "€ nell'anno", larghezza: Tema.Misura.Inserimento.campoEuro)
                }
                GruppoCampi(titolo: "Il ruolo di \(nome)")
                CampoModulo(etichetta: "Quota") {
                    CampoCifraFacoltativa(valore: $bozza.quota, unita: "% del capitale")
                }
                CampoModulo(etichetta: "Amministratore") {
                    Toggle("\(nome) è amministratore", isOn: casella(\.amministratore)).stileCasella()
                }
                CampoModulo(etichetta: "Titolare") {
                    Toggle("Titolare (ditta individuale)", isOn: casella(\.titolare)).stileCasella()
                }
                CampoModulo(etichetta: "Reddito che ne ricava") {
                    CampoCifraFacoltativa(valore: $bozza.redditoDalCliente, unita: "€ l'anno tra compensi e utili",
                                          larghezza: Tema.Misura.Inserimento.campoEuro)
                }
                SezioneRipiegabile("Persona chiave", nota: bozza.personaChiave == nil ? nil : "indicata", aperta: nuova) {
                    CampoModulo(etichetta: "Mesi a rischio") {
                        CampoCifraFacoltativa(valore: personaChiave(\.mesiARischio),
                                              unita: "mesi di fatturato persi se \(nome) si ferma (tua valutazione)")
                    }
                    GruppoCampi(titolo: "Coperture «key man» in essere",
                                spiegazione: coperturePossibili.isEmpty
                                    ? "Nessuna posizione di protezione in essere per \(nome): la copertura resta a zero."
                                    : "Spunta le posizioni che coprono la persona chiave: il loro capitale assicurato conta nella copertura.")
                    ForEach(coperturePossibili) { p in
                        Toggle(isOn: collegata(p.id)) {
                            Text("\(p.nome) · \(p.canale.nomeBreve)\(p.capitaleAssicurato.map { " · " + Formati.euro($0) } ?? "")")
                        }
                        .stileCasella()
                    }
                }
                SezioneRipiegabile("Trattamento di fine mandato", nota: bozza.tfm?.accantonato.map { $0 ? "accantonato" : "non accantonato" }) {
                    CampoModulo(etichetta: "Accantonato") {
                        MenuTendina(selezione: tfm(\.accantonato),
                                    opzioni: [(Bool?.none, "Non indicato"), (Optional(true), "Sì"), (Optional(false), "No")],
                                    larghezza: 160)
                    }
                    CampoModulo(etichetta: "Importo") {
                        CampoCifraFacoltativa(valore: tfm(\.importo), unita: "€ accantonati", larghezza: Tema.Misura.Inserimento.campoEuro)
                    }
                    CampoModulo(etichetta: "Nota") {
                        TextField("", text: tfmNota).textFieldStyle(.roundedBorder)
                    }
                    Text(TestiAzienda.notaTFM)
                        .font(Tema.Testo.Inserimento.nota).foregroundColor(Tema.Colore.Inserimento.nota)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SezioneRipiegabile("Welfare aziendale", nota: nota(bozza.welfare)) {
                    ListaVociAzienda(lista: $bozza.welfare, proposte: VoceAzienda.propostePerWelfare, segno: "attiva",
                                     spiegazione: "Le voci che consideri per i dipendenti; spunta quelle già attive.")
                }
                SezioneRipiegabile("Passaggio dell'impresa", nota: nota(bozza.continuita)) {
                    ListaVociAzienda(lista: $bozza.continuita, proposte: VoceAzienda.propostePerContinuita, segno: "fatto",
                                     spiegazione: "I passi della continuità che consideri; spunta quelli già fatti.")
                }
                CampoModulo(etichetta: "Nota") {
                    TextField("", text: $bozza.nota).textFieldStyle(.roundedBorder)
                }
                Text(TestiAzienda.piedeFiscale)
                    .font(Tema.Testo.Inserimento.nota).foregroundColor(Tema.Colore.Inserimento.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } piede: {
            if !nuova {
                Button {
                    elimina(bozza)
                    chiudi()
                } label: {
                    Text("Elimina").foregroundColor(Colori.Rubrica.pericolo)
                }
                .buttonStyle(StileVetro())
            }
            Spacer()
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuova ? "Aggiungi" : "Salva") {
                salva(bozza)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(!valido)
            .opacity(valido ? 1 : 0.5)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: Tema.Apple.Azienda.modulo.width, height: Tema.Apple.Azienda.modulo.height)
    }

    // MARK: Legami con i campi facoltativi

    private func testo(_ k: WritableKeyPath<AziendaCliente, String?>) -> Binding<String> {
        Binding(get: { bozza[keyPath: k] ?? "" }, set: { bozza[keyPath: k] = $0 })
    }

    /// Spuntata = true; tolta la spunta = nil (non indicato), mai un «no» che l'utente non ha detto.
    private func casella(_ k: WritableKeyPath<AziendaCliente, Bool?>) -> Binding<Bool> {
        Binding(get: { bozza[keyPath: k] == true }, set: { bozza[keyPath: k] = $0 ? true : nil })
    }

    private func personaChiave<T>(_ k: WritableKeyPath<PersonaChiave, T>) -> Binding<T> {
        Binding(get: { (bozza.personaChiave ?? PersonaChiave())[keyPath: k] }, set: { nuovo in
            var p = bozza.personaChiave ?? PersonaChiave()
            p[keyPath: k] = nuovo
            bozza.personaChiave = p
        })
    }

    private func collegata(_ id: String) -> Binding<Bool> {
        Binding(get: { bozza.personaChiave?.posizioniCollegate.contains(id) ?? false }, set: { si in
            var p = bozza.personaChiave ?? PersonaChiave()
            p.posizioniCollegate.removeAll { $0 == id }
            if si { p.posizioniCollegate.append(id) }
            bozza.personaChiave = p
        })
    }

    private func tfm<T>(_ k: WritableKeyPath<StatoTFM, T>) -> Binding<T> {
        Binding(get: { (bozza.tfm ?? StatoTFM())[keyPath: k] }, set: { nuovo in
            var t = bozza.tfm ?? StatoTFM()
            t[keyPath: k] = nuovo
            bozza.tfm = t
        })
    }

    private var tfmNota: Binding<String> {
        Binding(get: { bozza.tfm?.nota ?? "" }, set: { nuovo in
            var t = bozza.tfm ?? StatoTFM()
            t.nota = nuovo
            bozza.tfm = t
        })
    }

    private func nota(_ l: ListaAzienda?) -> String? {
        guard let voci = l?.voci, !voci.isEmpty else { return nil }
        return "\(voci.filter(\.fatta).count) su \(voci.count)"
    }
}

/// Una lista di voci scelte dall'utente: spunta, titolo, togli; sotto i titoli proposti non ancora presenti e un campo
/// per una voce propria.
struct ListaVociAzienda: View {
    @Binding var lista: ListaAzienda?
    let proposte: [String]
    /// «attiva» o «fatto»: la parola accanto alla spunta.
    let segno: String
    let spiegazione: String
    @State private var nuova = ""

    var body: some View {
        let voci = lista?.voci ?? []
        let mancanti = proposte.filter { p in !voci.contains { $0.titolo.caseInsensitiveCompare(p) == .orderedSame } }
        return VStack(alignment: .leading, spacing: Tema.Misura.Inserimento.spazioRiga) {
            Text(spiegazione)
                .font(Tema.Testo.Inserimento.nota).foregroundColor(Tema.Colore.Inserimento.nota)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(voci) { v in
                HStack(spacing: Tema.Misura.Inserimento.spazioRiga) {
                    Toggle(isOn: fatta(v.id)) { Text("\(v.titolo) · \(segno)") }
                        .stileCasella()
                    Spacer(minLength: 0)
                    Button { togli(v.id) } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(StileSemplice())
                        .help("Togli dalla lista")
                        .accessibilityLabel("Togli \(v.titolo)")
                }
            }
            if !mancanti.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Tema.Apple.Azienda.colonnaProposta), alignment: .leading)],
                          alignment: .leading, spacing: Tema.Misura.Inserimento.spazioRiga) {
                    ForEach(mancanti, id: \.self) { p in
                        Button("＋ \(p)") { aggiungi(p) }
                            .buttonStyle(StileVetro())
                            .lineLimit(1)
                    }
                }
            }
            HStack(spacing: Tema.Misura.Inserimento.spazioRiga) {
                TextField("Un'altra voce", text: $nuova).textFieldStyle(.roundedBorder)
                Button("Aggiungi") {
                    aggiungi(nuova)
                    nuova = ""
                }
                .buttonStyle(StileVetro())
                .disabled(nuova.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func fatta(_ id: String) -> Binding<Bool> {
        Binding(get: { lista?.voci.first { $0.id == id }?.fatta ?? false }, set: { si in
            guard var l = lista, let i = l.voci.firstIndex(where: { $0.id == id }) else { return }
            l.voci[i].fatta = si
            lista = l
        })
    }

    private func aggiungi(_ titolo: String) {
        let t = titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var l = lista ?? ListaAzienda()
        l.voci.append(VoceAzienda(titolo: t))
        lista = l
    }

    private func togli(_ id: String) {
        guard var l = lista else { return }
        l.voci.removeAll { $0.id == id }
        lista = l
    }
}
