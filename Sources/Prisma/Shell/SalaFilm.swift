#if os(macOS)
import AppKit
#endif
import SwiftUI

// Sala › Il film del piano («Luce» giro 15, Design/template-luce-specifica.md §3.2). In alto lo schermo del film
// (880×495, raggio 18, sempre scuro), sotto i comandi (❚❚/▶︎, barra cliccabile e trascinabile, tempo «0:05 / 0:20»,
// «⇩ Esporta il video» e «Condividi il video…»), poi la tile dell'esportazione (sotto i comandi, mai sullo schermo) e le
// note degli stati vuoti. Il film si disegna con `DisegnoFilm` (una funzione pura del tempo) in un `Canvas` dentro
// `TimelineView(.animation(paused:))`: il ritmo del display, niente Timer. Parte da solo all'apertura del palco (mai con
// «Riduci movimento», dove le scene compaiono ferme con una dissolvenza di 0,15 s); a fine film ▶︎ riparte da capo.
// Tastiera: spazio pausa e riproduzione, ←/→ una scena, ⌘E esporta. Esportato: MP4 in `CartellaUscite`, poi Documento del
// cliente con l'impronta dei dati; la condivisione passa dal foglio del sistema (WhatsApp solo con il consenso), con la
// traccia nel dossier. Sulla sala opaca della presentazione solo lo schermo e i comandi di riproduzione. Istantanee:
// scena ferma nel suo stato finale (`sala.provaUscite.filmScena`) e la tile «pronto» se `filmEsportato`.

struct FilmDelPiano: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Falso sulla sala opaca della presentazione (si guarda, senza esportare né condividere).
    var modificabile = true

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    /// Il tempo del film quando è fermo (o da cui è ripartito).
    @State private var base: Double = 0
    /// Quando è ripartito (nil = in pausa).
    @State private var partenza: Date?
    @State private var avviato = false
    @State private var fase: FaseEsportazioneFilm = .ferma
    @State private var avanzamento = AvanzamentoFilm()
    @State private var regista: RegistaFilm?
    @State private var compito: Task<Void, Never>?
    @FocusState private var fuoco: Bool

    private typealias F = Tema.Apple.SalaRacconti.Film

    var body: some View {
        let _ = ContaCorpi.segna()
        let attuale = stato.cliente(cliente.id) ?? cliente
        let nome = ModelliMessaggi.primoNome(attuale.nome)
        Group {
            if let d = stato.datiFilm(attuale) {
                film(attuale, dati: d, nome: nome)
            } else {
                vuoto(attuale, nome: nome)
            }
        }
        .onChange(of: stato.bloccato) { _, bloccato in
            if bloccato { ferma() }
        }
        .onDisappear { ferma() }
    }

    // MARK: Il film

    private func film(_ c: Cliente, dati d: DatiFilm, nome: String) -> some View {
        GeometryReader { geo in
            let s = scala(geo.size)
            let larghezza = F.formato.width * s
            VStack(spacing: 0) {
                TimelineView(.animation(minimumInterval: nil, paused: partenza == nil || istantanea)) { tl in
                    let tempo = tempoCorrente(tl.date, d)
                    let finito = tempo >= d.durataTotale - 0.0001
                    VStack(spacing: F.sottoSchermo) {
                        SchermoFilm(dati: d, tempo: istantanea ? tempoIstantanea(d).disegno : tempo,
                                    fermo: calmo || istantanea, raggio: F.raggio * s)
                            .frame(width: larghezza, height: F.formato.height * s)
                        comandi(c, dati: d, nome: nome, tempo: istantanea ? tempoIstantanea(d).etichetta : tempo)
                            .frame(width: larghezza)
                    }
                    .onChange(of: finito) { _, ora in
                        if ora, partenza != nil { pausa(d, al: d.durataTotale) }
                    }
                }
                if modificabile {
                    HStack(alignment: .top, spacing: F.spazioComandi) {
                        TileEsportazioneFilm(stato: statoTile(c, dati: d, nome: nome),
                                             riprova: { avviaEsportazione(c, dati: d, nome: nome) },
                                             apri: { mostraNelFinder(c, dati: d) })
                            .frame(width: F.larghezzaTile, alignment: .leading)
                        note(c, dati: d, nome: nome)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, F.sopraTile)
                    .frame(width: larghezza, alignment: .leading)
                }
            }
            .padding(.top, F.sopra)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .focusable(!istantanea)
        .focused($fuoco)
        .focusEffectDisabled()
        .onKeyPress(phases: .down) { tasto in tastiera(tasto, dati: d) }
        .onAppear { avvia(d) }
        .accessibilityElement(children: .contain)
    }

    /// La scala dello schermo: 1 di solito, meno se il palco è basso o stretto (mai sotto 0,6).
    private func scala(_ misura: CGSize) -> CGFloat {
        let alto = (misura.height - F.sopra - (modificabile ? F.riservaSotto : F.sottoSchermo + F.pulsanteTondo)) / F.formato.height
        let largo = (misura.width - 2 * F.sopra) / F.formato.width
        return min(1, max(F.scalaMinima, min(alto, largo)))
    }

    // MARK: I comandi

    private func comandi(_ c: Cliente, dati d: DatiFilm, nome: String, tempo: Double) -> some View {
        let inRiproduzione = partenza != nil && !istantanea
        let inCorso = fase == .inCorso
        return HStack(spacing: F.spazioComandi) {
            Button { cambiaRiproduzione(d) } label: {
                Text(inRiproduzione ? "❚❚" : "▶︎")
                    .carattereApple(F.simboloPulsante)
                    .foregroundColor(F.coloreSimbolo)
                    .frame(width: F.pulsanteTondo, height: F.pulsanteTondo)
                    .background(Circle().fill(F.fondoPulsanteTondo))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(istantanea)
            .help(inRiproduzione ? "Pausa (spazio)" : "Riproduci (spazio)")
            .accessibilityLabel(Text(inRiproduzione ? "Pausa" : "Riproduci"))
            BarraFilm(frazione: d.durataTotale > 0 ? tempo / d.durataTotale : 0, attiva: !istantanea) { f in
                vai(f * d.durataTotale)
            }
            Text(TestiFilm.tempo(tempo, totale: d.durataTotale))
                .carattereApple(F.tempo)
                .foregroundColor(F.coloreTempo)
                .frame(width: F.larghezzaTempo)
                .lineLimit(1)
            if modificabile {
                Button { azioneEsporta(c, dati: d, nome: nome) } label: {
                    Text(etichettaEsporta(c, dati: d))
                }
                .buttonStyle(.apple)
                .keyboardShortcut("e", modifiers: .command)
                .disabled(istantanea)
                .help(inCorso ? "Ferma l'esportazione" : "MP4 1080p, 20 secondi, senza voce: resta nei Documenti del cliente")
                PulsanteCondividi(titolo: TestiFilm.condividi, primario: true, consensoWhatsApp: c.consensi.whatsapp == true,
                                  prepara: { await fileDaCondividere(c, dati: d, nome: nome) },
                                  esito: { e in dopoCondivisione(e, cliente: c, dati: d) })
                    .disabled(istantanea || inCorso)
            }
        }
    }

    // MARK: Note sotto i comandi

    @ViewBuilder
    private func note(_ c: Cliente, dati d: DatiFilm, nome: String) -> some View {
        VStack(alignment: .leading, spacing: F.spazioNote) {
            if !d.scene.contains(.oggi) {
                nota(TestiFilm.senzaObiettivi, avviso: false)
            } else if d.versamento == nil {
                nota(TestiFilm.senzaVersamenti, avviso: false)
            }
            if !d.scene.contains(.futuro) {
                nota(TestiFilm.senzaCurva, avviso: false)
            }
            if stato.primaUscita(clienteId: c.id) {
                nota(TestiUscite.avvisoPrimaVolta(nome: nome, cosa: "Il video"), avviso: false)
            }
            if stato.avvertenzaFilmSegnaposto {
                HStack(spacing: F.spazioNote) {
                    nota(TestiFilm.avvertenzaNonScelta, avviso: true)
                    Button("Impostazioni ›") {
                        stato.schedaImpostazioni = .sala
                        stato.apri(.impostazioni)
                    }
                    .buttonStyle(.appleSobrio)
                }
            }
            if !stato.dati.impostazioni.backup.cifrato {
                nota(TestiUscite.promemoriaBackup, avviso: true)
            }
            if d.diProva {
                nota(TestiFilm.datiDiProvaNota, avviso: false)
            }
        }
    }

    private func nota(_ testo: String, avviso: Bool) -> some View {
        Text(testo)
            .carattereApple(F.nota)
            .foregroundColor(avviso ? F.coloreAvviso : F.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Stato vuoto

    private func vuoto(_ c: Cliente, nome: String) -> some View {
        VStack(spacing: F.spazioVuoto) {
            Text(TestiFilm.vuoto(nome))
                .carattereApple(F.vuoto)
                .foregroundColor(F.coloreVuoto)
                .multilineTextAlignment(.center)
                .frame(maxWidth: F.larghezzaVuoto)
                .fixedSize(horizontal: false, vertical: true)
            if modificabile {
                HStack(spacing: F.spazioComandi) {
                    Button(TestiFilm.apriObiettivi) {
                        stato.clienteAttivoId = c.id
                        stato.schedaCliente = .obiettivi
                        stato.apri(.clienti)
                    }
                    .buttonStyle(.apple)
                    Button(TestiFilm.apriAnagrafica) { stato.apriCliente(c.id) }
                        .buttonStyle(.apple)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Riproduzione

    private func tempoCorrente(_ adesso: Date, _ d: DatiFilm) -> Double {
        guard let p = partenza else { return min(max(base, 0), d.durataTotale) }
        return min(d.durataTotale, max(0, base + adesso.timeIntervalSince(p)))
    }

    /// Nelle istantanee: la scena chiesta ferma nel suo stato finale; l'etichetta del tempo all'inizio della scena.
    private func tempoIstantanea(_ d: DatiFilm) -> (disegno: Double, etichetta: Double) {
        let chiesta = stato.sala.provaUscite.filmScena ?? 0
        let indice = d.scene.firstIndex { $0.rawValue >= chiesta } ?? max(0, d.scene.count - 1)
        let inizio = MotoreFilm.inizio(scena: indice, d)
        let durata = d.durate.indices.contains(indice) ? d.durate[indice] : 0
        return (inizio + max(0, durata - 0.001), inizio)
    }

    private func avvia(_ d: DatiFilm) {
        guard !avviato else { return }
        avviato = true
        base = 0
        // Parte da solo, mai con «Riduci movimento» (lì resta fermo sulla prima scena) né nelle istantanee
        partenza = (calmo || istantanea) ? nil : Date()
    }

    private func cambiaRiproduzione(_ d: DatiFilm) {
        if partenza != nil {
            pausa(d, al: tempoCorrente(Date(), d))
        } else {
            if base >= d.durataTotale - 0.05 { base = 0 }
            partenza = Date()
        }
    }

    private func pausa(_ d: DatiFilm, al tempo: Double) {
        base = min(max(tempo, 0), d.durataTotale)
        partenza = nil
    }

    private func vai(_ tempo: Double) {
        base = max(0, tempo)
        if partenza != nil { partenza = Date() }
    }

    private func tastiera(_ tasto: KeyPress, dati d: DatiFilm) -> KeyPress.Result {
        guard !istantanea else { return .ignored }
        switch tasto.key {
        case .space:
            cambiaRiproduzione(d)
            return .handled
        case .rightArrow:
            let (k, _) = MotoreFilm.scena(al: tempoCorrente(Date(), d), d)
            vai(k + 1 < d.scene.count ? MotoreFilm.inizio(scena: k + 1, d) : d.durataTotale)
            return .handled
        case .leftArrow:
            let (k, t) = MotoreFilm.scena(al: tempoCorrente(Date(), d), d)
            vai(MotoreFilm.inizio(scena: t > 0.5 ? k : max(0, k - 1), d))
            return .handled
        default:
            return .ignored
        }
    }

    // MARK: Esportazione

    private func etichettaEsporta(_ c: Cliente, dati d: DatiFilm) -> String {
        if fase == .inCorso { return TestiFilm.annulla }
        #if os(macOS)
        if urlDaMostrare(c, dati: d) != nil { return TestiFilm.mostraNelFinder }
        #endif
        return TestiFilm.esporta
    }

    private func azioneEsporta(_ c: Cliente, dati d: DatiFilm, nome: String) {
        if fase == .inCorso {
            regista?.annulla()
            return
        }
        #if os(macOS)
        if urlDaMostrare(c, dati: d) != nil {
            mostraNelFinder(c, dati: d)
            return
        }
        #endif
        avviaEsportazione(c, dati: d, nome: nome)
    }

    private func avviaEsportazione(_ c: Cliente, dati d: DatiFilm, nome: String) {
        guard fase != .inCorso, !istantanea else { return }
        compito = Task { @MainActor in
            _ = await esportaOra(c, dati: d, nome: nome)
        }
    }

    /// Scrive il video in `CartellaUscite` e lo conserva come Documento del cliente. true se riuscito.
    @MainActor
    private func esportaOra(_ c: Cliente, dati d: DatiFilm, nome: String) async -> Bool {
        guard fase != .inCorso else { return false }
        let r = RegistaFilm()
        regista = r
        avanzamento.frazione = 0
        fase = .inCorso
        let url = CartellaUscite.cartella.appendingPathComponent(TestiFilm.nomeFile(nome))
        let barra = avanzamento
        do {
            try FileManager.default.createDirectory(at: CartellaUscite.cartella, withIntermediateDirectories: true)
            try await r.esporta(d, in: url) { f in
                DispatchQueue.main.async { barra.frazione = f }
            }
            let video = try Data(contentsOf: url)
            let id = stato.registraFilmEsportato(c, dati: d, video: video)
            regista = nil
            fase = .pronto(url, documentoId: id)
            return true
        } catch let e as ErroreFilm {
            regista = nil
            fase = e == .annullato ? .ferma : .errore(e.messaggio)
            return false
        } catch {
            regista = nil
            fase = .errore(TestiFilm.scrittura(error.localizedDescription))
            return false
        }
    }

    /// Il file da mostrare nel Finder: il Documento aggiornato, o la copia appena esportata.
    private func urlDaMostrare(_ c: Cliente, dati d: DatiFilm) -> URL? {
        let fm = FileManager.default
        if let doc = stato.filmAggiornato(c, dati: d), let u = stato.urlDocumento(doc), fm.fileExists(atPath: u.path) { return u }
        if case .pronto(let u, _) = fase, fm.fileExists(atPath: u.path) { return u }
        return nil
    }

    private func mostraNelFinder(_ c: Cliente, dati d: DatiFilm) {
        #if os(macOS)
        guard let u = urlDaMostrare(c, dati: d) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([u])
        #endif
    }

    private func statoTile(_ c: Cliente, dati d: DatiFilm, nome: String) -> StatoTileFilm {
        if istantanea {
            return stato.sala.provaUscite.filmEsportato ? .pronto(TestiFilm.nomeFile(nome), d.durataTotale) : .nessuna
        }
        switch fase {
        case .inCorso: return .inCorso(avanzamento.frazione)
        case .errore(let m): return .errore(m)
        case .pronto: return .pronto(TestiFilm.nomeFile(nome), d.durataTotale)
        case .ferma: break
        }
        if stato.filmAggiornato(c, dati: d) != nil { return .pronto(TestiFilm.nomeFile(nome), d.durataTotale) }
        if let quando = stato.filmCambiatoDal(c, dati: d) { return .cambiato(quando) }
        return .nessuna
    }

    // MARK: Condivisione

    /// Il video da condividere: la copia del Documento aggiornato, quella appena esportata, o un'esportazione adesso.
    @MainActor
    private func fileDaCondividere(_ c: Cliente, dati d: DatiFilm, nome: String) async -> [URL]? {
        if let doc = stato.filmAggiornato(c, dati: d), let u = stato.copiaFilmDaCondividere(doc, nome: nome) { return [u] }
        if case .pronto(let u, _) = fase, FileManager.default.fileExists(atPath: u.path) { return [u] }
        guard await esportaOra(c, dati: d, nome: nome) else { return nil }
        if case .pronto(let u, _) = fase, FileManager.default.fileExists(atPath: u.path) { return [u] }
        return nil
    }

    private func dopoCondivisione(_ e: EsitoCondivisione, cliente c: Cliente, dati d: DatiFilm) {
        var documentoId = stato.filmAggiornato(c, dati: d)?.id
        if case .pronto(_, let id) = fase, documentoId == nil { documentoId = id }
        switch e {
        case .condiviso(let via):
            stato.registraUscitaFilm(c, dati: d, via: via, documentoId: documentoId)
            stato.mostraAvviso(TestiFilm.uscito)
        case .annullato:
            break
        case .nonRiuscito(let motivo):
            stato.mostraAvviso(motivo)
        }
        // Il foglio toglie la copia temporanea dopo l'esito: il video resta nei Documenti
        if case .pronto(let u, _) = fase, !FileManager.default.fileExists(atPath: u.path) { fase = .ferma }
    }

    /// Al blocco e alla chiusura del palco: niente esportazione in corso, film fermo.
    private func ferma() {
        regista?.annulla()
        compito?.cancel()
        compito = nil
        if partenza != nil { partenza = nil }
        if case .pronto(let u, _) = fase, !FileManager.default.fileExists(atPath: u.path) { fase = .ferma }
    }
}

/// Le fasi dell'esportazione nel palco.
enum FaseEsportazioneFilm: Equatable {
    case ferma
    case inCorso
    case pronto(URL, documentoId: String?)
    case errore(String)
}

/// L'avanzamento vero della codifica: lo scrive la callback del regista (dal thread principale), lo legge la tile.
@Observable final class AvanzamentoFilm: @unchecked Sendable {
    var frazione: Double = 0
}

/// Cosa mostra la tile dell'esportazione.
enum StatoTileFilm: Equatable {
    case nessuna
    case inCorso(Double)
    case pronto(String, Double)
    case errore(String)
    case cambiato(Date)
}

// MARK: - Lo schermo

/// Lo schermo del film: il fotogramma all'istante `tempo` disegnato da `DisegnoFilm` in un `Canvas`.
struct SchermoFilm: View {
    let dati: DatiFilm
    let tempo: Double
    var fermo = false
    var raggio: CGFloat = Tema.Apple.SalaRacconti.Film.raggio

    private typealias F = Tema.Apple.SalaRacconti.Film

    var body: some View {
        Canvas(opaque: true) { contesto, misura in
            contesto.withCGContext { cg in
                DisegnoFilm.disegna(in: cg, dimensione: misura, tempo: tempo, dati: dati, fermo: fermo)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: raggio, style: .continuous))
        .shadow(color: F.ombraColore, radius: F.ombraRaggio, x: 0, y: F.ombraY)
        .accessibilityElement()
        .accessibilityLabel(Text(dati.titolo))
        .accessibilityValue(Text(TestiFilm.tempo(tempo, totale: dati.durataTotale)))
    }
}

// MARK: - La barra

/// La barra dell'avanzamento: alta 6, raggio 9; un clic o un trascinamento porta a quel punto.
struct BarraFilm: View {
    let frazione: Double
    var attiva = true
    let vai: (Double) -> Void

    private typealias F = Tema.Apple.SalaRacconti.Film

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let f = min(max(frazione.isFinite ? frazione : 0, 0), 1)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: F.raggioBarra, style: .continuous)
                    .fill(F.binarioBarra)
                    .frame(height: F.altezzaBarra)
                RoundedRectangle(cornerRadius: F.raggioBarra, style: .continuous)
                    .fill(F.riempimentoBarra)
                    .frame(width: w * CGFloat(f), height: F.altezzaBarra)
            }
            .frame(width: w, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                guard attiva else { return }
                vai(Double(min(max(g.location.x / w, 0), 1)))
            })
        }
        .frame(height: F.areaBarra)
        .accessibilityElement()
        .accessibilityLabel(Text("Avanzamento del film"))
        .accessibilityValue(Text("\(Int((min(max(frazione.isFinite ? frazione : 0, 0), 1) * 100).rounded()))%"))
    }
}

// MARK: - La tile dell'esportazione

/// «Esporto il video · 1080p» con la barra vera; «✓ Il piano di Giulia.mp4 · 20 secondi · senza voce · pronto» (bordo
/// verde, un clic lo mostra nel Finder); rossa con il motivo e «Riprova»; «Il piano è cambiato dopo il …».
struct TileEsportazioneFilm: View {
    let stato: StatoTileFilm
    let riprova: () -> Void
    let apri: () -> Void

    private typealias F = Tema.Apple.SalaRacconti.Film

    var body: some View {
        switch stato {
        case .nessuna:
            Color.clear.frame(height: 0)
        case .inCorso(let f):
            corpo(bordo: nil) {
                Text(TestiFilm.esportoIlVideo)
                    .carattereApple(F.testoTile)
                    .foregroundColor(F.coloreTestoTile)
                BarraEsportazioneFilm(frazione: f)
            }
        case .pronto(let nome, let totale):
            Button(action: apri) {
                corpo(bordo: F.bordoPronto) {
                    Text(TestiFilm.pronto(nome))
                        .carattereApple(F.testoTile)
                        .foregroundColor(F.colorePronto)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(TestiFilm.dettaglioPronto(totale))
                        .carattereApple(F.dettaglioTile)
                        .foregroundColor(F.coloreDettaglio)
                }
            }
            .buttonStyle(.plain)
            .help("Il video è nei Documenti del cliente")
        case .errore(let motivo):
            corpo(bordo: F.bordoErrore) {
                Text(motivo)
                    .carattereApple(F.testoTile)
                    .foregroundColor(F.coloreErrore)
                    .fixedSize(horizontal: false, vertical: true)
                Button(TestiFilm.riprova, action: riprova)
                    .buttonStyle(.appleSobrio)
            }
        case .cambiato(let quando):
            corpo(bordo: nil) {
                Text(TestiFilm.cambiato(quando))
                    .carattereApple(F.testoTile)
                    .foregroundColor(F.coloreAvviso)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func corpo<C: View>(bordo: Color?, @ViewBuilder _ contenuto: () -> C) -> some View {
        VStack(alignment: .leading, spacing: F.spazioTile) {
            contenuto()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(F.paddingTile)
        .superficieApple(F.tile, raggio: F.raggioTile)
        .overlay(RoundedRectangle(cornerRadius: F.raggioTile, style: .continuous)
            .strokeBorder(bordo ?? Color.clear, lineWidth: F.spessoreBordo))
    }
}

/// La barra della tile: segue l'avanzamento vero della codifica, ammorbidita (con «Riduci movimento» senza animazione).
struct BarraEsportazioneFilm: View {
    let frazione: Double
    @Environment(\.prismaCalmo) private var calmo
    private typealias F = Tema.Apple.SalaRacconti.Film

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: F.raggioBarraTile, style: .continuous).fill(F.binarioBarra)
                RoundedRectangle(cornerRadius: F.raggioBarraTile, style: .continuous).fill(F.riempimentoBarra)
                    .frame(width: geo.size.width * CGFloat(min(max(frazione, 0), 1)))
            }
        }
        .frame(height: F.altezzaBarraTile)
        .animation(calmo ? nil : Tema.Apple.Moto.Curva.backup.animazione(Tema.Apple.Moto.Film.barraEsportazione), value: frazione)
    }
}
