import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// App Note nel tema Apple (Design/template-apple-specifica.md §1, AltreAppApple.swift): l'indice delle note a
// sinistra nel pannello `.side`, la nota nella card piatta con righe appena accennate, i pulsanti del tema.

extension Colori {
    /// Nel tema Apple (AltreAppApple.swift): l'indice nel pannello `.side`, la pagina nella card piatta.
    enum Note {
        private typealias A = Tema.Apple.Colore
        // Fondo dell'app: il fondo della finestra (pannello e card ci stanno sopra)
        static let fondoAlto = Color.clear
        static let fondoBasso = Color.clear
        static let taccuinoBordo = A.separatore
        static let taccuinoOmbra1 = Color.clear
        static let taccuinoOmbra2 = Color.clear
        static let taccuinoOmbra3 = Color.clear
        static let taccuinoOmbra4 = Color.clear
        // Testate (erano la rilegatura in cuoio)
        static let cuoioAlto = Color.clear
        static let cuoioMezzo = Color.clear
        static let cuoioBasso = Color.clear
        static let cuoioBordo = A.separatore
        static let cuoioLuce = Color.clear
        static let cuoioTesto = A.inchiostro2
        static let cuoioIncisione = Color.clear
        static let cucitura = Color.clear
        static let cucituraOmbra = Color.clear
        static let contatore = A.chip
        static let contatoreBordo = Color.clear
        static let stato = A.inchiostro2
        static let statoModificato = A.arancio
        // Pulsanti (capsule del tema Apple)
        static let pulsanteAlto = A.cardPiena
        static let pulsanteMezzoAlto = A.cardPiena
        static let pulsanteMezzoBasso = A.cardPiena
        static let pulsanteBasso = A.cardPiena
        static let pulsanteBordo = A.separatore
        static let pulsanteTesto = A.inchiostro
        static let pulsanteFissato = A.arancio
        // Indice: il fondo è il pannello
        static let indiceSinistra = Color.clear
        static let indiceCentro = Color.clear
        static let indiceDestra = Color.clear
        static let indiceBordo = Color.clear
        static let campo = A.chip
        static let campoBordo = Color.clear
        static let voceTesto = A.inchiostro
        static let voceSecondario = A.inchiostro2
        static let voceBordo = A.separatore
        static let voceLuce = Color.clear
        static let voceFondo = Color.clear
        static let selezioneAlto = A.selezioneVoce
        static let selezioneBasso = A.selezioneVoce
        static let selezioneTesto = A.inchiostro
        static let selezioneLuce = Color.clear
        static let selezioneBordo = Color.clear
        static let fissata = A.arancio
        static let piedeIndice = A.inchiostro3
        static let piedeIndiceBordo = A.separatore
        // Pagina: il fondo è la card
        static let paginaSinistra = Color.clear
        static let paginaChiara = Color.clear
        static let paginaCentro = Color.clear
        static let paginaDestra = Color.clear
        static let paginaOmbra = Color.clear
        static let margine1 = A.rosso.opacity(0.22)
        static let margine2 = A.rosso.opacity(0.14)
        static let righe = A.separatore
        static let lineaCliente = A.separatore
        static let etichetta = A.inchiostro2
        static let collegamento = A.accento
        static let titolo = A.inchiostro
        static let testo = A.inchiostro
        static let segnaposto = A.inchiostro3
        static let azioniAlto = Color.clear
        static let azioniBasso = Color.clear
        static let azioniBordo = A.separatore
        static let vuotoIcona = A.inchiostro3
        static let vuotoTitolo = A.inchiostro2
        static let vuotoTesto = A.inchiostro3
    }
}

extension Gradienti {
    static let fondoNote = LinearGradient.verticale(Colori.Note.fondoAlto, Colori.Note.fondoBasso)
    static let cuoioNote = LinearGradient.verticale([(Colori.Note.cuoioAlto, 0), (Colori.Note.cuoioMezzo, 0.55), (Colori.Note.cuoioBasso, 1)])
    static let pulsanteNote = LinearGradient.verticale([
        (Colori.Note.pulsanteAlto, 0), (Colori.Note.pulsanteMezzoAlto, 0.49), (Colori.Note.pulsanteMezzoBasso, 0.5), (Colori.Note.pulsanteBasso, 1),
    ])
    static let indiceNote = LinearGradient(stops: [
        .init(color: Colori.Note.indiceSinistra, location: 0), .init(color: Colori.Note.indiceCentro, location: 0.93),
        .init(color: Colori.Note.indiceDestra, location: 1),
    ], startPoint: .leading, endPoint: .trailing)
    static let selezioneNote = LinearGradient.verticale(Colori.Note.selezioneAlto, Colori.Note.selezioneBasso)
    static let paginaNote = LinearGradient(stops: [
        .init(color: Colori.Note.paginaSinistra, location: 0), .init(color: Colori.Note.paginaChiara, location: 0.02),
        .init(color: Colori.Note.paginaCentro, location: 0.92), .init(color: Colori.Note.paginaDestra, location: 1),
    ], startPoint: .leading, endPoint: .trailing)
    static let azioniNote = LinearGradient.verticale(Colori.Note.azioniAlto, Colori.Note.azioniBasso)
}

extension Misure {
    enum Note {
        static let raggio: CGFloat = Tema.Apple.Raggio.card
        static let etichetta = EdgeInsets(top: 14, leading: 16, bottom: 12, trailing: 16)
        static let barra = EdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        static let campoAltezza: CGFloat = 30
        static let voce = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let carta = EdgeInsets(top: 15, leading: 45, bottom: 12, trailing: 29)
        static let margine: CGFloat = 32
        /// Corpo del testo della nota (15, come nel tema) e passo delle righe (15 × 1,6).
        static let corpoTesto: CGFloat = 15
        static let riga: CGFloat = 24
        /// Altezza di una riga di testo nel carattere della nota come la misura l'editor (NSLayoutManager):
        /// con l'interlinea ogni riga è alta `riga` e il testo resta sulle righe della pagina.
        static let altezzaTesto: CGFloat = {
            #if os(macOS)
            let f = NSFont.systemFont(ofSize: Misure.Note.corpoTesto)
            return NSLayoutManager().defaultLineHeight(for: f)
            #elseif os(iOS)
            // Su iPhone e iPad l'editor (UITextView) usa l'altezza di riga del carattere
            return UIFont.systemFont(ofSize: Misure.Note.corpoTesto).lineHeight
            #endif
        }()
        static let interlinea: CGFloat = max(0, riga - altezzaTesto)
        /// La prima riga della pagina, appena sotto la prima riga di testo.
        static let primaRiga: CGFloat = altezzaTesto + 2
        static let azioni = EdgeInsets(top: 10, leading: 26, bottom: 10, trailing: 20)
        static let avatar: CGFloat = 24
        static let minimaPagina: CGFloat = 340
        /// Pulsanti in capsula della barra della pagina.
        static let pulsante = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
    }
}

extension Tipo {
    // La scala del tema Apple (§1.7), con la «Dimensione del testo» dei caratteri di sempre
    private typealias C = Tema.Apple.Carattere
    static let noteEtichetta = C.etichetta.fontLeggibile
    static let noteContatore = C(dimensione: 11, peso: .semibold, tabellare: true).fontLeggibile
    static let noteVoceTitolo = Tema.Apple.AltreApp.titoloVoce.fontLeggibile
    static let noteVoceTesto = C.secondario.fontLeggibile
    static let noteVoceData = Tema.Apple.AltreApp.nota.fontLeggibile
    static let notePiede = Tema.Apple.AltreApp.nota.fontLeggibile
    static let noteStato = Tema.Apple.AltreApp.nota.fontLeggibile
    static let notePulsante = C.pulsante.fontLeggibile
    static let notePer = C.etichetta.fontLeggibile
    static let noteCliente = C.pulsante.fontLeggibile
    static let noteCollegamento = C.pulsante.fontLeggibile
    static let noteTitolo = C.titoloDettaglio(26).fontLeggibile
    /// Il testo della nota: corpo fisso, perché le righe della pagina si contano su questo carattere.
    static let noteTesto = Font.system(size: Misure.Note.corpoTesto)
    static let notePiedePagina = C.sottotitolo.fontLeggibile
    static let noteDidascalia = C.secondario.fontLeggibile
    static let noteVuotoIcona = Tema.Testo.sf(50, .light)
    static let noteVuotoTitolo = C.titoloGruppo.fontLeggibile
    static let noteVuotoTesto = C.corpo.fontLeggibile
}

/// Pulsante della barra della pagina: il pulsante secondario del tema Apple; `evidenziato` (nota fissata)
/// con il testo arancio.
struct StileCuoioNote: ButtonStyle {
    var evidenziato = false

    func makeBody(configuration: Configuration) -> some View {
        // Il colore arancio della nota fissata lo dà l'etichetta (`.foregroundColor` sulla Label)
        StilePulsanteApple(.secondaria).makeBody(configuration: configuration)
    }
}

/// Testata dell'indice e della pagina (era la rilegatura in cuoio): trasparente sul vetro, filo sotto.
struct CuoioNote: View {
    var body: some View {
        Color.clear
            .overlay(alignment: .bottom) {
                Rectangle().fill(Colori.Note.cuoioBordo).frame(height: Tema.Misura.filo)
            }
    }
}

/// Le righe orizzontali della pagina, ogni `Misure.Note.riga` punti. `scorrimento` è quanto il
/// testo è salito nell'editor: le righe salgono con lui e restano sotto le parole.
struct RigheNote: Shape {
    var inizio: CGFloat = Misure.Note.primaRiga
    var scorrimento: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        var y = rect.minY + inizio - scorrimento
        if y < rect.minY { y += ceil((rect.minY - y) / Misure.Note.riga) * Misure.Note.riga }
        while y < rect.maxY {
            p.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: 1))
            y += Misure.Note.riga
        }
        return p
    }
}

/// Il margine rosso a sinistra della pagina (due linee sottili).
struct MargineNote: View {
    var body: some View {
        HStack(spacing: 1) {
            Rectangle().fill(Colori.Note.margine1).frame(width: 1)
            Rectangle().fill(Colori.Note.margine2).frame(width: 1)
        }
        .frame(maxHeight: .infinity)
    }
}

#if os(macOS)
/// Legge di quanto è scorso il testo dell'editor che ha accanto (il TextEditor di SwiftUI non lo
/// dice): cerca la vista di testo AppKit che sta sotto di sé e ne segue lo scorrimento.
struct ScorrimentoEditor: NSViewRepresentable {
    @Binding var scorrimento: CGFloat

    func makeCoordinator() -> Osservatore { Osservatore() }

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        context.coordinator.aggiorna = { y in if abs(scorrimento - y) > 0.5 { scorrimento = y } }
        DispatchQueue.main.async { context.coordinator.aggancia(da: v) }
        return v
    }

    func updateNSView(_ v: NSView, context: Context) {
        context.coordinator.aggiorna = { y in if abs(scorrimento - y) > 0.5 { scorrimento = y } }
        if context.coordinator.clip == nil { DispatchQueue.main.async { context.coordinator.aggancia(da: v) } }
    }

    static func dismantleNSView(_ v: NSView, coordinator: Osservatore) { coordinator.stacca() }

    final class Osservatore {
        var aggiorna: (CGFloat) -> Void = { _ in }
        weak var clip: NSClipView?
        private var token: NSObjectProtocol?

        /// La vista di testo il cui riquadro contiene il centro del segnaposto, salendo di qualche livello.
        func aggancia(da segno: NSView) {
            guard clip == nil, let finestra = segno.window else { return }
            let centro = segno.convert(NSPoint(x: segno.bounds.midX, y: segno.bounds.midY), to: nil)
            var livello: NSView? = segno.superview
            for _ in 0..<6 {
                guard let l = livello else { break }
                if let s = Self.cerca(in: l, centro: centro), s.window === finestra {
                    let c = s.contentView
                    c.postsBoundsChangedNotifications = true
                    clip = c
                    token = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: c, queue: .main) { [weak self] _ in
                        guard let self, let c = self.clip else { return }
                        self.aggiorna(c.bounds.origin.y)
                    }
                    aggiorna(c.bounds.origin.y)
                    return
                }
                livello = l.superview
            }
        }

        private static func cerca(in vista: NSView, centro: NSPoint) -> NSScrollView? {
            for v in vista.subviews {
                if let s = v as? NSScrollView, s.documentView is NSTextView,
                   s.convert(s.bounds, to: nil).contains(centro) { return s }
                if let s = cerca(in: v, centro: centro) { return s }
            }
            return nil
        }

        func stacca() {
            if let token { NotificationCenter.default.removeObserver(token) }
            token = nil
        }

        deinit { stacca() }
    }
}
#elseif os(iOS)
/// Su iPhone e iPad, per ora, le righe della pagina non seguono lo scorrimento del testo: segnaposto vuoto
/// con la stessa API (lo scorrimento resta 0).
struct ScorrimentoEditor: View {
    @Binding var scorrimento: CGFloat

    var body: some View { Color.clear }
}
#endif
