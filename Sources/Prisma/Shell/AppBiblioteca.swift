#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.1, «Luce» giro 6):
//
//   ┌ I DOCUMENTI      6 + ┐ ┌ (●) Chiedi qualcosa ai tuoi documenti…              [Cerca] ┐
//   │ [▤] Piano rivalut…   │  (Il riscatto…?) (Quanto si deduce…?) (Se Marco…?)
//   │     Condizioni · 38  │ ┌ tile di Vera ──────────┐ ┌ vassoio ── pagina 14 di 38 ──────┐
//   │ [▤] …                │ │ (●) Vera  ho cercato… │ │   ┌ foglio ─────────────────┐    │
//   │                      │ │ risposta              │ │   │ Art. 9 · Riscatto       │    │
//   │ Trascina qui i PDF…  │ │ [▤ Piano] [Pagina 14] │ │   │ ████ frase evidenziata  │    │
//   └──────────────────────┘ └───────────────────────┘ │   └─────────────────────────┘    │
//                            [Mostra al cliente] [Copia la citazione]                      ┘
//
// La barra laterale è il solo elenco dei documenti (gli stessi di «Il codice in tasca»): clic apre il documento nel
// vassoio, menu contestuale per genere, canale, prodotto, Finder e «Togli». Su iPhone e iPad non c'è (decisione 114).

/// Il contenuto della Biblioteca.
struct AppBiblioteca: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        #if os(macOS)
        VistaBiblioteca(biblioteca: stato.biblioteca, trova: stato.trovaPagina)
        #else
        // Su iPhone e iPad la Biblioteca non c'è in questo giro (decisione 114): più avanti dal ponte di Vera
        let n = NovitaLuce.trovaLaPagina
        InArrivoAppLuce(app: .biblioteca, glifo: n.glifo, titolo: n.titolo, frase: n.frase + ".",
                        nota: "La Biblioteca è sul Mac: i PDF che porti tu, letti sul Mac, con la pagina giusta.")
        #endif
    }
}

#if os(macOS)
struct VistaBiblioteca: View {
    @Environment(StatoShell.self) var stato
    let biblioteca: StatoBiblioteca
    // La domanda (un tasto alla volta) la legge solo la barra e le letture in corso (una pagina alla volta) solo la
    // barra laterale: ognuna sta nella sua vista, così non ridisegnano il vassoio con il foglio
    let trova: StatoTrovaPagina
    @State private var sopra = false
    @State private var daTogliere: String?
    @State private var daModificare: String?

    private typealias B = Tema.Apple.Biblioteca
    private typealias C = Tema.Apple.Colore

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(alignment: .top, spacing: B.spazioLaterale) {
            LateraleBiblioteca(biblioteca: biblioteca, trova: trova, sopra: sopra, daTogliere: $daTogliere,
                               daModificare: $daModificare)
                .frame(width: B.larghezzaLaterale)
                .entrataCascata(0, base: B.baseCascata)
            principale
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(B.margine)
        .onAppear {
            biblioteca.carica()
            trova.preparaIndice()
            apriArticoloChiesto()
        }
        .onDisappear { PagineBiblioteca.libera() }
        .onChange(of: biblioteca.articoloScelto) { _ in apriArticoloChiesto() }
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
            gruppo.notify(queue: .main) { stato.importaInBiblioteca(raccolta.urls) }
            return true
        }
        .confirmationDialog("Togliere il documento dalla Biblioteca?", isPresented: Binding(get: { daTogliere != nil }, set: { if !$0 { daTogliere = nil } }),
                            titleVisibility: .visible) {
            Button("Togli dalla Biblioteca", role: .destructive) {
                if let id = daTogliere { stato.togliDallaBiblioteca(id) }
                daTogliere = nil
            }
            Button("Annulla", role: .cancel) { daTogliere = nil }
        } message: {
            Text("Il PDF e il suo testo escono da Prisma. I backup già fatti non cambiano.")
        }
        .sheet(isPresented: Binding(get: { daModificare != nil }, set: { if !$0 { daModificare = nil } })) {
            if let id = daModificare, let d = stato.documentoBiblioteca(id) {
                ModuloDocumentoBiblioteca(documento: d) { titolo, edizione in
                    biblioteca.modifica(id, titolo: titolo, sigla: d.sigla, edizione: edizione)
                    daModificare = nil
                } annulla: { daModificare = nil }
            }
        }
    }

    /// «Apri l'articolo» dalla risposta di Vera («Il codice in tasca»): il documento sulla pagina dell'articolo.
    private func apriArticoloChiesto() {
        guard let a = biblioteca.articoloScelto, let t = biblioteca.scelto,
              let art = stato.documentoBiblioteca(t)?.articoli.first(where: { $0.id == a }) else { return }
        stato.apriDocumentoBiblioteca(t, pagina: art.pagina)
        biblioteca.articoloScelto = nil
    }

    private var documenti: [DocumentoBiblioteca] { biblioteca.tutti }

    // MARK: - Colonna principale

    private var principale: some View {
        VStack(alignment: .leading, spacing: 0) {
            BarraDomandaBiblioteca(trova: trova, senzaDocumenti: documenti.isEmpty)
                .entrataCascata(1, base: B.baseCascata)
            suggerimenti
                .padding(.top, B.sottoDomanda)
                .entrataCascata(2, base: B.baseCascata)
            zonaRisposta
                .padding(.top, B.sopraRisposta)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder private var suggerimenti: some View {
        let elenco = stato.suggerimentiBiblioteca
        if !elenco.isEmpty {
            HStack(spacing: B.spazioSuggerimenti) {
                ForEach(elenco, id: \.self) { s in
                    Button {
                        trova.domanda = s
                        stato.chiediBiblioteca(s)
                    } label: { PillolaSpuntoVera(simbolo: "text.magnifyingglass", testo: s) }
                    .buttonStyle(StileSemplice())
                }
            }
            .padding(.vertical, abs(Tema.Apple.Moto.SuggerimentoSopra.spostamento))
        }
    }

    // MARK: - Risposta

    @ViewBuilder private var zonaRisposta: some View {
        if documenti.isEmpty && trova.letture.isEmpty {
            vuota
        } else if let a = trova.aperta, let d = stato.documentoBiblioteca(a.documentoId) {
            documentoAperto(d, pagina: a.pagina)
        } else if let r = trova.risultato {
            risultato(r)
        } else {
            Text("Fai una domanda: la risposta arriva con la pagina giusta, aperta e illuminata.")
                .carattereApple(B.invito)
                .foregroundColor(B.coloreInvito)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, B.sopraInvito)
        }
    }

    private var vuota: some View {
        VStack(spacing: 16) {
            TasselloGlifo(glifo: .libro, lato: Tema.Apple.Tassello.latoSalaGrande)
            Text("Trascina qui le condizioni, i KID e le circolari che usi: Prisma li legge sul Mac.")
                .carattereApple(B.invito)
                .foregroundColor(B.coloreInvito)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
            Button("Scegli i PDF…") { stato.scegliDocumentiBiblioteca() }
                .buttonStyle(.applePrimarioGrande)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, B.sopraInvito - 40)
    }

    @ViewBuilder private func risultato(_ r: RisultatoBiblioteca) -> some View {
        if r.stato == .nonTrovata {
            VStack(alignment: .leading, spacing: B.sottoTile) {
                tile(r)
                if !r.vicini.isEmpty {
                    Text("Le pagine più vicine").carattereApple(B.etichetta).foregroundColor(B.coloreEtichetta)
                    VStack(alignment: .leading, spacing: B.spazioChip) {
                        ForEach(r.vicini) { p in
                            if let d = stato.documentoBiblioteca(p.documentoId) {
                                Button { stato.apriDocumentoBiblioteca(d.id, pagina: p.pagina) } label: {
                                    chip(testo: "\(d.genereVisto.nome) \(d.titoloBreve) · p. \(p.pagina)", glifo: true)
                                }
                                .buttonStyle(StileSemplice())
                            }
                        }
                    }
                }
                nota
            }
            .frame(width: B.larghezzaRisposta, alignment: .leading)
        } else {
            GeometryReader { g in
                // Il vassoio tiene almeno il foglio alla scala minima; la colonna della risposta cede fino al suo minimo
                let vassoioMinimo = B.larghezzaFoglio * B.scalaMinima + 2 * B.latiVassoio
                let colonna = min(B.larghezzaRisposta, g.size.width - B.spazioColonne - vassoioMinimo)
                if colonna >= B.rispostaMinima {
                    HStack(alignment: .top, spacing: B.spazioColonne) {
                        colonnaRisposta(r).frame(width: colonna)
                        vassoio(r)
                    }
                } else {
                    // Finestra stretta: la risposta sopra, il foglio sotto, e si scorre
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: B.spazioColonne) {
                            colonnaRisposta(r)
                            vassoio(r).frame(height: B.altezzaVassoioStretto)
                        }
                    }
                }
            }
        }
    }

    private func colonnaRisposta(_ r: RisultatoBiblioteca) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            tile(r)
            if let a = r.avviso {
                Label { Text(a) } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(C.arancio) }
                    .carattereApple(B.testoAvviso)
                    .foregroundColor(B.coloreTestoAvviso)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(B.paddingAvviso)
                    .background(RoundedRectangle(cornerRadius: B.raggioAvviso, style: .continuous).fill(B.fondoAvviso))
                    .padding(.top, B.sottoTile)
            }
            HStack(spacing: B.spazioPulsanti) {
                Button("Mostra al cliente") { stato.mostraBibliotecaAlCliente() }
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(r.passo == nil || r.stato == .cerca)
                Button("Copia la citazione") { stato.copiaCitazioneBiblioteca() }
                    .buttonStyle(.appleGrande)
                    .disabled(r.frase == nil)
            }
            .padding(.top, B.sottoTile)
            nota.padding(.top, B.sottoTile)
        }
    }

    private var nota: some View {
        Text("La risposta viene solo dal documento: se il testo non dice una cosa, Vera lo scrive.")
            .carattereApple(B.nota)
            .foregroundColor(B.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func tile(_ r: RisultatoBiblioteca) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SferaVera(misura: B.sferaRisposta, pensa: r.stato == .cerca)
                Text("Vera").carattereApple(B.nomeVera).foregroundColor(C.inchiostro)
                Spacer()
                Text("ho cercato in \(r.pagineCercate) \(r.pagineCercate == 1 ? "pagina" : "pagine")")
                    .carattereApple(B.notaCercate).foregroundColor(C.inchiostro2).monospacedDigit()
            }
            Group {
                switch r.stato {
                case .cerca:
                    PuntiniScrittura()
                case .risposta:
                    TestoProgressivo(testo: r.risposta ?? "")
                case .nonTrovata:
                    Text("Nei tuoi documenti non ho trovato una risposta a questa domanda.")
                case .nonVerificata(let motivo):
                    Text("\(motivo) Guarda il passo evidenziato sulla pagina.")
                case .senzaVera:
                    Text("Vera non è pronta: ti mostro la pagina più vicina alla domanda, senza risposta scritta.")
                }
            }
            .carattereApple(B.risposta)
            .foregroundColor(B.coloreRisposta)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: r.stato == .nonTrovata ? nil : B.minimoRisposta, alignment: .topLeading)
            if let p = r.passo, r.stato != .cerca, let d = stato.documentoBiblioteca(p.documentoId) {
                VStack(alignment: .leading, spacing: B.spazioChip) {
                    // Le due chip in riga; se non ci stanno intere, una sotto l'altra
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: B.spazioChip) { chipDocumento(d, p); chipPaginaPulsante(p) }
                        VStack(alignment: .leading, spacing: B.spazioChip) { chipDocumento(d, p); chipPaginaPulsante(p) }
                    }
                    if !d.edizione.isEmpty {
                        Text(d.edizione).carattereApple(B.notaCercate).foregroundColor(C.inchiostro2)
                    }
                    // §8.1.6 punto 3: lo stesso prodotto con un'altra edizione
                    if let altra = stato.avvisoEdizioneBiblioteca(d) {
                        Text(altra)
                            .carattereApple(B.notaCercate)
                            .foregroundColor(C.arancio)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, B.sopraChip - 10)
            }
        }
        .padding(B.paddingRisposta)
        .superficieApple(B.superficieRisposta)
    }

    private func chip(testo: String, glifo: Bool) -> some View {
        HStack(spacing: 6) {
            if glifo {
                GlifoLuceVista(glifo: .libro, lato: B.glifoChip * 0.8, colore: Tema.Apple.Colore.Glifi.libro)
                    .frame(width: B.glifoChip, height: B.glifoChip)
            }
            Text(testo).lineLimit(1)
        }
        .carattereApple(B.chip)
        .foregroundColor(C.inchiostro)
        .padding(B.paddingChip)
        .background(Capsule(style: .continuous).fill(B.fondoChip))
        .overlay(Capsule(style: .continuous).strokeBorder(B.bordoChip, lineWidth: Tema.Apple.Misura.bordo))
    }

    private func chipDocumento(_ d: DocumentoBiblioteca, _ p: PassoBiblioteca) -> some View {
        Button { stato.apriDocumentoBiblioteca(d.id, pagina: p.pagina) } label: { chip(testo: d.titoloBreve, glifo: true) }
            .buttonStyle(StileSemplice())
            .help("Apri il documento")
    }

    private func chipPaginaPulsante(_ p: PassoBiblioteca) -> some View {
        Button { stato.tornaAllaRisposta() } label: { chipPagina(p) }
            .buttonStyle(StileSemplice())
            .help("Riporta il foglio alla frase")
    }

    private func chipPagina(_ p: PassoBiblioteca) -> some View {
        Text("Pagina \(p.pagina)" + (p.intestazioneVista.isEmpty ? "" : " · \(p.intestazioneVista)"))
            .lineLimit(1)
            .carattereApple(B.chip)
            .foregroundColor(B.testoPagina)
            .padding(B.paddingChip)
            .background(Capsule(style: .continuous).fill(B.fondoPagina))
            .overlay(Capsule(style: .continuous).strokeBorder(B.bordoPagina, lineWidth: Tema.Apple.Misura.bordo))
    }

    @ViewBuilder private func vassoio(_ r: RisultatoBiblioteca) -> some View {
        if let p = r.passo, let d = stato.documentoBiblioteca(p.documentoId) {
            let pagine = trova.pagine(d)
            let testo = p.pagina - 1 < pagine.count ? pagine[p.pagina - 1] : ""
            VassoioBiblioteca(foglio: FoglioBiblioteca(documento: d, pagina: p.pagina, testo: testo, frase: r.frase,
                                                       passi: r.passiEvidenziati.map(\.testo), avanzamento: 1),
                              totale: max(pagine.count, d.numeroPagine), giro: trova.giro) { EmptyView() }
        }
    }

    /// Il documento intero nel vassoio, con le frecce delle pagine.
    private func documentoAperto(_ d: DocumentoBiblioteca, pagina: Int) -> some View {
        let pagine = trova.pagine(d)
        let totale = max(1, max(pagine.count, d.numeroPagine))
        let testo = pagina - 1 < pagine.count ? pagine[pagina - 1] : ""
        return VStack(alignment: .leading, spacing: B.sottoTile) {
            HStack(spacing: 10) {
                TasselloGlifo(glifo: .libro, lato: B.latoTassello, tinta: B.tassello(canale: d.canale))
                VStack(alignment: .leading, spacing: 1) {
                    Text(d.titolo).carattereApple(B.titoloDocumento).foregroundColor(B.coloreTitolo)
                    Text([d.dettaglio, d.edizione].filter { !$0.isEmpty }.joined(separator: " · "))
                        .carattereApple(B.dettaglioDocumento).foregroundColor(B.coloreDettaglio)
                }
                Spacer()
                if trova.risultato != nil {
                    Button("Torna alla risposta") { stato.tornaAllaRisposta() }.buttonStyle(.apple)
                }
            }
            VassoioBiblioteca(foglio: FoglioBiblioteca(documento: d, pagina: pagina, testo: testo, frase: nil, passi: [], avanzamento: 1),
                              totale: totale, giro: trova.giro) {
                Button { stato.apriDocumentoBiblioteca(d.id, pagina: pagina - 1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain).disabled(pagina <= 1)
                    .accessibilityLabel(Text("Pagina precedente"))
                Button { stato.apriDocumentoBiblioteca(d.id, pagina: pagina + 1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain).disabled(pagina >= totale)
                    .accessibilityLabel(Text("Pagina seguente"))
            }
        }
    }
}

/// La barra laterale della Biblioteca: i documenti, le letture in corso e la didascalia. Una vista a parte: durante
/// un'importazione ogni pagina letta ridisegna solo lei, non la domanda né il vassoio con il foglio.
private struct LateraleBiblioteca: View {
    @Environment(StatoShell.self) var stato
    let biblioteca: StatoBiblioteca
    let trova: StatoTrovaPagina
    /// Un rilascio di file sopra la Biblioteca (bordo e fondo del rilascio).
    let sopra: Bool
    @Binding var daTogliere: String?
    @Binding var daModificare: String?
    @Environment(\.modoIstantanea) private var istantanea

    private typealias B = Tema.Apple.Biblioteca

    private var documenti: [DocumentoBiblioteca] { biblioteca.tutti }

    /// Il documento acceso: quello della risposta o quello aperto.
    private var acceso: String? { trova.aperta?.documentoId ?? trova.risultato?.passo?.documentoId }

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("I documenti").carattereApple(B.etichetta).foregroundColor(B.coloreEtichetta)
                Spacer()
                Text("\(documenti.count)").carattereApple(B.etichetta).foregroundColor(B.coloreEtichetta).monospacedDigit()
                Button { stato.scegliDocumentiBiblioteca() } label: {
                    Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundColor(B.coloreEtichetta)
                .help("Aggiungi i PDF che usi")
            }
            ScrollView(.vertical, showsIndicators: false) {
                // Pigra: con molti documenti si costruiscono (menu compresi) solo le righe in vista; le righe vanno già
                // a tutta larghezza, la disposizione non cambia
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(trova.letture) { l in rigaLettura(l) }
                    ForEach(documenti) { d in rigaDocumento(d) }
                }
            }
            Spacer(minLength: 0)
            didascalia
        }
        .padding(B.paddingLaterale)
        .frame(maxHeight: .infinity, alignment: .top)
        .superficieApple(B.superficieLaterale, raggio: B.raggioLaterale)
        .overlay {
            RoundedRectangle(cornerRadius: B.raggioLaterale, style: .continuous)
                .strokeBorder(sopra ? B.bordoRilascio : .clear, lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: B.raggioLaterale, style: .continuous).fill(sopra ? B.fondoRilascio : .clear))
                .allowsHitTesting(false)
        }
    }

    private var didascalia: some View {
        let esempi = documenti.contains { $0.diProva == true }
        var testo = documenti.isEmpty && trova.letture.isEmpty
            ? "Trascina qui i PDF che usi: condizioni, KID, circolari, normativa."
            : "Trascina qui i PDF che usi. Vera li legge sul Mac e risponde citando documento e pagina."
        if esempi { testo += " Testi di esempio." }
        if trova.indice.esclusi > 0 {
            testo += " Indice parziale: \(trova.indice.documenti) di \(trova.indice.documenti + trova.indice.esclusi) documenti."
        }
        return Text(testo)
            .carattereApple(B.didascalia)
            .foregroundColor(B.coloreDidascalia)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func rigaDocumento(_ d: DocumentoBiblioteca) -> some View {
        Button { stato.apriDocumentoBiblioteca(d.id) } label: {
            HStack(alignment: .top, spacing: B.spazioVoce) {
                TasselloGlifo(glifo: .libro, lato: B.latoTassello, tinta: B.tassello(canale: d.canale))
                VStack(alignment: .leading, spacing: 2) {
                    Text(d.titolo)
                        .carattereApple(B.titoloDocumento)
                        .foregroundColor(B.coloreTitolo)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(d.illeggibile ? "illeggibile: non posso cercarci dentro" : d.dettaglio)
                        .carattereApple(B.dettaglioDocumento)
                        .foregroundColor(d.illeggibile || d.daConfermare ? B.coloreAvviso : B.coloreDettaglio)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
            .padding(B.paddingVoce)
            .background(RoundedRectangle(cornerRadius: B.raggioVoce, style: .continuous).fill(acceso == d.id ? B.fondoVoceAccesa : .clear))
            .contentShape(RoundedRectangle(cornerRadius: B.raggioVoce, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(istantanea ? nil : Tema.Apple.Moto.uscita(0.25), value: acceso)
        .contextMenu { menu(d) }
        .accessibilityHint(Text("Apre il documento"))
    }

    @ViewBuilder private func menu(_ d: DocumentoBiblioteca) -> some View {
        if d.daConfermare {
            Button("Conferma \(d.genereVisto.nome.lowercased()) e canale") { stato.classificaBiblioteca(d.id) }
        }
        Menu("Genere") {
            ForEach(GenereBiblioteca.allCases) { g in
                Button { stato.classificaBiblioteca(d.id, genere: g) } label: {
                    if d.genereVisto == g { Label(g.nome, systemImage: "checkmark") } else { Text(g.nome) }
                }
            }
        }
        Menu("Canale") {
            Button { stato.classificaBiblioteca(d.id, canale: .some(.alleanza)) } label: { marcato("Alleanza", d.canale == .alleanza) }
            Button { stato.classificaBiblioteca(d.id, canale: .some(.indipendente)) } label: { marcato("Consulenza indipendente", d.canale == .indipendente) }
            Button { stato.classificaBiblioteca(d.id, canale: .some(nil)) } label: { marcato("Nessuno (di riferimento)", d.canale == nil) }
        }
        Menu("Collega a un prodotto") {
            Button { stato.collegaProdottoBiblioteca(d.id, prodotto: nil) } label: { marcato("Nessun prodotto", d.prodottoId == nil) }
            ForEach(stato.dati.prodotti) { p in
                Button { stato.collegaProdottoBiblioteca(d.id, prodotto: p.id) } label: { marcato(p.nome, d.prodottoId == p.id) }
            }
        }
        Button("Titolo ed edizione…") { daModificare = d.id }
        Button("Mostra nel Finder") { stato.mostraNelFinderBiblioteca(d.id) }
        Divider()
        Button("Togli dalla Biblioteca…", role: .destructive) { daTogliere = d.id }
    }

    @ViewBuilder private func marcato(_ testo: String, _ si: Bool) -> some View {
        if si { Label(testo, systemImage: "checkmark") } else { Text(testo) }
    }

    private func rigaLettura(_ l: LetturaBiblioteca) -> some View {
        HStack(alignment: .top, spacing: B.spazioVoce) {
            ZStack {
                TasselloGlifo(glifo: .libro, lato: B.latoTassello, tinta: Tema.Apple.Colore.Glifi.libro)
                    .opacity(0.45)
                Circle().stroke(Color.white.opacity(0.35), lineWidth: B.spessoreAnello)
                    .frame(width: B.anelloLettura, height: B.anelloLettura)
                Circle().trim(from: 0, to: CGFloat(l.lette) / CGFloat(max(1, l.totale)))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: B.spessoreAnello, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: B.anelloLettura, height: B.anelloLettura)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(l.nome).carattereApple(B.titoloDocumento).foregroundColor(B.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Leggo… \(l.lette) di \(l.totale) \(l.totale == 1 ? "pagina" : "pagine")")
                    .carattereApple(B.dettaglioDocumento).foregroundColor(B.coloreDettaglio).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(B.paddingVoce)
        .accessibilityElement(children: .combine)
    }
}

/// La barra della domanda: la sola vista che legge la domanda, così un tasto nel campo ridisegna solo lei.
private struct BarraDomandaBiblioteca: View {
    @Environment(StatoShell.self) var stato
    @Bindable var trova: StatoTrovaPagina
    let senzaDocumenti: Bool
    @FocusState private var campo: Bool

    private typealias B = Tema.Apple.Biblioteca
    private typealias C = Tema.Apple.Colore

    private var cercaInCorso: Bool { trova.risultato?.stato == .cerca }

    var body: some View {
        let vuota = trova.domanda.trimmingCharacters(in: .whitespaces).isEmpty
        HStack(spacing: B.spazioSfera) {
            SferaVera(misura: B.sferaDomanda, pensa: cercaInCorso)
            TextField("Chiedi qualcosa ai tuoi documenti…", text: $trova.domanda)
                .textFieldStyle(.plain)
                .carattereApple(B.campoDomanda)
                .foregroundColor(C.inchiostro)
                .focused($campo)
                .onSubmit { stato.chiediBiblioteca(trova.domanda) }
            Button("Cerca") { stato.chiediBiblioteca(trova.domanda) }
                .buttonStyle(.applePrimario)
                .disabled(vuota || senzaDocumenti)
            // ⌘F porta nel campo della domanda
            Button("") { campo = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .padding(B.paddingDomanda)
        .frame(height: B.altezzaDomanda)
        .background {
            Capsule(style: .continuous).fill(B.fondoDomanda).ombraApple(B.ombraDomanda)
        }
        .overlay {
            Capsule(style: .continuous).strokeBorder(B.bordoDomanda, lineWidth: Tema.Apple.Misura.bordo).allowsHitTesting(false)
        }
    }
}

/// Titolo ed edizione di un documento (ogni citazione porta l'edizione).
private struct ModuloDocumentoBiblioteca: View {
    let documento: DocumentoBiblioteca
    let salva: (String, String) -> Void
    let annulla: () -> Void
    @State private var titolo = ""
    @State private var edizione = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Titolo ed edizione").carattereApple(Tema.Apple.Carattere.titoloGruppo)
            TextField("Titolo (es. Piano rivalutabile · Condizioni di assicurazione)", text: $titolo).textFieldStyle(.roundedBorder)
            TextField("Edizione (es. ed. 03/2026)", text: $edizione).textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Annulla", action: annulla).keyboardShortcut(.cancelAction)
                Button("Salva") { salva(titolo, edizione) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(titolo.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            titolo = documento.titolo
            edizione = documento.edizione
        }
    }
}
#endif
