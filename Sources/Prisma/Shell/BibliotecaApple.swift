#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

/// La Biblioteca delle norme (Vera, funzione 13; Luce, «Trova la pagina»): a sinistra i testi caricati dall'utente con
/// sigla ed edizione, in mezzo gli articoli (con la ricerca), a destra il testo dell'articolo. Si aggiungono PDF con il
/// pulsante o trascinandoli. Vera risponde alle domande sulle norme citando l'articolo («Apri l'articolo» porta qui).
struct BibliotecaApple: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var biblioteca: StatoBiblioteca
    @State private var sopra = false

    private typealias F = Tema.Apple.FaseDueVera

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(alignment: .top, spacing: F.spazioBiblioteca) {
            testi.frame(width: F.colonnaTesti)
            articoli.frame(width: F.colonnaArticoli)
            articolo.frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(F.paddingBiblioteca)
        .onAppear {
            biblioteca.carica()
            if biblioteca.scelto == nil { biblioteca.scelto = biblioteca.tutti.first?.id }
        }
        #if os(macOS)
        .onDrop(of: [UTType.fileURL], isTargeted: $sopra) { fornitori in
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
            gruppo.notify(queue: .main) { biblioteca.importa(raccolta.urls) { stato.mostraAvviso($0) } }
            return true
        }
        #endif
    }

    private var scelto: TestoNorma? { biblioteca.tutti.first { $0.id == biblioteca.scelto } }

    private var testi: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                IconaApp(app: .biblioteca, lato: F.iconaCitazione)
                Text("La biblioteca delle norme").carattereApple(F.titoloColonna)
            }
            Text("Testi ufficiali caricati da te, sul Mac. Vera risponde citando l'articolo.")
                .carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(biblioteca.tutti) { t in
                        Button { biblioteca.scelto = t.id; biblioteca.articoloScelto = nil } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.titolo).carattereApple(F.titoloTesto).foregroundColor(Tema.Apple.Colore.inchiostro)
                                Text([t.sigla, t.edizione, "\(t.articoli.count) articoli"].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte).lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(F.paddingVoce)
                            .background(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                                .fill(t.id == biblioteca.scelto ? F.fondoScelto : Color.clear))
                        }
                        .buttonStyle(.plain)
                        .contextMenu { Button("Togli dalla Biblioteca", role: .destructive) { biblioteca.elimina(t.id) } }
                    }
                    ForEach(biblioteca.inLettura, id: \.self) { n in
                        Label("Leggo «\(n)»…", systemImage: "hourglass").carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte)
                    }
                    if biblioteca.tutti.isEmpty && biblioteca.inLettura.isEmpty {
                        Text("Nessun testo: aggiungi i PDF delle norme che usi (TUF, Regolamento Intermediari, codice delle assicurazioni…), con la loro edizione.")
                            .carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte)
                    }
                }
            }
            Button("Aggiungi un testo…") { scegli() }.buttonStyle(.applePrimario)
            if let t = scelto { ModificaTestoNorma(testo: t) { id, ti, si, ed in biblioteca.modifica(id, titolo: ti, sigla: si, edizione: ed) } }
        }
    }

    private var articoliFiltrati: [ArticoloNorma] {
        guard let t = scelto else { return [] }
        let q = biblioteca.cerca.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return t.articoli }
        let pezzi = t.articoli.map { PezzoRicerca(id: $0.id, tipo: .norma, clienteId: nil, fonte: "", testo: $0.rubrica + "\n" + $0.testo) }
        let trovati = RicercaVera.cerca(q, in: pezzi, quanti: 30).map(\.pezzo.id)
        let perNumero = t.articoli.filter { $0.numero == q.lowercased() || "art. \($0.numero)" == q.lowercased() }
        return perNumero + trovati.compactMap { id in t.articoli.first { $0.id == id } }.filter { a in !perNumero.contains(a) }
    }

    private var articoli: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Cerca negli articoli", text: $biblioteca.cerca).textFieldStyle(.roundedBorder)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(articoliFiltrati) { a in
                        Button { biblioteca.articoloScelto = a.id } label: {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Art. \(a.numero)").carattereApple(F.titoloArticolo).foregroundColor(Tema.Apple.Colore.inchiostro)
                                if !a.rubrica.isEmpty {
                                    Text(a.rubrica).carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte).lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(F.paddingVoce)
                            .background(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                                .fill(a.id == biblioteca.articoloScelto ? F.fondoScelto : Color.clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var articolo: some View {
        ScrollView {
            if let t = scelto, let a = t.articoli.first(where: { $0.id == biblioteca.articoloScelto }) ?? t.articoli.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(t.titolo) · art. \(a.numero)").carattereApple(F.titoloColonna)
                    Text([t.sigla, t.edizione, "pagina \(a.pagina)"].filter { !$0.isEmpty }.joined(separator: " · "))
                        .carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte)
                    if !a.rubrica.isEmpty { Text(a.rubrica).carattereApple(F.titoloTesto) }
                    Text(a.testo).carattereApple(F.testoArticolo).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                }
                .padding(F.paddingArticolo)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            } else {
                Text("Scegli un testo e un articolo.").carattereApple(F.siglaTesto).foregroundColor(F.coloreFonte)
            }
        }
    }

    private func scegli() {
        #if os(macOS)
        let p = NSOpenPanel()
        p.allowedContentTypes = [.pdf]
        p.allowsMultipleSelection = true
        p.prompt = "Aggiungi"
        p.message = "Scegli i PDF delle norme: restano sul Mac, nella Biblioteca di Prisma."
        if p.runModal() == .OK { biblioteca.importa(p.urls) { stato.mostraAvviso($0) } }
        #endif
    }
}

/// Titolo, sigla ed edizione del testo scelto (ogni citazione porta l'edizione).
private struct ModificaTestoNorma: View {
    let testo: TestoNorma
    let salva: (String, String, String, String) -> Void
    @State private var idCaricato: String?
    @State private var titolo = ""
    @State private var sigla = ""
    @State private var edizione = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Titolo", text: $titolo, onCommit: invia).textFieldStyle(.roundedBorder)
            TextField("Sigla (es. D.Lgs. 209/2005)", text: $sigla, onCommit: invia).textFieldStyle(.roundedBorder)
            TextField("Edizione (es. aggiornato al 1° ottobre 2026)", text: $edizione, onCommit: invia).textFieldStyle(.roundedBorder)
        }
        .onAppear(perform: copia)
        // Cambiando testo (o lasciando la pagina) quello che hai scritto si salva, anche senza Invio
        .onChange(of: testo.id) { _ in invia(); copia() }
        .onDisappear(perform: invia)
    }

    private func copia() {
        idCaricato = testo.id
        titolo = testo.titolo
        sigla = testo.sigla
        edizione = testo.edizione
    }

    private func invia() {
        guard let id = idCaricato, titolo != testo.titolo || sigla != testo.sigla || edizione != testo.edizione || id != testo.id else { return }
        salva(id, titolo, sigla, edizione)
    }
}
