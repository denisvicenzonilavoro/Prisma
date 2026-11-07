#if os(macOS)
import SwiftUI

// Il tavolo con l'iPad sul Mac (Tavolo/TavoloMac.swift): il pulsante «Al tavolo» con lo stato, il pannello dei comandi
// in Prospetti, la striscia dei comandi nella sala della presentazione e la pagina finale della presa visione nel PDF.
// Il template non ha il tavolo: i pezzi sono quelli del tema Apple (pulsanti a capsula, puntino di stato, sala
// sempre scura) e la carta dei documenti (sempre chiara). Valori in DesignSystem/Apple/Tema.Apple+Tavolo.swift.

/// Il puntino dello stato: verde con l'iPad collegato, arancio in attesa, tenue a tavolo chiuso.
struct PuntinoTavolo: View {
    let collegamento: TavoloMac.Collegamento

    var body: some View {
        let t = Tema.Apple.Tavolo.self
        Circle()
            .fill(colore)
            .frame(width: t.puntino, height: t.puntino)
            .accessibilityHidden(true)
    }

    private var colore: Color {
        let t = Tema.Apple.Tavolo.self
        switch collegamento {
        case .spento: return t.coloreSpento
        case .inAttesa: return t.coloreInAttesa
        case .collegato: return t.coloreCollegato
        }
    }
}

// MARK: - In Prospetti

/// «Al tavolo» nella barra delle azioni di Prospetti: lo stato e, al clic, il pannello dei comandi.
struct PulsanteAlTavolo: View {
    @ObservedObject var tavolo: TavoloMac
    let contesto: ContestoTavolo
    var soloIcona = false
    @EnvironmentObject var stato: StatoShell
    @State private var aperto = false

    var body: some View {
        let t = Tema.Apple.Tavolo.self
        Button { aperto.toggle() } label: {
            HStack(spacing: t.spazioPuntino) {
                PuntinoTavolo(collegamento: tavolo.collegamento)
                if soloIcona {
                    Image(systemName: "ipad.landscape")
                        .accessibilityLabel(Text("Al tavolo"))
                } else {
                    Text("Al tavolo")
                }
            }
        }
        .buttonStyle(.apple)
        .fixedSize()
        .help("Al tavolo · \(tavolo.descrizione): l'iPad davanti al cliente mostra solo ciò che scegli qui")
        .popover(isPresented: $aperto, arrowEdge: .bottom) {
            PannelloAlTavolo(tavolo: tavolo, contesto: contesto)
                .environmentObject(stato)
        }
    }
}

/// I comandi del tavolo (popover di Prospetti): aprire, mandare, chiedere la presa visione, chiudere.
struct PannelloAlTavolo: View {
    @ObservedObject var tavolo: TavoloMac
    let contesto: ContestoTavolo
    @EnvironmentObject var stato: StatoShell
    @State private var minimo = 50.0
    @State private var massimo = 1_000.0

    var body: some View {
        let t = Tema.Apple.Tavolo.self
        VStack(alignment: .leading, spacing: t.spazioPannello) {
            intestazione
            if tavolo.acceso {
                comandi
            } else {
                apertura
            }
            if let a = tavolo.avviso {
                Text(a)
                    .carattereApple(t.avviso)
                    .foregroundColor(t.coloreAvviso)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let id = tavolo.ultimaPresaVisione {
                Button {
                    stato.documentoSelezionato = id
                    stato.apri(.documenti)
                } label: {
                    HStack(spacing: Tema.Apple.Controlli.Pulsante.spazio) {
                        Text("Presa visione archiviata in Documenti")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(.appleSobrio)
            }
        }
        .padding(t.paddingPannello)
        .frame(width: t.larghezzaPannello, alignment: .leading)
    }

    private var intestazione: some View {
        let t = Tema.Apple.Tavolo.self
        return VStack(alignment: .leading, spacing: Tema.Apple.Tavolo.PresaVisione.spazioPiccolo) {
            Text("Al tavolo con l'iPad")
                .carattereApple(t.titoloPannello)
                .foregroundColor(t.coloreTitoloPannello)
            HStack(spacing: t.spazioPuntino) {
                PuntinoTavolo(collegamento: tavolo.collegamento)
                Text(statoEsteso)
                    .carattereApple(t.statoPannello)
                    .foregroundColor(t.coloreStatoPannello)
                    .lineLimit(2)
            }
        }
    }

    private var statoEsteso: String {
        guard let m = tavolo.mostrato, tavolo.collegato else { return tavolo.descrizione }
        return "\(tavolo.descrizione) · mostra: \(m)"
    }

    /// A tavolo chiuso: che cosa fa, il codice (non in modalità cliente) e «Apri il tavolo».
    private var apertura: some View {
        let t = Tema.Apple.Tavolo.self
        let codice = stato.dati.impostazioni.vera.ponte.codice
        return VStack(alignment: .leading, spacing: t.spazioPannello) {
            Text("L'iPad davanti al cliente mostra solo ciò che scegli qui. Mac e iPad sulla stessa rete Wi‑Fi, con il codice di Vera.")
                .carattereApple(t.statoPannello)
                .foregroundColor(t.coloreStatoPannello)
                .fixedSize(horizontal: false, vertical: true)
            if !stato.inModoCliente, PonteVera.normalizza(codice) != nil {
                Text("Codice \(codice)")
                    .carattereApple(t.codice)
                    .foregroundColor(t.coloreCodice)
                    .textSelection(.enabled)
            }
            Button {
                tavolo.avvia()
            } label: {
                Label("Apri il tavolo", systemImage: "ipad.landscape")
            }
            .buttonStyle(.applePrimario)
        }
    }

    private var comandi: some View {
        let t = Tema.Apple.Tavolo.self
        let azioni = tavolo.azioni(contesto)
        return VStack(alignment: .leading, spacing: t.spazioAzioni) {
            ForEach(azioni) { a in
                Button { a.azione() } label: {
                    Label(a.titolo, systemImage: a.simbolo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.apple)
                .disabled(!a.abilitata)
                .help(a.aiuto)
            }
            limitiCursore
            Button(role: .destructive) {
                tavolo.chiudi()
            } label: {
                Label("Chiudi il tavolo", systemImage: "xmark")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.appleSobrio)
            .help("L'iPad torna alla schermata neutra e il Mac smette di ascoltare in rete")
        }
    }

    /// I limiti del cursore del versamento mensile: li decide il consulente.
    private var limitiCursore: some View {
        let t = Tema.Apple.Tavolo.self
        return HStack(spacing: t.spazioAzioni) {
            Text("Cursore da")
            TextField("", value: $minimo, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: t.larghezzaCampo)
            Text("a")
            TextField("", value: $massimo, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: t.larghezzaCampo)
            Text("€")
            Button("Lascia") { tavolo.lasciaCursore(contesto, minimo: minimo, massimo: massimo) }
                .buttonStyle(.apple)
                .disabled(!tavolo.collegato)
        }
        .carattereApple(t.statoPannello)
        .foregroundColor(t.coloreStatoPannello)
    }
}

// MARK: - Nella sala della presentazione

/// «Al tavolo» fra i comandi della sala: lo stato e la striscia dei comandi.
struct PulsanteTavoloSala: View {
    @ObservedObject var tavolo: TavoloMac
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo

    var body: some View {
        let t = Tema.Apple.Tavolo.self
        Button {
            let a = Tema.Apple.Moto.animazione(t.comparsa, calmo: calmo)
            if fermo {
                tavolo.pannello.toggle()
            } else {
                withAnimation(a) { tavolo.pannello.toggle() }
            }
        } label: {
            HStack(spacing: t.spazioPuntino) {
                PuntinoTavolo(collegamento: tavolo.collegamento)
                Text("Al tavolo")
            }
        }
        .buttonStyle(StileCapsulaSalaApple(chiara: false))
        .help("Al tavolo · \(tavolo.descrizione): manda all'iPad questa pagina, la macchina del tempo, la famiglia o un cursore")
    }
}

/// La striscia dei comandi del tavolo sopra quelli della sala (si apre da «Al tavolo»).
struct StrisciaTavoloSala: View {
    @ObservedObject var tavolo: TavoloMac
    let contesto: ContestoTavolo
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        let t = Tema.Apple.Tavolo.self
        if tavolo.pannello {
            VStack(spacing: t.spazioStriscia) {
                Text(stato)
                    .carattereApple(t.carattereStriscia)
                    .foregroundColor(t.testoStriscia)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: t.spazioStriscia) {
                    if tavolo.acceso {
                        ForEach(tavolo.azioni(contesto).filter { $0.id != "documento" }) { a in
                            Button { a.azione() } label: { Text(a.titolo) }
                                .buttonStyle(StileCapsulaSalaApple(chiara: false))
                                .disabled(!a.abilitata)
                                .opacity(a.abilitata ? 1 : Tema.Apple.Prospetti.Anteprima.opacitaFrecciaSpenta)
                                .help(a.aiuto)
                        }
                        Button("Chiudi il tavolo") { tavolo.chiudi() }
                            .buttonStyle(StileCapsulaSalaApple(chiara: false))
                    } else {
                        Button("Apri il tavolo") { tavolo.avvia() }
                            .buttonStyle(StileCapsulaSalaApple(chiara: true))
                    }
                }
            }
            .padding(t.paddingStriscia)
            .background {
                RoundedRectangle(cornerRadius: t.raggioStriscia, style: .continuous).fill(t.fondoStriscia)
            }
            .padding(.bottom, t.sopraComandiSala)
            .transition(calmo ? .opacity : .opacity.combined(with: .offset(y: t.spostamentoComparsa)))
        }
    }

    private var stato: String {
        var testo = tavolo.descrizione
        if let m = tavolo.mostrato, tavolo.collegato { testo += " · il cliente vede: \(m)" }
        if let a = tavolo.avviso { testo += " · \(a)" }
        return testo
    }
}

// MARK: - La pagina della presa visione (carta)

/// L'ultima pagina del PDF con la presa visione: il documento, la scritta esatta, il tratto del cliente e la data.
/// Su carta: sempre chiara, colori opachi e fissi, niente vetro. Stesso formato delle pagine del documento.
struct PaginaPresaVisione: View {
    private typealias T = Tipo.Documento
    private typealias P = Tema.Apple.Tavolo.PresaVisione
    @Environment(\.paletteDocumento) private var C
    let titolo: String
    let genere: String
    let cliente: String
    let pagine: Int
    let formato: CGSize
    let tratto: CGImage
    let data: Date

    var body: some View {
        FoglioDocumento(formato: formato) {
            VStack(alignment: .leading, spacing: P.spazio) {
                VStack(alignment: .leading, spacing: P.spazioPiccolo) {
                    Text(verbatim: "PRESA VISIONE")
                        .font(T.pOcchiello)
                        .foregroundColor(C.occhiello)
                    Text(verbatim: titolo)
                        .font(T.pTitolo)
                        .foregroundColor(C.titolo)
                    Text(verbatim: "\(genere) · \(cliente) · \(pagine) \(pagine == 1 ? "pagina" : "pagine")")
                        .font(T.pSottotitolo)
                        .foregroundColor(C.tenue)
                }
                Rectangle().fill(C.filetto).frame(height: P.filetto)
                Text(verbatim: ProtocolloTavolo.testoPresaVisione)
                    .font(T.pSezione)
                    .foregroundColor(C.titolo)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "Il documento è stato mostrato al cliente sull'iPad, al tavolo, pagina per pagina. Il segno qui sotto dice solo che l'ha visto.")
                    .font(T.pCorpo)
                    .foregroundColor(C.tenue)
                    .fixedSize(horizontal: false, vertical: true)
                Image(decorative: tratto, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(P.paddingTratto)
                    .frame(width: P.tratto.width, height: P.tratto.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: P.raggioTratto, style: .continuous)
                            .strokeBorder(P.coloreBordo, lineWidth: P.bordoTratto)
                    }
                Text(verbatim: "\(cliente) · \(Formati.dataEstesa.string(from: data)), ore \(Formati.ora.string(from: data))")
                    .font(T.pCorpoForte)
                    .foregroundColor(C.testo)
                Spacer(minLength: 0)
                Text(verbatim: "Creato con Prisma sul Mac del consulente. Il PDF resta nei Documenti del cliente.")
                    .font(T.pPiede)
                    .foregroundColor(C.tenue)
            }
            .padding(EdgeInsets(top: P.alto, leading: P.margine, bottom: P.margine, trailing: P.margine))
            .overlay(alignment: .topTrailing) {
                LogoPrismaConNome(colore: Colori.Documento.logo, altezza: Misure.Documento.logoProspetto)
                    .padding(.top, Misure.Documento.logoProspettoAlto)
                    .padding(.trailing, P.margine)
            }
        }
    }
}

/// Un tratto di prova (istantanee e prove): una curva su fondo trasparente, 600×240 pixel.
enum TrattoProvaTavolo {
    private typealias P = Tema.Apple.Tavolo.PresaVisione

    static func immagine() -> CGImage? {
        let w = 600, h = 240
        guard let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c.setStrokeColor(P.coloreTrattoProva)
        c.setLineWidth(P.spessoreTrattoProva * 2)
        c.setLineCap(.round)
        c.setLineJoin(.round)
        c.move(to: CGPoint(x: 40, y: 90))
        c.addCurve(to: CGPoint(x: 200, y: 170), control1: CGPoint(x: 80, y: 220), control2: CGPoint(x: 150, y: 40))
        c.addCurve(to: CGPoint(x: 380, y: 110), control1: CGPoint(x: 250, y: 260), control2: CGPoint(x: 320, y: 30))
        c.addCurve(to: CGPoint(x: 560, y: 150), control1: CGPoint(x: 430, y: 180), control2: CGPoint(x: 500, y: 70))
        c.strokePath()
        return c.makeImage()
    }
}
#endif
