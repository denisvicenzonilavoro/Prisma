#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

// Ombre delle finestre già sfocate in una bitmap a 9 fette, con il buco della forma ritagliato («mai sotto il vetro»).
// Si disegnano una volta con CoreGraphics per (raggio, strati, scala) e poi si stirano: aprire, spostare, scalare
// o cambiare finestra attiva costa quanto un'immagine, senza sfocature né maschere fuori schermo a ogni fotogramma.

extension Tema.Ombra {
    /// Fin dove si disegna la sfocatura, in multipli della sfocatura CSS: 1,25 = 2,5 σ (oltre resta meno dello 0,3 %).
    static let estensionePrecalcolata: CGFloat = 1.25
    /// Sfocatura di CoreGraphics per un punto di sfocatura CSS (CG blur ≈ CSS blur, come il raggio/2 di SwiftUI).
    static let fattoreSfocaturaPrecalcolata: CGFloat = 1
    /// Ombre tenute in memoria (finestre, riquadri, schede, pulsanti; chiaro e scuro; 1x e 2x): oltre si toglie
    /// la meno usata di recente, mai tutte insieme.
    static let limitePrecalcolate = 32
    /// Il raggio nella bitmap, a passi di mezzo punto (i raggi letti da un GeometryReader sono frazionari).
    static let passoRaggioPrecalcolato: CGFloat = 0.5
    /// Un lato più corto della forma «lunga» si disegna alla sua misura, a passi di 2 pt (il resto si stira al centro).
    static let passoMisuraPrecalcolata: CGFloat = 2
}

/// Le bitmap delle ombre. Solo dal thread principale (SwiftUI valuta i body lì); `prepara` disegna fuori,
/// ma cache e conteggio li tocca solo qui.
enum OmbraPrecalcolata {
    /// L'immagine e dove tagliarla: `margine` = quanto esce dalla forma, `bordo` / `bordoAlto` = lato delle fette
    /// d'angolo in orizzontale e in verticale (al centro restano 2 pt che si stirano).
    struct Pronta {
        let immagine: ImmaginePiattaforma
        let margine: CGFloat
        let bordo: CGFloat
        let bordoAlto: CGFloat
    }

    private static var cache: [String: Pronta] = [:]
    /// Quante bitmap si sono disegnate da quando parte l'app (la prova di fluidità le conta per azione).
    private(set) static var disegnate = 0
    /// Le chiavi dalla meno usata di recente alla più usata.
    private static var ordine: [String] = []

    /// Che cosa disegnare e con quale chiave: raggio a passi, strati che contano e forma (lunga o alla misura).
    private struct Voce {
        let chiave: String
        let raggio: CGFloat
        let strati: [StratoOmbra]
        let scala: CGFloat
        let margine: CGFloat
        let forma: CGSize
    }

    /// `misura`: la misura della forma. Senza, o con lati abbastanza lunghi, la bitmap è quella a 9 fette che
    /// vale per ogni misura; un lato più corto di quanto servono le fette d'angolo si disegna alla sua misura
    /// (prima, stirando fette che si sovrapponevano, l'ombra usciva spostata o in un riquadro spurio).
    static func ombra(raggio: CGFloat, strati: [StratoOmbra], scala: CGFloat, misura: CGSize? = nil) -> Pronta? {
        guard let v = voce(raggio: raggio, strati: strati, scala: scala, misura: misura) else { return nil }
        if let pronta = cache[v.chiave] {
            if ordine.last != v.chiave, let i = ordine.firstIndex(of: v.chiave) {
                ordine.remove(at: i)
                ordine.append(v.chiave)
            }
            return pronta
        }
        guard let pronta = disegna(v) else { return nil }
        disegnate += 1
        conserva(pronta, chiave: v.chiave)
        return pronta
    }

    private static func voce(raggio: CGFloat, strati: [StratoOmbra], scala: CGFloat, misura: CGSize?) -> Voce? {
        var strati = strati
        if let misura, misura.width > 0, misura.height > 0 {
            // Uno strato che rientra di metà del lato corto o più non disegna nulla (lo salta `disegna`): fuori
            // subito, così non allarga margine e forma piena (le pillole tornano a 9 fette e a una voce sola)
            let corto = min(misura.width, misura.height)
            strati = strati.filter { 2 * max(0, -$0.espansione) < corto }
        }
        guard !strati.isEmpty else { return nil }
        let scala = max(1, scala)
        let passoRaggio = Tema.Ombra.passoRaggioPrecalcolato
        var raggio = (max(0, raggio) / passoRaggio).rounded() * passoRaggio
        if let misura, misura.width > 0, misura.height > 0 {
            // Come RoundedRectangle: il raggio non supera metà del lato più corto (pillole)
            raggio = min(raggio, (min(misura.width, misura.height) / 2 / passoRaggio).rounded(.down) * passoRaggio)
        }
        let estensioni = Self.estensioni(raggio: raggio, strati: strati)
        let pieno = 2 * estensioni.interno + 2
        func lato(_ valore: CGFloat?) -> CGFloat {
            guard let valore, valore > 0, valore < pieno else { return pieno }
            let passo = Tema.Ombra.passoMisuraPrecalcolata
            return max(2, (valore / passo).rounded(.down) * passo)
        }
        let forma = CGSize(width: lato(misura?.width), height: lato(misura?.height))
        let nome = Self.chiave(raggio: raggio, strati: strati, scala: scala) + "#\(forma.width)x\(forma.height)"
        return Voce(chiave: nome, raggio: raggio, strati: strati, scala: scala, margine: estensioni.margine, forma: forma)
    }

    /// Tiene la bitmap appena disegnata; oltre il limite toglie le meno usate di recente.
    private static func conserva(_ pronta: Pronta, chiave: String) {
        while cache.count >= Tema.Ombra.limitePrecalcolate, !ordine.isEmpty {
            cache[ordine.removeFirst()] = nil
        }
        cache[chiave] = pronta
        ordine.append(chiave)
    }

    /// Le ombre a 9 fette che non dipendono dalla misura (finestre attive e inattive, normali e ingrandite;
    /// dettaglio), con la scala dello schermo: si sfocano una volta fuori dal thread principale, così la prima
    /// apertura, il primo ingrandimento e il primo dettaglio non le disegnano nel primo fotogramma del movimento.
    /// Dal thread principale (la chiama la shell all'avvio vero, mai nelle istantanee e nelle prove).
    @MainActor static func preparaShell() {
        #if os(macOS)
        let scala = NSScreen.main?.backingScaleFactor ?? 2
        var richieste: [(raggio: CGFloat, strati: [StratoOmbra])] = []
        for raggio in [Tema.Raggio.finestra, Tema.Raggio.finestraIngrandita] {
            richieste.append((raggio: raggio, strati: Tema.Ombra.finestra(attiva: true)))
            richieste.append((raggio: raggio, strati: Tema.Ombra.finestra(attiva: false)))
        }
        // L'ombra del dettaglio è la stessa in chiaro e in scuro
        richieste.append((raggio: Tema.Apple.Moto.DettaglioApre.raggioFinale,
                          strati: Tema.Apple.Ombra.dettaglio.strati(scuro: false)))
        prepara(richieste, scala: scala)
        #endif
    }

    /// Disegna fuori dal thread principale le bitmap a 9 fette che mancano. Fuori si disegna soltanto (solo
    /// CoreGraphics e immagini, colori RGB fissi): cache, ordine e conteggio si toccano solo qui sul principale.
    private static func prepara(_ richieste: [(raggio: CGFloat, strati: [StratoOmbra])], scala: CGFloat) {
        let voci = richieste.compactMap { voce(raggio: $0.raggio, strati: $0.strati, scala: scala, misura: nil) }
            .filter { cache[$0.chiave] == nil }
        guard !voci.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            let pronte = voci.map { v in (chiave: v.chiave, pronta: OmbraPrecalcolata.disegna(v)) }
            DispatchQueue.main.async {
                for p in pronte {
                    // Un body può averla già disegnata nel frattempo: resta quella
                    guard let pronta = p.pronta, OmbraPrecalcolata.cache[p.chiave] == nil else { continue }
                    OmbraPrecalcolata.disegnate += 1
                    OmbraPrecalcolata.conserva(pronta, chiave: p.chiave)
                }
            }
        }
    }

    /// Stessi strati, campo per campo (StratoOmbra non è Equatable).
    static func stessiStrati(_ a: [StratoOmbra], _ b: [StratoOmbra]) -> Bool {
        guard a.count == b.count else { return false }
        for (x, y) in zip(a, b) {
            if x.colore != y.colore || x.y != y.y || x.sfocatura != y.sfocatura || x.espansione != y.espansione {
                return false
            }
        }
        return true
    }

    private static func chiave(raggio: CGFloat, strati: [StratoOmbra], scala: CGFloat) -> String {
        var parti = ["\(raggio)@\(scala)"]
        for s in strati {
            #if os(macOS)
            let c = NSColor(s.colore).usingColorSpace(.sRGB) ?? NSColor.black
            let colore = [c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent].map { "\($0)" }
            #elseif os(iOS)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
            _ = UIColor(s.colore).getRed(&r, green: &g, blue: &b, alpha: &a)
            let colore = [r, g, b, a].map { "\($0)" }
            #endif
            parti.append("\(s.y),\(s.sfocatura),\(s.espansione)," + colore.joined(separator: ","))
        }
        return parti.joined(separator: "|")
    }

    /// Quanto esce l'ombra dalla forma (`margine`) e quanto entra nella forma ciò che dipende dagli angoli (`interno`).
    private static func estensioni(raggio: CGFloat, strati: [StratoOmbra]) -> (margine: CGFloat, interno: CGFloat) {
        var margine: CGFloat = 0
        var interno = max(0, raggio)
        for s in strati {
            let estensione = s.sfocatura * Tema.Ombra.estensionePrecalcolata
            let rientro = max(0, -s.espansione)
            margine = max(margine, estensione + abs(s.y))
            interno = max(interno, estensione + rientro + abs(s.y) + max(0, raggio - rientro))
        }
        return (margine.rounded(.up), interno.rounded(.up))
    }

    /// La forma al centro è grande abbastanza perché a metà di ogni lato l'ombra sia quella di un lato lungo:
    /// le fette d'angolo (`bordo`) contengono tutto ciò che dipende dagli angoli, il centro (2 pt) si stira.
    /// Un lato corto (`forma` più piccola della forma lunga) si disegna alla sua misura: lì si stirano solo 2 pt.
    /// Solo CoreGraphics e immagini: si può chiamare anche fuori dal thread principale (`prepara`).
    private static func disegna(_ v: Voce) -> Pronta? {
        let raggio = v.raggio
        let strati = v.strati
        let scala = v.scala
        let margine = v.margine
        let misuraForma = v.forma
        guard !strati.isEmpty else { return nil }
        let larghezza = misuraForma.width + 2 * margine
        let altezza = misuraForma.height + 2 * margine
        let pixelX = Int((larghezza * scala).rounded(.up))
        let pixelY = Int((altezza * scala).rounded(.up))
        guard pixelX > 0, pixelY > 0, let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: pixelX, height: pixelY, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: spazio, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                      | CGBitmapInfo.byteOrder32Big.rawValue)
        else { return nil }
        // Tutto in pixel: offset e sfocatura delle ombre di CoreGraphics non seguono la trasformazione corrente.
        // L'asse y di CoreGraphics va in su: la forma sta a `margine` dal bordo alto dell'immagine
        let forma = CGRect(x: margine * scala, y: CGFloat(pixelY) - (margine + misuraForma.height) * scala,
                           width: misuraForma.width * scala, height: misuraForma.height * scala)
        #if os(macOS)
        ctx.setFillColor(NSColor.black.cgColor)
        #elseif os(iOS)
        ctx.setFillColor(UIColor.black.cgColor)
        #endif
        for s in strati {
            // Come OmbreVetro: la forma rientra di -espansione (anche negli angoli) e l'ombra cade sotto di y
            let rientro = max(0, -s.espansione)
            let r = forma.insetBy(dx: rientro * scala, dy: rientro * scala)
            guard r.width > 0, r.height > 0 else { continue }
            #if os(macOS)
            let colore = NSColor(s.colore).usingColorSpace(.sRGB)?.cgColor ?? NSColor(s.colore).cgColor
            #elseif os(iOS)
            let colore = UIColor(s.colore).cgColor
            #endif
            ctx.saveGState()
            // L'asse y di CoreGraphics va in su: l'ombra «in giù» di SwiftUI ha l'offset negativo
            ctx.setShadow(offset: CGSize(width: 0, height: -s.y * scala),
                          blur: s.sfocatura * Tema.Ombra.fattoreSfocaturaPrecalcolata * scala, color: colore)
            ctx.addPath(percorso(r, raggio: max(0, raggio - rientro) * scala))
            ctx.fillPath()
            ctx.restoreGState()
        }
        // Il buco: sotto il vetro nessuna ombra (toglie anche il nero delle forme, che stanno tutte dentro)
        ctx.setBlendMode(.clear)
        ctx.addPath(percorso(forma, raggio: raggio * scala))
        ctx.fillPath()
        guard let cg = ctx.makeImage() else { return nil }
        #if os(macOS)
        let punti = NSSize(width: CGFloat(pixelX) / scala, height: CGFloat(pixelY) / scala)
        let rep = NSBitmapImageRep(cgImage: cg)
        rep.size = punti
        let immagine = NSImage(size: punti)
        immagine.addRepresentation(rep)
        #elseif os(iOS)
        // UIImage porta da sé la scala: punti = pixel / scala, come la bitmap del Mac
        let immagine = UIImage(cgImage: cg, scale: scala, orientation: .up)
        #endif
        // Le fette: tutto meno i 2 pt centrali di ogni lato (in punti dell'immagine)
        let latoX = CGFloat(pixelX) / scala
        let latoY = CGFloat(pixelY) / scala
        return Pronta(immagine: immagine, margine: margine,
                      bordo: max(0, (latoX - 2) / 2), bordoAlto: max(0, (latoY - 2) / 2))
    }

    /// Lo stesso rettangolo ad angoli continui di FormaVetro (simmetrico: l'asse y capovolto non conta).
    private static func percorso(_ r: CGRect, raggio: CGFloat) -> CGPath {
        RoundedRectangle(cornerRadius: raggio, style: .continuous).path(in: r).cgPath
    }
}

/// Al posto di OmbreVetro: la bitmap pronta, stirata alla misura della forma.
/// `misuraEsatta` (di solito): legge la misura della forma, così i lati corti (riquadri bassi, pillole) hanno
/// l'ombra giusta. Senza (finestre, dettaglio che cresce): la bitmap non cambia mai con la misura.
struct OmbraVetroPronta: View, Equatable {
    let raggio: CGFloat
    let strati: [StratoOmbra]
    let misuraEsatta: Bool
    @Environment(\.displayScale) private var scala

    init(raggio: CGFloat, strati: [StratoOmbra], misuraEsatta: Bool = true) {
        self.raggio = raggio
        self.strati = strati
        self.misuraEsatta = misuraEsatta
    }

    /// Gli strati arrivano in un array nuovo a ogni body di chi la usa (anche a ogni fotogramma del dettaglio e
    /// dell'inclinazione): a parità di raggio e strati il body non si rifà e la chiave non si ricostruisce.
    /// La scala dello schermo (ambiente) e la misura (GeometryReader) la aggiornano comunque.
    nonisolated static func == (a: OmbraVetroPronta, b: OmbraVetroPronta) -> Bool {
        a.raggio == b.raggio && a.misuraEsatta == b.misuraEsatta && OmbraPrecalcolata.stessiStrati(a.strati, b.strati)
    }

    var body: some View {
        Group {
            if misuraEsatta {
                GeometryReader { geo in
                    immagine(misura: geo.size)
                }
            } else {
                immagine(misura: nil)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func immagine(misura: CGSize?) -> some View {
        if let pronta = OmbraPrecalcolata.ombra(raggio: raggio, strati: strati, scala: scala, misura: misura) {
            Image(piattaforma: pronta.immagine)
                .resizable(capInsets: EdgeInsets(top: pronta.bordoAlto, leading: pronta.bordo,
                                                 bottom: pronta.bordoAlto, trailing: pronta.bordo),
                           resizingMode: .stretch)
                .padding(-pronta.margine)
        }
    }
}
