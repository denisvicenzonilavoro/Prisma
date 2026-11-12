#if os(macOS)
import AppKit
#endif
import PDFKit
import SwiftUI

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.1.4, §8.1.3, §8.1.5.2 punto 4): il foglio della
// pagina con l'evidenziatore che si stende riga per riga, il contatore che scorre e il vassoio che lo porta.
// - I PDF con testo si disegnano come immagine della pagina (una alla volta, `PDFPage.thumbnail`) e sopra i rettangoli
//   delle righe della frase (`selectionsByLine`), in SwiftUI.
// - Le pagine senza PDF (fac-simile, scansioni, testi di prima) si ricompongono dal testo: intestazione, titolo
//   dell'articolo e paragrafi; il paragrafo con la frase ha l'evidenziatore sulla frase.
// Il foglio è carta bianca in chiaro e in scuro. Con «Riduci movimento» e nelle istantanee tutto è già fermo.

// MARK: - Le righe dell'evidenziatore

/// Righe che si stendono da sinistra a destra, una dopo l'altra (la durata divisa per le righe).
struct RigheEvidenziatore: Shape {
    /// Le righe (0…1 della superficie, origine in alto). Vuoto = righe piene alte `altezzaRiga`.
    var righe: [CGRect] = []
    var altezzaRiga: CGFloat = Tema.Apple.Biblioteca.rigaParagrafo
    var avanzamento: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let elenco: [CGRect]
        if righe.isEmpty {
            let n = max(1, Int((rect.height / altezzaRiga).rounded()))
            elenco = (0..<n).map { CGRect(x: 0, y: CGFloat($0) / CGFloat(n), width: 1, height: 1 / CGFloat(n)) }
        } else {
            elenco = righe
        }
        var p = Path()
        let n = Double(elenco.count)
        for (i, r) in elenco.enumerated() {
            let locale = min(1, max(0, avanzamento * n - Double(i)))
            guard locale > 0 else { continue }
            let pieno = CGRect(x: rect.minX + r.minX * rect.width, y: rect.minY + r.minY * rect.height,
                               width: r.width * rect.width * locale, height: r.height * rect.height)
            p.addRoundedRect(in: pieno, cornerSize: CGSize(width: Tema.Apple.Biblioteca.raggioEvidenzia, height: Tema.Apple.Biblioteca.raggioEvidenzia))
        }
        return p
    }
}

// MARK: - Il foglio

/// La pagina di un documento della Biblioteca su carta bianca, 600 di larghezza.
struct FoglioBiblioteca: View {
    let documento: DocumentoBiblioteca
    let pagina: Int
    let testo: String
    /// La frase della risposta (evidenziata esatta).
    var frase: String?
    /// I passi da evidenziare quando non c'è una frase (Vera non pronta, risposta non verificata).
    var passi: [String] = []
    var avanzamento: Double

    private typealias B = Tema.Apple.Biblioteca

    var body: some View {
        Group {
            #if os(macOS)
            if documento.ePDF, let immagine = PagineBiblioteca.immagine(documento, pagina: pagina) {
                paginaPDF(immagine)
            } else {
                paginaTesto
            }
            #else
            paginaTesto
            #endif
        }
        .environment(\.colorScheme, .light)
    }

    #if os(macOS)
    private func paginaPDF(_ immagine: NSImage) -> some View {
        let altezza = B.larghezzaFoglio * immagine.size.height / max(1, immagine.size.width)
        let righe = PagineBiblioteca.righe(documento, pagina: pagina, frasi: frase.map { [$0] } ?? passi)
        return Image(nsImage: immagine)
            .resizable()
            .interpolation(.high)
            .frame(width: B.larghezzaFoglio, height: altezza)
            .overlay {
                RigheEvidenziatore(righe: righe, avanzamento: avanzamento)
                    .fill(frase == nil ? B.evidenziaPasso : B.evidenzia)
                    .blendMode(.multiply)
            }
            .superficieApple(Tema.Apple.Superficie.carta)
    }
    #endif

    /// Un blocco della pagina ricomposta.
    private struct Blocco: Identifiable {
        let id: Int
        let testo: String
        let titolo: Bool
    }

    private var blocchi: [Blocco] {
        var r: [Blocco] = []
        for (testo, _) in MotoreBiblioteca.paragrafi(testo) {
            var corpo: [String] = []
            func chiudi() {
                let unito = corpo.joined(separator: " ").replacingOccurrences(of: "- ", with: "-")
                if !unito.trimmingCharacters(in: .whitespaces).isEmpty { r.append(Blocco(id: r.count, testo: unito, titolo: false)) }
                corpo = []
            }
            for riga in testo.components(separatedBy: "\n") {
                if MotoreBiblioteca.eIntestazione(riga) {
                    chiudi()
                    r.append(Blocco(id: r.count, testo: riga.trimmingCharacters(in: .whitespaces), titolo: true))
                } else {
                    corpo.append(riga.trimmingCharacters(in: .whitespaces))
                }
            }
            chiudi()
        }
        return r
    }

    private func evidenziato(_ b: Blocco) -> Bool {
        guard !b.titolo else { return false }
        if let frase { return MotoreBiblioteca.intervallo(frase, in: b.testo) != nil }
        return passi.contains { p in MotoreBiblioteca.intervallo(String(p.prefix(80)), in: b.testo) != nil }
    }

    private var paginaTesto: some View {
        let tutti = blocchi
        // Il paragrafo evidenziato resta sul foglio: se è in fondo, la parte sopra si riassume con «[…]»
        let primo = tutti.firstIndex(where: evidenziato) ?? 0
        let taglio = primo > 4 ? primo - 1 : 0
        let visibili = taglio > 0 ? Array(tutti[taglio...]) : tutti
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(documento.titolo + (documento.diProva == true ? " · fac-simile" : ""))
                    .lineLimit(1)
                Spacer(minLength: 12)
                Text("pagina \(pagina)")
            }
            .carattereApple(B.intestazioneFoglio)
            .foregroundColor(B.coloreIntestazione)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(B.filettoFoglio).frame(height: 1) }
            .padding(.bottom, B.sottoIntestazione)
            VStack(alignment: .leading, spacing: B.spazioParagrafi) {
                if taglio > 0 {
                    Text("[…]").carattereApple(B.omesso).foregroundColor(B.coloreIntestazione)
                }
                ForEach(visibili) { b in
                    if b.titolo {
                        Text(b.testo.replacingOccurrences(of: " – ", with: " · "))
                            .carattereApple(B.titoloArticolo)
                            .foregroundColor(B.coloreTitoloArticolo)
                    } else {
                        paragrafo(b)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(B.paddingFoglio)
        .frame(width: B.larghezzaFoglio, height: B.altezzaFoglio, alignment: .topLeading)
        .clipped()
        .superficieApple(Tema.Apple.Superficie.carta)
    }

    /// Un paragrafo: sotto il testo, sopra lo stesso testo trasparente con il fondo giallo sulla frase, mascherato
    /// dalle righe che si stendono.
    @ViewBuilder private func paragrafo(_ b: Blocco) -> some View {
        let base = Text(b.testo)
            .carattereApple(B.paragrafo)
            .foregroundColor(B.coloreParagrafo)
            .fixedSize(horizontal: false, vertical: true)
        if evidenziato(b) {
            base.overlay(alignment: .topLeading) {
                Text(evidenziatura(b.testo))
                    .carattereApple(B.paragrafo)
                    .fixedSize(horizontal: false, vertical: true)
                    .mask(RigheEvidenziatore(avanzamento: avanzamento))
                    .accessibilityHidden(true)
            }
        } else {
            base
        }
    }

    /// Il testo con la frase (o tutto il paragrafo del passo) sul fondo giallo; il resto trasparente.
    private func evidenziatura(_ testo: String) -> AttributedString {
        var a = AttributedString(testo)
        a.foregroundColor = .clear
        let intervallo: Range<String.Index>? = frase.flatMap { MotoreBiblioteca.intervallo($0, in: testo) } ?? (testo.startIndex..<testo.endIndex)
        if let r = intervallo, let da = AttributedString.Index(r.lowerBound, within: a), let a2 = AttributedString.Index(r.upperBound, within: a) {
            a[da..<a2].backgroundColor = frase == nil ? B.evidenziaPasso : B.evidenzia
            a[da..<a2].foregroundColor = B.testoEvidenziato
        }
        return a
    }
}

// MARK: - Le pagine dei PDF

#if os(macOS)
/// Le righe di una pagina già calcolate (l'oggetto della cache: NSCache vuole una classe).
private final class RighePaginaPDF {
    let righe: [CGRect]
    init(_ righe: [CGRect]) { self.righe = righe }
}

/// Le immagini delle pagine dei PDF (una alla volta, poche in memoria) e le righe della frase sulla pagina.
enum PagineBiblioteca {
    private static let immagini: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 6
        return c
    }()

    /// Gli ultimi PDF aperti (al più due): il foglio si ridisegna più volte per pagina (il giro, l'evidenziatore che
    /// riparte, la frase di Vera) e riaprire il file vorrebbe dire rileggerlo e analizzarlo dal disco ogni volta.
    private static let documenti: NSCache<NSString, PDFDocument> = {
        let c = NSCache<NSString, PDFDocument>()
        c.countLimit = 2
        return c
    }()

    /// Le righe delle frasi per documento, pagina e frasi: con la cache piena il ridisegno non rifà `selection(for:)`.
    private static let righeFatte: NSCache<NSString, RighePaginaPDF> = {
        let c = NSCache<NSString, RighePaginaPDF>()
        c.countLimit = 12
        return c
    }()

    private static func pagina(_ d: DocumentoBiblioteca, _ n: Int) -> PDFPage? {
        let url = StatoTrovaPagina.cartella.appendingPathComponent(d.file)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let chiave = url.path as NSString
        let pdf: PDFDocument
        if let aperto = documenti.object(forKey: chiave) {
            pdf = aperto
        } else {
            guard let nuovo = PDFDocument(url: url) else { return nil }
            documenti.setObject(nuovo, forKey: chiave)
            pdf = nuovo
        }
        guard n >= 1, n <= pdf.pageCount else { return nil }
        return pdf.page(at: n - 1)
    }

    /// L'immagine della pagina (circa 4 MB); nil se il PDF non c'è o la pagina è una scansione (si ricompone dal testo).
    static func immagine(_ d: DocumentoBiblioteca, pagina n: Int) -> NSImage? {
        let chiave = "\(d.id)#\(n)" as NSString
        if let i = immagini.object(forKey: chiave) { return i }
        guard let p = pagina(d, n), (p.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).count >= LetturaDocumenti.sogliaTesto else { return nil }
        let b = p.bounds(for: .mediaBox)
        let scala = Tema.Apple.Biblioteca.larghezzaFoglio * 2 / max(1, b.width)
        let misura = NSSize(width: b.width * scala, height: b.height * scala)
        let i = MetalPrisma.spento ? (disegnoSenzaGPU(p, misura: misura) ?? p.thumbnail(of: misura, for: .mediaBox))
                                   : p.thumbnail(of: misura, for: .mediaBox)
        immagini.setObject(i, forKey: chiave)
        return i
    }

    /// La pagina disegnata da CoreGraphics in una bitmap, senza GPU: solo con `PRISMA_SENZA_METAL=1` (le prove sul
    /// runner di GitHub, dove `thumbnail` può passare da Metal sulla GPU virtuale e fermare il processo).
    private static func disegnoSenzaGPU(_ p: PDFPage, misura: NSSize) -> NSImage? {
        let w = Int(misura.width.rounded()), h = Int(misura.height.rounded())
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        let b = p.bounds(for: .mediaBox)
        ctx.scaleBy(x: CGFloat(w) / max(1, b.width), y: CGFloat(h) / max(1, b.height))
        ctx.translateBy(x: -b.minX, y: -b.minY)
        p.draw(with: .mediaBox, to: ctx)
        guard let cg = ctx.makeImage() else { return nil }
        return NSImage(cgImage: cg, size: misura)
    }

    /// Le righe delle frasi sulla pagina (0…1, origine in alto): `selection(for:)` e `selectionsByLine()`.
    static func righe(_ d: DocumentoBiblioteca, pagina n: Int, frasi: [String]) -> [CGRect] {
        guard !frasi.isEmpty else { return [] }
        // Contano solo i primi 400 caratteri di ogni frase (quelli cercati sulla pagina): la chiave tiene solo quelli
        let cercate = frasi.map { String($0.prefix(400)) }
        let chiave = "\(d.id)#\(n)#\(cercate.joined(separator: "\u{1}"))" as NSString
        if let fatte = righeFatte.object(forKey: chiave) { return fatte.righe }
        guard let p = pagina(d, n), let s = p.string else { return [] }
        let b = p.bounds(for: .mediaBox)
        var r: [CGRect] = []
        for f in cercate {
            guard let intervallo = MotoreBiblioteca.intervallo(f, in: s),
                  let sel = p.selection(for: NSRange(intervallo, in: s)) else { continue }
            for riga in sel.selectionsByLine() {
                let x = riga.bounds(for: p)
                r.append(CGRect(x: (x.minX - b.minX) / b.width, y: 1 - (x.maxY - b.minY) / b.height,
                                width: x.width / b.width, height: x.height / b.height))
            }
        }
        righeFatte.setObject(RighePaginaPDF(r), forKey: chiave)
        return r
    }

    /// Alla chiusura della Biblioteca: i PDF aperti e le righe non servono più (il Mac ha poca memoria).
    static func libera() {
        documenti.removeAllObjects()
        righeFatte.removeAllObjects()
    }
}
#endif

// MARK: - Il contatore e il giro

/// «pagina 14 di 38»: il numero corre da 1 alla pagina con l'avanzamento del giro (un intero `Animatable`).
struct ContatorePagine: View, Animatable {
    var avanzamento: Double
    let pagina: Int
    let totale: Int

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    var body: some View {
        let n = 1 + Int((Double(max(0, pagina - 1)) * min(1, max(0, avanzamento))).rounded())
        Text("pagina \(n) di \(totale)")
            .carattereApple(Tema.Apple.Biblioteca.contatore)
            .foregroundColor(Tema.Apple.Colore.inchiostro)
            .accessibilityLabel(Text("pagina \(pagina) di \(totale)"))
    }
}

/// Il foglio che «sfoglia» mentre il contatore corre: ±4 in verticale, `sin(30·t)·4`.
struct OscillazioneFoglio: ViewModifier, Animatable {
    var avanzamento: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func body(content: Content) -> some View {
        let g = Tema.Apple.Moto.GiroPagine.self
        let y = avanzamento < 1 ? sin(g.frequenza * avanzamento) * Double(g.oscillazione) : 0
        return content.offset(y: CGFloat(y))
    }
}

/// Il vassoio con il contatore in alto e il foglio scalato (0,78, mai sotto 0,6). `giro` cambia → il contatore corre
/// fino alla pagina, il foglio oscilla e arriva, poi l'evidenziatore si stende. All'apparire tutto è già fermo
/// (tornando nella Biblioteca l'ultima risposta si ridisegna subito, senza giro).
struct VassoioBiblioteca<Comandi: View>: View {
    let foglio: FoglioBiblioteca
    let totale: Int
    let giro: Int
    @ViewBuilder var comandi: () -> Comandi

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var corsa: Double = 1
    @State private var arrivato = true
    @State private var evidenzia: Double = 1

    private typealias B = Tema.Apple.Biblioteca

    var body: some View {
        GeometryReader { g in
            let scala = max(B.scalaMinima, min(B.scalaFoglio, (g.size.width - 2 * B.latiVassoio) / B.larghezzaFoglio))
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: B.raggioVassoio, style: .continuous).fill(B.fondoVassoio)
                FoglioBiblioteca(documento: foglio.documento, pagina: foglio.pagina, testo: foglio.testo, frase: foglio.frase,
                                 passi: foglio.passi, avanzamento: evidenzia)
                    .scaleEffect(scala, anchor: .top)
                    .modifier(OscillazioneFoglio(avanzamento: corsa))
                    .opacity(arrivato ? 1 : Tema.Apple.Moto.GiroPagine.opacitaGiro)
                    .frame(width: g.size.width, height: max(0, g.size.height - B.margineFoglio), alignment: .top)
                    .padding(.top, B.margineFoglio)
                HStack(spacing: 8) {
                    comandi()
                    ContatorePagine(avanzamento: corsa, pagina: foglio.pagina, totale: totale)
                }
                .padding(B.paddingContatore)
                .background(Capsule(style: .continuous).fill(B.fondoContatore))
                .padding(.top, B.sopraContatore)
            }
            .clipShape(RoundedRectangle(cornerRadius: B.raggioVassoio, style: .continuous))
        }
        .onChange(of: giro) { _ in parti() }
        .onChange(of: foglio.frase) { _ in stendi() }
    }

    private func parti() {
        guard !fermo else {
            corsa = 1
            evidenzia = 1
            if calmo {
                arrivato = false
                withAnimation(Tema.Moto.dissolvenzaCalma) { arrivato = true }
            } else {
                arrivato = true
            }
            return
        }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            corsa = 0
            arrivato = false
            evidenzia = 0
        }
        withAnimation(Tema.Apple.Moto.GiroPagine.animazione) { corsa = 1 }
        withAnimation(Tema.Apple.Moto.GiroPagine.arrivo) { arrivato = true }
        withAnimation(Tema.Apple.Moto.Evidenzia.animazione) { evidenzia = 1 }
    }

    /// La frase arrivata dopo il giro (Vera ha risposto): l'evidenziatore si stende subito.
    private func stendi() {
        guard !fermo, corsa >= 1 else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { evidenzia = 0 }
        withAnimation(Tema.Apple.Moto.Evidenzia.curva.animazione(Tema.Apple.Moto.Evidenzia.durata)) { evidenzia = 1 }
    }
}
