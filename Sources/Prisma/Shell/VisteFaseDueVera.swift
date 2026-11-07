import SwiftUI
import UniformTypeIdentifiers

// Le viste della fase 2 di Vera (Design/template-vera.html): la cornice di «Lascia cadere qui» sulla finestra di Vera,
// la pagina della memoria (ricordi su di te e sui clienti, lezioni, interruttori), 👍 e 👎 sotto le risposte con la
// correzione che diventa una lezione, «Il cliente in 30 secondi» con le sue fonti e le citazioni delle norme.

private typealias F = Tema.Apple.FaseDueVera

// MARK: - Lascia cadere qui

private struct RilascioDocumentiVera: ViewModifier {
    @EnvironmentObject var stato: StatoShell
    @State private var sopra = false

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onDrop(of: [UTType.fileURL], isTargeted: $sopra) { fornitori in
                guard !stato.solaLettura else { return false }
                let raccolta = RaccoltaRilascio()
                let gruppo = DispatchGroup()
                for f in fornitori {
                    gruppo.enter()
                    _ = f.loadObject(ofClass: URL.self) { url, _ in
                        DispatchQueue.main.async {
                            if let url { raccolta.urls.append(url) }
                            gruppo.leave()
                        }
                    }
                }
                gruppo.notify(queue: .main) { stato.lasciaCadere(raccolta.urls) }
                return true
            }
            .overlay {
                if sopra {
                    ZStack {
                        RoundedRectangle(cornerRadius: F.raggioCornice, style: .continuous).fill(F.fondoCornice)
                        RoundedRectangle(cornerRadius: F.raggioCornice, style: .continuous)
                            .strokeBorder(F.cornice, style: StrokeStyle(lineWidth: F.spessoreCornice, dash: F.trattino))
                        VStack(spacing: 6) {
                            Text("Lascia cadere qui").carattereApple(F.testoCornice).foregroundColor(Tema.Apple.Colore.inchiostro)
                            Text("PDF, foto o scansione: Vera lo legge sul Mac, riconosce il cliente e ti chiede conferma.")
                                .carattereApple(F.notaCornice).foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            #endif
    }
}

extension View {
    func rilascioDocumentiVera() -> some View { modifier(RilascioDocumentiVera()) }

    func paginaMemoriaVera(_ memoria: StatoMemoriaVera) -> some View { modifier(PaginaMemoriaVera(memoria: memoria)) }
}

// MARK: - La memoria

private struct PaginaMemoriaVera: ViewModifier {
    @ObservedObject var memoria: StatoMemoriaVera

    func body(content: Content) -> some View {
        content.sheet(isPresented: $memoria.aperta) { MemoriaVeraVista(memoria: memoria) }
    }
}

/// La pagina dei ricordi: «Vera ricorda», su di te e sui clienti (✎ e ✕), le lezioni dalle correzioni.
struct MemoriaVeraVista: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var memoria: StatoMemoriaVera
    @State private var inModifica: String?
    @State private var testo = ""
    @State private var password = ""
    @State private var confermaRicomincia = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("La memoria di Vera").carattereApple(F.titoloPagina)
                Spacer()
                Button("Fine") { memoria.aperta = false }.buttonStyle(.applePrimario)
            }
            HStack(spacing: 12) {
                Toggle("Vera ricorda", isOn: $stato.dati.impostazioni.vera.memoriaAttiva).toggleStyle(.switch)
                Text("\(memoria.ricordi.count) ricordi · sul Mac, cifrati").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                Spacer()
                pillola("Non ricorda mai: numeri di documenti, conti, password")
            }
            if memoria.bloccata { bloccata } else { colonne }
        }
        .padding(F.paddingPagina)
        .frame(width: F.larghezzaPagina, height: F.altezzaPagina)
    }

    private var bloccata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("La memoria non si apre su questo Mac").carattereApple(F.titoloColonna)
            Text("Arriva da un backup: scrivi la password dei backup per aprirla, oppure ricomincia da capo (i ricordi di prima si perdono).")
                .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            HStack {
                SecureField("Password dei backup", text: $password).textFieldStyle(.roundedBorder).frame(maxWidth: 280)
                Button("Apri") { if memoria.sblocca(password: password) { password = "" } else { stato.mostraAvviso("Password sbagliata") } }
                    .buttonStyle(.applePrimario)
                Button("Ricomincia da capo") { confermaRicomincia = true }.buttonStyle(.apple)
            }
            Spacer()
        }
        .alert("Cancellare la memoria di Vera?", isPresented: $confermaRicomincia) {
            Button("Annulla", role: .cancel) {}
            Button("Ricomincia da capo", role: .destructive) { memoria.ricomincia() }
        } message: {
            Text("I ricordi, le lezioni e gli esempi arrivati dal backup si perdono per sempre. Con la password dei backup puoi ancora aprirli.")
        }
    }

    private var colonne: some View {
        HStack(alignment: .top, spacing: F.spazioColonne) {
            colonna("Su di te", memoria.ricordi.filter { $0.clienteId == nil })
            colonna("Sui clienti", memoria.ricordi.filter { $0.clienteId != nil })
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Le lezioni").carattereApple(F.titoloColonna)
                    Spacer()
                    Toggle("", isOn: $stato.dati.impostazioni.vera.imparaDalleCorrezioni).toggleStyle(.switch).labelsHidden()
                        .help("Impara dalle correzioni")
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if memoria.lezioni.isEmpty {
                            Text("Nessuna lezione: con 👎 sotto una risposta scrivi cosa non va, e Vera lo rilegge prima di rispondere.")
                                .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                        }
                        ForEach(memoria.lezioni.reversed()) { l in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(l.testo).carattereApple(F.ricordo).opacity(l.attiva ? 1 : 0.5)
                                    Text("\(Formati.giornoMese.string(from: l.data)), \(l.fonte)").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                                }
                                Spacer(minLength: 0)
                                tasto(l.attiva ? "pause" : "play") { memoria.alternaLezione(l.id) }
                                tasto("xmark") { memoria.eliminaLezione(l.id) }
                            }
                            .padding(F.paddingRicordo)
                            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func colonna(_ titolo: String, _ ricordi: [RicordoVera]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titolo).carattereApple(F.titoloColonna)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if ricordi.isEmpty {
                        Text("Ancora niente: di' a Vera «ricorda che…» oppure conferma i ricordi che ti propone.")
                            .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                    }
                    ForEach(ricordi.reversed()) { r in voce(r) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func voce(_ r: RicordoVera) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let id = r.clienteId, let c = stato.cliente(id) {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatarRicordo)
            }
            VStack(alignment: .leading, spacing: 2) {
                if inModifica == r.id {
                    TextField("Ricordo", text: $testo, onCommit: {
                        memoria.modificaRicordo(r.id, testo: testo)
                        inModifica = nil
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(r.testo).carattereApple(F.ricordo)
                }
                Text("\(Formati.giornoMese.string(from: r.data)), \(r.fonte)").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            }
            Spacer(minLength: 0)
            tasto("pencil") { testo = r.testo; inModifica = r.id }
            tasto("xmark") { memoria.dimentica(r.id); stato.mostraAvviso("Dimenticato: Vera non lo userà più") }
        }
        .padding(F.paddingRicordo)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    private func tasto(_ simbolo: String, _ fai: @escaping () -> Void) -> some View {
        Button(action: fai) {
            Image(systemName: simbolo).carattereApple(Tema.Apple.ConfermaVera.segnoCarattere).frame(width: F.tasto, height: F.tasto)
                .background(Circle().fill(F.fondoPillola))
        }
        .buttonStyle(.plain)
    }

    private func pillola(_ t: String) -> some View {
        Text(t).carattereApple(F.pillola).foregroundColor(F.testoPillola).padding(F.paddingPillola).background(Capsule().fill(F.fondoPillola))
    }
}

// MARK: - 👍 e 👎

/// Sotto una risposta di Vera: 👍 la segna come buona, 👎 apre la correzione che diventa una lezione.
struct PolliciVera: View {
    @EnvironmentObject var stato: StatoShell
    let messaggio: MessaggioVera
    @State private var correggi = false
    @State private var testo = ""
    @State private var salvata = false

    var body: some View {
        // Con «Impara dalle correzioni» o la memoria spenti i pollici non ci sono
        if stato.dati.impostazioni.vera.imparaDalleCorrezioni && stato.dati.impostazioni.vera.memoriaAttiva { pollici }
    }

    private var pollici: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button("👍") { stato.approvaRispostaVera(messaggio.id) }
                    .buttonStyle(StilePulsanteApple(messaggio.voto == true ? .principale : .secondaria))
                    .help("Va bene")
                Button("👎") { correggi = true }
                    .buttonStyle(StilePulsanteApple(messaggio.voto == false ? .principale : .secondaria))
                    .help("Non va: scrivi cosa correggere")
                if salvata {
                    Label("Lezione salvata", systemImage: "checkmark").carattereApple(F.fonteSezione).foregroundColor(F.votoDato)
                }
            }
            if correggi && !salvata {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cosa non va?").carattereApple(Tema.Apple.Carattere.etichetta).foregroundColor(F.coloreFonte)
                    TextField("Per esempio: con i clienti Alleanza parla di «piano», non di «prodotto»", text: $testo)
                        .textFieldStyle(.plain)
                        .carattereApple(F.correzione)
                        .padding(F.paddingCorrezione)
                        .background(RoundedRectangle(cornerRadius: F.raggioCorrezione, style: .continuous).fill(F.fondoCorrezione))
                    HStack(spacing: 6) {
                        Button("Salva la lezione") {
                            if stato.correggiRispostaVera(messaggio.id, correzione: testo) != nil { salvata = true }
                        }
                        .buttonStyle(.applePrimario)
                        .disabled(testo.trimmingCharacters(in: .whitespaces).count < 4)
                        Text("Vale per tutte le risposte future, non solo per questa.").carattereApple(F.fonteSezione).foregroundColor(F.coloreFonte)
                    }
                }
            }
        }
    }
}

// MARK: - Il cliente in 30 secondi

struct TrentaSecondiVista: View {
    @EnvironmentObject var stato: StatoShell
    let scheda: SchedaTrentaSecondi

    var body: some View {
        VStack(alignment: .leading, spacing: F.spazioSezioni) {
            HStack(spacing: 10) {
                if let c = stato.cliente(scheda.clienteId) {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatarTrenta)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scheda.nome).carattereApple(F.titoloCitazione)
                    if !scheda.tema.isEmpty { Text(scheda.tema).carattereApple(F.tema).foregroundColor(F.coloreFonte) }
                }
                Spacer(minLength: 0)
                ForEach(scheda.canali, id: \.self) { EtichettaCanaleApple(canale: $0, compatta: true) }
            }
            ForEach(Array(scheda.sezioni.enumerated()), id: \.offset) { _, s in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(s.titolo).carattereApple(F.titoloSezione).foregroundColor(F.coloreTitoloSezione)
                        Spacer()
                        Text(s.fonte).carattereApple(F.fonteSezione).foregroundColor(F.coloreFonte)
                    }
                    Text(s.testo).carattereApple(F.testoSezione).fixedSize(horizontal: false, vertical: true)
                }
                .padding(F.paddingSezione)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            }
            Text("Da dove arriva: la scheda · \(scheda.incontri) incontri · \(scheda.messaggi) messaggi quest'anno · \(scheda.ricordi) ricordi · \(scheda.documenti) documenti")
                .carattereApple(F.fonti).foregroundColor(F.coloreFonte)
        }
        .padding(.top, F.sopraScheda)
    }
}

// MARK: - Le norme citate

struct NormeVeraVista: View {
    @EnvironmentObject var stato: StatoShell
    let risposta: RispostaNorme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if risposta.nonRisponde {
                Label("Cercato in \(risposta.articoliCercati) articoli: la norma non risponde", systemImage: "magnifyingglass")
                    .carattereApple(F.fonti).foregroundColor(F.nonRisponde)
            }
            ForEach(risposta.citazioni) { c in
                HStack(spacing: 11) {
                    IconaApp(app: .biblioteca, lato: F.iconaCitazione)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.etichetta + (c.rubrica.isEmpty ? "" : " · \(c.rubrica)")).carattereApple(F.titoloCitazione)
                        Text("\(c.sigla.isEmpty ? "" : c.sigla + " · ")\(c.edizione) · pagina \(c.pagina) · dal testo che hai caricato nella biblioteca")
                            .carattereApple(F.dettaglioCitazione).foregroundColor(F.coloreFonte).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Button("Apri l'articolo") { stato.apriArticolo(c) }.buttonStyle(.apple)
                }
                .padding(F.paddingCitazione)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            }
        }
        .padding(.top, F.sopraScheda)
    }
}
