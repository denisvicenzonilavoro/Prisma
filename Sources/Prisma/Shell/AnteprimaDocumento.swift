#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import PDFKit
import SwiftUI

/// L'anteprima di un documento: il foglio è il protagonista, a tutta altezza e con lo zoom adatto alla larghezza;
/// in basso galleggia la barra delle pagine (sfoglia, zoom − + e «adatta», apri fuori da Prisma).
/// Tre casi: il PDF vero (`VistaPDF`, un solo `PDFDocument` aperto alla volta), l'immagine ridotta con ImageIO, oppure
/// (senza file o nelle istantanee) la pagina ricostruita dal testo letto. Il foglio è carta: bianco anche in scuro.
struct AnteprimaDocumento: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var modoIstantanea
    let documento: Documento

    /// Lo zoom rispetto alla larghezza: 1 = il foglio largo quanto l'anteprima. Torna a 1 a ogni documento.
    @State private var zoom: CGFloat = 1

    private enum Foglio { case pdf(URL), immagine(URL), testo }

    /// Il file del documento, se c'è sul Mac.
    private var file: URL? {
        guard let url = stato.urlDocumento(documento), FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    var body: some View {
        let url = file
        let foglio: Foglio = {
            guard !modoIstantanea, let url else { return .testo }
            return url.pathExtension.lowercased() == "pdf" ? .pdf(url) : .immagine(url)
        }()
        let pagine = stato.testoDocumento(documento)
        let totale: Int = {
            switch foglio {
            case .pdf: return max(documento.pagine, pagine.count, 1)
            case .immagine: return 1
            case .testo: return max(pagine.count, 1)
            }
        }()
        let pagina = min(max(stato.vistaDocumenti.pagina, 1), totale)
        contenuto(foglio, pagine: pagine, pagina: pagina)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(colors: [Tema.Colore.Strumenti.tavoloAlto, Tema.Colore.Strumenti.tavoloBasso],
                                       startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .bottom) {
                BarraPagineDocumento(documento: documento, pagina: pagina, totale: totale, url: url, zoom: $zoom)
                    .padding(.bottom, Tema.Misura.Documenti.margineBarraPagine)
            }
            .onChange(of: documento.id) { _ in zoom = 1 }
    }

    @ViewBuilder private func contenuto(_ foglio: Foglio, pagine: [String], pagina: Int) -> some View {
        let m = Tema.Misura.Documenti.self
        switch foglio {
        case .pdf(let u):
            VistaPDF(url: u,
                     pagina: Binding(get: { stato.vistaDocumenti.pagina }, set: { stato.vistaDocumenti.pagina = $0 }),
                     evidenzia: estrattoEvidenziato(pagina: nil),
                     zoom: zoom)
        case .immagine(let u):
            GeometryReader { geo in
                ScrollView(Self.assi(zoom)) {
                    ImmagineDocumento(url: u)
                        .frame(width: max((geo.size.width - 2 * m.margineTavolo) * zoom, m.margineTavolo))
                        .padding(m.margineTavolo)
                        .padding(.bottom, m.spazioSottoFoglio)
                        .frame(minWidth: geo.size.width)
                }
            }
        case .testo:
            FoglioRicostruito(testo: pagina <= pagine.count ? pagine[pagina - 1] : "",
                              estratto: estrattoEvidenziato(pagina: pagina),
                              nota: notaFoglio(vuoto: pagine.isEmpty),
                              pagina: pagina,
                              zoom: zoom)
        }
    }

    /// Ingrandito, il foglio scorre anche di lato.
    static func assi(_ zoom: CGFloat) -> Axis.Set {
        zoom > 1 ? [.vertical, .horizontal] : .vertical
    }

    /// La riga del documento da cui viene il dato da evidenziare (sulla pagina mostrata, per il foglio ricostruito).
    private func estrattoEvidenziato(pagina: Int?) -> String? {
        guard let chiave = stato.vistaDocumenti.evidenzia, let c = documento.campo(chiave), !c.estratto.isEmpty else { return nil }
        if let pagina, c.pagina != pagina { return nil }
        return c.estratto
    }

    private func notaFoglio(vuoto: Bool) -> String {
        #if os(macOS)
        if stato.documentiInLettura.contains(documento.id) { return "Prisma sta leggendo il testo sul Mac…" }
        #elseif os(iOS)
        if stato.documentiInLettura.contains(documento.id) { return "Prisma sta leggendo il testo…" }
        #endif
        if vuoto { return "Il testo di questo documento non è ancora disponibile." }
        return documento.file == nil ? "Documento di prova: pagina ricostruita dal testo" : "Pagina ricostruita dal testo letto"
    }
}

/// Il foglio ricostruito dal testo, largo quanto l'anteprima (per lo zoom): la riga del dato scelto evidenziata e
/// portata al centro.
private struct FoglioRicostruito: View {
    let testo: String
    let estratto: String?
    let nota: String
    let pagina: Int
    let zoom: CGFloat

    var body: some View {
        let m = Tema.Misura.Documenti.self
        GeometryReader { geo in
            let adatta: CGFloat = min(max(geo.size.width - 2 * m.margineTavolo, m.margineTavolo), m.foglioMassimo)
            let larghezza: CGFloat = adatta * zoom
            let scala: CGFloat = max(min(larghezza / m.foglioRiferimento, m.scalaFoglioMassima * zoom), m.scalaFoglioMinima * zoom)
            ScrollViewReader { lettore in
                ScrollView(AnteprimaDocumento.assi(zoom)) {
                    PaginaTestoDocumento(testo: testo, estratto: estratto, nota: nota, larghezza: larghezza, scala: scala)
                        .padding(m.margineTavolo)
                        .padding(.bottom, m.spazioSottoFoglio)
                        .frame(minWidth: geo.size.width)
                }
                .onAppear { vaiAllaRiga(lettore) }
                .onChange(of: estratto ?? "") { _ in vaiAllaRiga(lettore) }
                .onChange(of: pagina) { _ in vaiAllaRiga(lettore) }
            }
        }
    }

    /// Porta al centro la riga evidenziata (dopo che il foglio è disposto).
    private func vaiAllaRiga(_ lettore: ScrollViewProxy) {
        let righe = testo.components(separatedBy: "\n")
        guard let i = righe.firstIndex(where: { PaginaTestoDocumento.evidenziata($0, estratto: estratto) }) else { return }
        DispatchQueue.main.async {
            withAnimation(Tema.Moto.pannello) { lettore.scrollTo(PaginaTestoDocumento.idRiga(i), anchor: .center) }
        }
    }
}

/// La barra delle pagine che galleggia sul foglio: ‹ Pagina 2 di 3 ›, zoom − + e «adatta alla larghezza», e il
/// file fuori da Prisma (Anteprima sul Mac, Condividi su iPhone e iPad).
private struct BarraPagineDocumento: View {
    @Environment(StatoShell.self) var stato
    let documento: Documento
    let pagina: Int
    let totale: Int
    let url: URL?
    @Binding var zoom: CGFloat

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        HStack(spacing: m.spazioPagine) {
            PulsanteIcona(simbolo: "chevron.left", aiuto: "Pagina precedente", taglia: .compatta, vetro: false) {
                stato.vistaDocumenti.pagina = pagina - 1
            }
            .disabled(pagina <= 1)
            Text("\(pagina) di \(totale)")
                .font(Tema.Testo.didascalia)
                .monospacedDigit()
                .foregroundColor(Tema.Colore.inchiostro)
                .lineLimit(1)
                .fixedSize()
                .accessibilityLabel("Pagina \(pagina) di \(totale)")
            PulsanteIcona(simbolo: "chevron.right", aiuto: "Pagina successiva", taglia: .compatta, vetro: false) {
                stato.vistaDocumenti.pagina = pagina + 1
            }
            .disabled(pagina >= totale)
            filo
            PulsanteIcona(simbolo: "minus.magnifyingglass", aiuto: "Rimpicciolisci", taglia: .compatta, vetro: false) {
                zoom = max(zoom - m.passoZoom, m.zoomMinimo)
            }
            .disabled(zoom <= m.zoomMinimo)
            PulsanteIcona(simbolo: "arrow.left.and.right", aiuto: "Adatta alla larghezza", taglia: .compatta, vetro: false) {
                zoom = 1
            }
            .disabled(zoom == 1)
            PulsanteIcona(simbolo: "plus.magnifyingglass", aiuto: "Ingrandisci", taglia: .compatta, vetro: false) {
                zoom = min(zoom + m.passoZoom, m.zoomMassimo)
            }
            .disabled(zoom >= m.zoomMassimo)
            if let url {
                filo
                fuori(url)
            }
        }
        .padding(.horizontal, m.marginePagine)
        .frame(height: m.barraPagine)
        // Il vetro del tema Apple in capsula (galleggia sopra il foglio, mai sul foglio)
        .background {
            GeometryReader { g in
                Color.clear.superficieApple(Tema.Apple.Superficie.vetro, raggio: g.size.height / 2)
            }
        }
        .fixedSize()
    }

    private var filo: some View {
        Rectangle()
            .fill(Colori.ColonneStrumento.divisore)
            .frame(width: Misure.ColonneStrumento.filo, height: Tema.Misura.Documenti.filoBarraPagine)
    }

    @ViewBuilder private func fuori(_ url: URL) -> some View {
        #if os(macOS)
        PulsanteIcona(simbolo: "arrow.up.forward.square", aiuto: "Apri in Anteprima", taglia: .compatta, vetro: false) {
            ApriFile.apri(url)
        }
        #elseif os(iOS)
        // Su iPhone e iPad l'Anteprima del Mac non c'è: il file si manda (AirDrop, Mail) o si salva in File
        PulsanteIcona(simbolo: "square.and.arrow.up", aiuto: "Condividi", taglia: .compatta, vetro: false) {
            StampaCarta.condividi(url, nome: documento.titolo)
        }
        #endif
    }
}

/// Un'immagine (foto o scansione) ridotta con ImageIO, letta una volta per file.
private struct ImmagineDocumento: View {
    let url: URL
    @State private var immagine: ImmaginePiattaforma?

    var body: some View {
        Group {
            if let immagine {
                Image(piattaforma: immagine)
                    .resizable()
                    .scaledToFit()
                    .ombraTema(Tema.Ombra.Strumenti.foglio)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) { immagine = LetturaDocumenti.anteprima(url) }
    }
}

/// La pagina ricostruita dal testo letto: foglio bianco in proporzione A4, il testo riga per riga e la riga da cui
/// viene il dato scelto evidenziata. Colori fissi: è carta anche in aspetto scuro.
struct PaginaTestoDocumento: View {
    let testo: String
    /// La riga del documento da evidenziare (`CampoEstratto.estratto`).
    let estratto: String?
    let nota: String
    let larghezza: CGFloat
    /// Lo zoom del foglio: testo e margini crescono con la larghezza (1 = misure del tema).
    var scala: CGFloat = 1

    /// L'identità di una riga, per portarla al centro (`ScrollViewReader`).
    static func idRiga(_ i: Int) -> String { "riga-foglio-\(i)" }

    var body: some View {
        let m = Tema.Misura.Documenti.self
        let righe = testo.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: m.spazioRigheFoglio * scala) {
            Text(nota)
                .font(Tema.Testo.Documenti.notaFoglioScala(scala))
                .foregroundColor(Tema.Colore.Documenti.notaFoglio)
                .padding(.bottom, m.spazioNotaFoglio * scala)
            ForEach(Array(righe.enumerated()), id: \.offset) { i, riga in
                rigaFoglio(riga)
                    .id(Self.idRiga(i))
            }
        }
        .padding(scalati(m.margineFoglio))
        .frame(width: larghezza, alignment: .topLeading)
        .frame(minHeight: larghezza / m.rapportoA4, alignment: .top)
        .background { FormaVetro.arrotondata(Tema.Raggio.Documenti.foglio).fill(Tema.Colore.Documenti.foglio) }
        .ombraTema(Tema.Ombra.Strumenti.foglio)
        .environment(\.colorScheme, .light)
    }

    private func rigaFoglio(_ riga: String) -> some View {
        Text(riga.isEmpty ? " " : riga)
            .font(Tema.Testo.Documenti.testoFoglioScala(scala))
            .foregroundColor(Tema.Colore.Documenti.testoFoglio)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Tema.Misura.Documenti.margineRigaFoglio * scala)
            .background {
                if Self.evidenziata(riga, estratto: estratto) {
                    FormaVetro.arrotondata(Tema.Raggio.Documenti.evidenza).fill(Tema.Colore.Documenti.evidenziaFoglio)
                }
            }
    }

    private func scalati(_ e: EdgeInsets) -> EdgeInsets {
        EdgeInsets(top: e.top * scala, leading: e.leading * scala, bottom: e.bottom * scala, trailing: e.trailing * scala)
    }

    /// Una riga viene dall'estratto se, tolti gli spazi ai lati, ha almeno 6 caratteri ed è contenuta nell'estratto,
    /// oppure se contiene i primi 30 caratteri dell'estratto.
    static func evidenziata(_ riga: String, estratto: String?) -> Bool {
        guard let estratto else { return false }
        let e = estratto.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = riga.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.isEmpty, !r.isEmpty else { return false }
        if r.count >= 6, e.contains(r) { return true }
        return r.contains(String(e.prefix(30)))
    }
}

/// Il PDF vero, in PDFKit: pagine una sotto l'altra sul tavolo, salto alla pagina scelta e la riga del dato
/// evidenziata (se il testo si trova: le pagine da scansione non hanno testo da cercare, e allora basta la pagina).
/// La stessa PDFView di PDFKit sul Mac (NSViewRepresentable) e su iPhone e iPad (UIViewRepresentable), sotto;
/// `@MainActor` come lo rende la conformità (che qui sta nelle estensioni).
@MainActor
struct VistaPDF {
    let url: URL
    @Binding var pagina: Int
    /// La riga del documento da evidenziare (`CampoEstratto.estratto`).
    let evidenzia: String?
    /// Lo zoom rispetto alla larghezza: 1 = le pagine si adattano da sole alla vista.
    var zoom: CGFloat = 1

    final class Coordinatore: NSObject {
        var url: URL?
        var pagina: Binding<Int>
        var ultimaPagina = 0
        var ultimaEvidenza: String?
        var ultimoZoom: CGFloat = 1
        /// Mentre Prisma sposta la vista, i cambi di pagina non tornano allo stato.
        var muove = false
        weak var vista: PDFView?

        init(pagina: Binding<Int>) {
            self.pagina = pagina
        }

        @objc func paginaCambiata(_ notifica: Notification) {
            guard !muove, let v = vista, let p = v.currentPage, let doc = v.document else { return }
            let n = doc.index(for: p) + 1
            guard n != ultimaPagina else { return }
            ultimaPagina = n
            let legame = pagina
            // Fuori dall'aggiornamento della vista
            DispatchQueue.main.async {
                if legame.wrappedValue != n { legame.wrappedValue = n }
            }
        }

        func mostra(_ pagina: Int, evidenzia: String?, in v: PDFView) {
            guard let doc = v.document, doc.pageCount > 0 else { return }
            let indice = min(max(pagina - 1, 0), doc.pageCount - 1)
            guard let pg = doc.page(at: indice) else { return }
            muove = true
            v.highlightedSelections = nil
            var trovata: PDFSelection?
            if let e = evidenzia?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty {
                trovata = doc.findString(String(e.prefix(40)), withOptions: .caseInsensitive).first { $0.pages.contains(pg) }
            }
            if let s = trovata {
                s.color = ColorePiattaforma(Tema.Colore.Documenti.evidenziaPDF)
                v.highlightedSelections = [s]
                v.go(to: s)
            } else {
                v.go(to: pg)
            }
            DispatchQueue.main.async { self.muove = false }
        }
    }

    func makeCoordinator() -> Coordinatore { Coordinatore(pagina: $pagina) }

    fileprivate func crea(_ coordinatore: Coordinatore) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displaysPageBreaks = true
        // Si vede il tavolo dell'app attorno ai fogli
        v.backgroundColor = .clear
        coordinatore.vista = v
        NotificationCenter.default.addObserver(coordinatore, selector: #selector(Coordinatore.paginaCambiata(_:)),
                                               name: .PDFViewPageChanged, object: v)
        return v
    }

    fileprivate func aggiorna(_ v: PDFView, _ c: Coordinatore) {
        c.pagina = $pagina
        // Il documento si apre solo quando cambia il file: uno alla volta
        if c.url != url {
            c.url = url
            c.muove = true
            v.document = PDFDocument(url: url)
            c.ultimaPagina = 0
            c.ultimaEvidenza = nil
        }
        if c.ultimaPagina != pagina || c.ultimaEvidenza != evidenzia {
            c.ultimaPagina = pagina
            c.ultimaEvidenza = evidenzia
            c.mostra(pagina, evidenzia: evidenzia, in: v)
        } else if c.muove {
            DispatchQueue.main.async { c.muove = false }
        }
        if c.ultimoZoom != zoom {
            c.ultimoZoom = zoom
            if zoom == 1 {
                v.autoScales = true
            } else {
                v.autoScales = false
                v.scaleFactor = v.scaleFactorForSizeToFit * zoom
            }
        }
    }

    fileprivate static func smonta(_ v: PDFView, _ coordinator: Coordinatore) {
        NotificationCenter.default.removeObserver(coordinator)
        v.document = nil
    }
}

#if os(macOS)
extension VistaPDF: NSViewRepresentable {
    func makeNSView(context: Context) -> PDFView { crea(context.coordinator) }
    func updateNSView(_ v: PDFView, context: Context) { aggiorna(v, context.coordinator) }
    static func dismantleNSView(_ v: PDFView, coordinator: Coordinatore) { smonta(v, coordinator) }
}
#elseif os(iOS)
extension VistaPDF: UIViewRepresentable {
    func makeUIView(context: Context) -> PDFView { crea(context.coordinator) }
    func updateUIView(_ v: PDFView, context: Context) { aggiorna(v, context.coordinator) }
    static func dismantleUIView(_ v: PDFView, coordinator: Coordinatore) { smonta(v, coordinator) }
}
#endif
