import SwiftUI

// Impostazioni › Portafogli modello (Design/template-luce-specifica.md §8.3.5 punto 5, «Luce» giro 2): i modelli del
// radar con i pesi delle quattro classi (la somma deve fare 100, altrimenti «mancano 5 punti»), la tolleranza generale
// e quella di ogni modello, e il modello di ogni cliente con investimenti. Nessun valore predefinito: i modelli e la
// tolleranza li scrive l'utente (i tre del template sono solo nei dati di prova, con la nota «Dati di prova»).
// Come le altre pagine del tema Apple: righe come card senza ombra, titolo a sinistra, campi a destra.

struct PaginaImpostazioniModelli: View {
    @Environment(StatoShell.self) var stato

    private typealias F = Tema.Apple.Studio.Impostazioni
    private typealias Riga = Tema.Apple.Impostazioni.Riga
    private typealias C = ComposizioneInvestimenti360.Classe

    var body: some View {
        let _ = ContaCorpi.segna()
        let modelli = stato.dati.portafogliModello
        let clienti = clientiConInvestimenti
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Il radar di Posizioni misura quanto ogni cliente si è allontanato dal suo portafoglio "
                             + "modello. Modelli, pesi e tolleranza li scrivi tu: Prisma non li inventa.")
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Tolleranza") {
                    RigaImpostazione(titolo: "Tolleranza generale",
                                     sottotitolo: "Oltre questa distanza dal modello il cliente è «fuori» sul radar",
                                     aiuto: "La distanza è la metà della somma degli scarti fra le quote di oggi e i pesi del "
                                        + "modello: dice quanta parte del portafoglio va spostata. Vuota: nessuno è segnato fuori.",
                                     ultima: true) {
                        CampoNumeroModelli(unita: "punti", valore: Binding(
                            get: { stato.dati.impostazioni.tolleranzaRadar },
                            set: { stato.dati.impostazioni.tolleranzaRadar = $0.map { max(0, $0) } }))
                            .disabled(stato.solaLettura)
                    }
                }
                .cascataImpostazioni(1)
            }
            ForEach(Array(modelli.enumerated()), id: \.element.id) { i, m in
                gruppoModello(m)
                    .cascataImpostazioni(2 + i)
            }
            HStack {
                Button("Aggiungi un modello") { aggiungi() }
                    .buttonStyle(.apple)
                    .disabled(stato.solaLettura)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Il modello di ogni cliente") {
                    if clienti.isEmpty {
                        RigaImpostazione(titolo: "Nessun cliente con investimenti", ultima: true) { EmptyView() }
                    }
                    ForEach(Array(clienti.enumerated()), id: \.element.id) { i, c in
                        RigaImpostazione(titolo: c.nome, sottotitolo: c.profilo.propensione.map { "Profilo \($0.nome.lowercased())" },
                                         ultima: i == clienti.count - 1) {
                            Picker("", selection: Binding(
                                get: { c.modelloId ?? "" },
                                set: { assegna(c.id, $0.isEmpty ? nil : $0) })) {
                                Text("Nessun modello").tag("")
                                ForEach(modelli) { m in Text(m.nome.isEmpty ? "Senza nome" : m.nome).tag(m.id) }
                            }
                            .labelsHidden()
                            .frame(width: Tema.Apple.Posizioni.Radar.Impostazioni.sceltaModello)
                            .disabled(stato.solaLettura || modelli.isEmpty)
                        }
                    }
                }
                NotaImpostazioni("Il modello è una scelta tua, separata dal profilo MiFID del cliente: se chiede più azioni di "
                                 + "quante ne regga il profilo, il radar lo segnala nel dettaglio. La previdenza non entra nel radar.")
            }
            .cascataImpostazioni(2 + modelli.count)
        }
    }

    /// I clienti con posizioni finanziarie in essere (quelle che il radar considera).
    private var clientiConInvestimenti: [Cliente] {
        let ids = Set(MotoreRadar.considerate(stato.dati.posizioni).map(\.clienteId))
        return stato.dati.clienti.filter { ids.contains($0.id) }.sorted { $0.nome < $1.nome }
    }

    private func gruppoModello(_ m: PortafoglioModello) -> some View {
        let somma = m.pesi.somma
        let mancano = 100 - somma
        return VStack(alignment: .leading, spacing: Riga.fraRighe) {
            GruppoImpostazioni(titolo: m.nome.isEmpty ? "Nuovo modello" : m.nome) {
                RigaImpostazione(titolo: "Nome e colore", sottotitolo: m.note.isEmpty ? nil : m.note) {
                    HStack(spacing: F.spazioCampi) {
                        TextField("Nome", text: legame(m.id, \.nome))
                            .campoTesto()
                            .frame(width: Tema.Apple.Posizioni.Radar.Impostazioni.campoNome)
                        Picker("", selection: legame(m.id, \.colore)) {
                            ForEach(ColoreModello.allCases) { c in Text(c.nome).tag(c) }
                        }
                        .labelsHidden()
                        .frame(width: Tema.Apple.Posizioni.Radar.Impostazioni.sceltaColore)
                    }
                    .disabled(stato.solaLettura)
                }
                RigaImpostazione(titolo: "Pesi delle classi",
                                 sottotitolo: TestiRadar.leggendaClassi,
                                 avvertenza: m.pesi.completi ? nil
                                    : (mancano > 0 ? "Mancano \(TestiRadar.puntiConNome(mancano)) per arrivare a 100"
                                                   : "Ci sono \(TestiRadar.puntiConNome(-mancano)) di troppo: la somma deve fare 100")) {
                    HStack(alignment: .bottom, spacing: F.spazioCampi) {
                        ForEach(C.allCases) { c in
                            CampoNumeroModelli(etichetta: TestiRadar.nomeClasse(c), unita: "%", valore: Binding(
                                get: { m.pesi[c] },
                                set: { v in modifica(m.id) { $0.pesi[c] = max(0, min(100, v ?? 0)) } }))
                        }
                    }
                    .disabled(stato.solaLettura)
                }
                RigaImpostazione(titolo: "Tolleranza del modello", sottotitolo: "Vuota: vale quella generale", ultima: true) {
                    HStack(spacing: F.spazioCampi) {
                        CampoNumeroModelli(unita: "punti", valore: Binding(
                            get: { m.tolleranza },
                            set: { v in modifica(m.id) { $0.tolleranza = v.map { max(0, $0) } } }))
                        Button("Togli") { togli(m.id) }
                            .buttonStyle(.appleSobrio)
                    }
                    .disabled(stato.solaLettura)
                }
            }
        }
    }

    // MARK: Modifiche

    private func legame<T>(_ id: String, _ campo: WritableKeyPath<PortafoglioModello, T>) -> Binding<T> {
        Binding(get: { stato.dati.portafogliModello.first { $0.id == id }![keyPath: campo] },
                set: { v in modifica(id) { $0[keyPath: campo] = v } })
    }

    private func modifica(_ id: String, _ cambia: (inout PortafoglioModello) -> Void) {
        guard !stato.solaLettura, let i = stato.dati.portafogliModello.firstIndex(where: { $0.id == id }) else { return }
        cambia(&stato.dati.portafogliModello[i])
    }

    private func aggiungi() {
        guard !stato.solaLettura else { return }
        let usati = Set(stato.dati.portafogliModello.map(\.colore))
        let colore = ColoreModello.allCases.first { !usati.contains($0) } ?? .verde
        stato.dati.portafogliModello.append(PortafoglioModello(nome: "", colore: colore, pesi: PesiModello()))
    }

    /// Toglie il modello e lo toglie ai clienti che lo avevano (tornano «senza modello»).
    private func togli(_ id: String) {
        guard !stato.solaLettura else { return }
        stato.dati.portafogliModello.removeAll { $0.id == id }
        for i in stato.dati.clienti.indices where stato.dati.clienti[i].modelloId == id {
            stato.dati.clienti[i].modelloId = nil
        }
    }

    private func assegna(_ clienteId: String, _ modelloId: String?) {
        guard !stato.solaLettura, let i = stato.dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return }
        stato.dati.clienti[i].modelloId = modelloId
    }
}

/// Un campo numerico della pagina: etichetta facoltativa sopra, il valore (vuoto = nil) e l'unità accanto.
private struct CampoNumeroModelli: View {
    var etichetta: String? = nil
    let unita: String
    @Binding var valore: Double?

    init(etichetta: String? = nil, unita: String, valore: Binding<Double?>) {
        self.etichetta = etichetta
        self.unita = unita
        _valore = valore
    }

    init(etichetta: String? = nil, unita: String, valore: Binding<Double>) {
        self.etichetta = etichetta
        self.unita = unita
        _valore = Binding(get: { valore.wrappedValue }, set: { valore.wrappedValue = $0 ?? 0 })
    }

    var body: some View {
        let f = Tema.Apple.Studio.Impostazioni.self
        VStack(alignment: .trailing, spacing: f.spazioEtichetta) {
            if let etichetta {
                Text(etichetta)
                    .carattereApple(f.etichettaCampo)
                    .foregroundColor(f.coloreEtichettaCampo)
                    .lineLimit(1)
            }
            HStack(spacing: f.spazioUnita) {
                TextField("", value: $valore, format: FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti)
                            .precision(.fractionLength(0...1)), prompt: Text(verbatim: "—"))
                    .campoTesto()
                    .multilineTextAlignment(.trailing)
                    .frame(width: f.campoPercentuale)
                Text(unita)
                    .carattereApple(f.unita)
                    .foregroundColor(f.coloreUnita)
                    .lineLimit(1)
            }
        }
    }
}
