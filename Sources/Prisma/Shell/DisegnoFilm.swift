#if os(macOS)
import AppKit
#else
import UIKit
#endif
import CoreGraphics
import CoreText
import SwiftUI

// Il disegno del film del piano («Luce» giro 15, §3.2.3): un solo disegno per anteprima, video e istantanee. È una
// funzione pura del tempo (niente animazioni di SwiftUI, niente Timer) in Core Graphics e Core Text, utilizzabile fuori
// dal thread principale (la codifica del video gira su una coda propria). SwiftUI serve solo per il tracciato vettoriale
// del logo (`GeometriaLogo.tracciato(_:in:)`, un valore). Il contesto ha **l'origine in alto a sinistra** (y verso il
// basso): `Canvas.withCGContext` lo è già, `RegistaFilm` capovolge il pixel buffer prima di chiamare il disegno; il testo
// si scrive con `textMatrix = (1, −1)`. Tutte le misure in punti del film (880×495), scalate alla dimensione chiesta.

enum DisegnoFilm {
    typealias F = Tema.Apple.SalaRacconti.Film
    typealias M = Tema.Apple.Moto.Film

    static let formato = F.formato

    // MARK: Il film all'istante

    /// Il fotogramma all'istante `tempo` del film, con la dissolvenza incrociata fra le scene (0,30 s; 0,15 da fermo).
    static func disegna(in ctx: CGContext, dimensione: CGSize, tempo: Double, dati: DatiFilm, fermo: Bool = false) {
        let (k, t) = MotoreFilm.scena(al: tempo, dati)
        guard dati.scene.indices.contains(k) else { return }
        let dissolvenza = fermo ? M.dissolvenzaCalma : M.dissolvenzaScene
        ctx.saveGState()
        scala(ctx, dimensione)
        fondo(ctx)
        if k > 0, t < dissolvenza {
            let p = t / dissolvenza
            let prima = dati.scene[k - 1]
            strato(ctx, alfa: 1 - p) { contenuto(ctx, scena: prima, t: dati.durate[k - 1], dati: dati, fermo: fermo) }
            strato(ctx, alfa: p) { contenuto(ctx, scena: dati.scene[k], t: t, dati: dati, fermo: fermo) }
        } else {
            contenuto(ctx, scena: dati.scene[k], t: t, dati: dati, fermo: fermo)
        }
        angoloDatiDiProva(ctx, dati)
        ctx.restoreGState()
    }

    /// Il fotogramma all'istante `t` della scena `scena`, senza dissolvenza (istantanee e fotogrammi delle anteprime).
    static func disegna(in ctx: CGContext, dimensione: CGSize, scena: ScenaFilm, t: Double, dati: DatiFilm, fermo: Bool = false) {
        ctx.saveGState()
        scala(ctx, dimensione)
        fondo(ctx)
        contenuto(ctx, scena: scena, t: t, dati: dati, fermo: fermo)
        angoloDatiDiProva(ctx, dati)
        ctx.restoreGState()
    }

    /// Il carattere di sistema con il peso dato (numero di `PesoFilm`).
    static func carattere(_ dimensione: CGFloat, peso: CGFloat) -> CTFont {
        #if os(macOS)
        return NSFont.systemFont(ofSize: dimensione, weight: NSFont.Weight(rawValue: peso)) as CTFont
        #else
        return UIFont.systemFont(ofSize: dimensione, weight: UIFont.Weight(rawValue: peso)) as CTFont
        #endif
    }

    // MARK: Fondo, scala, strati

    private static func scala(_ ctx: CGContext, _ dimensione: CGSize) {
        let s = min(dimensione.width / formato.width, dimensione.height / formato.height)
        let dx = (dimensione.width - formato.width * s) / 2
        let dy = (dimensione.height - formato.height * s) / 2
        ctx.translateBy(x: dx, y: dy)
        ctx.scaleBy(x: s, y: s)
    }

    private static func fondo(_ ctx: CGContext) {
        let rect = CGRect(origin: .zero, size: formato)
        ctx.setFillColor(colore(F.fondoBordo))
        ctx.fill(rect)
        let spazio = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let gradiente = CGGradient(colorsSpace: spazio, colors: [colore(F.fondoCentro), colore(F.fondoBordo)] as CFArray,
                                         locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.clip(to: rect)
        ctx.translateBy(x: formato.width * F.centroFondo.x, y: formato.height * F.centroFondo.y)
        ctx.scaleBy(x: 1, y: F.raggiFondo.height / F.raggiFondo.width)
        ctx.drawRadialGradient(gradiente, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: F.raggiFondo.width,
                               options: [.drawsAfterEndLocation])
        ctx.restoreGState()
    }

    /// Un gruppo disegnato con un'opacità comune (strato di trasparenza: gli elementi non si vedono attraverso).
    private static func strato(_ ctx: CGContext, alfa: Double, _ disegno: () -> Void) {
        guard alfa > 0.001 else { return }
        // Già del tutto visibile: niente strato (ogni strato costa un fotogramma intero in memoria)
        if alfa >= 0.999 {
            disegno()
            return
        }
        ctx.saveGState()
        ctx.setAlpha(CGFloat(min(1, alfa)))
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        disegno()
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    /// Un elemento che entra (`.fA`): opacità, 24 pt dal basso e scala 0,97 attorno al suo centro, curva `uscita`.
    private static func entrata(_ ctx: CGContext, indice: Int, t: Double, fermo: Bool, centro: CGPoint, _ disegno: () -> Void) {
        let p = fermo ? 1 : progresso(t, ritardo: Double(indice) * M.Elemento.passo, durata: M.Elemento.durata, curva: uscita)
        guard p > 0.001 else { return }
        if p >= 0.999 {
            disegno()
            return
        }
        ctx.saveGState()
        ctx.translateBy(x: centro.x, y: centro.y + M.Elemento.spostamento * CGFloat(1 - p))
        let s = M.Elemento.scala + (1 - M.Elemento.scala) * CGFloat(p)
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -centro.x, y: -centro.y)
        ctx.setAlpha(CGFloat(p))
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        disegno()
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    // MARK: Le scene

    private static func contenuto(_ ctx: CGContext, scena: ScenaFilm, t: Double, dati: DatiFilm, fermo: Bool) {
        switch scena {
        case .titolo: scenaTitolo(ctx, t: t, dati: dati, fermo: fermo)
        case .oggi: scenaOggi(ctx, t: t, dati: dati, fermo: fermo)
        case .ogniMese: scenaOgniMese(ctx, t: t, dati: dati, fermo: fermo)
        case .futuro: scenaFuturo(ctx, t: t, dati: dati, fermo: fermo)
        case .chiusura: scenaChiusura(ctx, t: t, dati: dati, fermo: fermo)
        }
        sottotitolo(ctx, TestiFilm.sottotitolo(scena), t: t, fermo: fermo)
    }

    private static func scenaTitolo(_ ctx: CGContext, t: Double, dati: DatiFilm, fermo: Bool) {
        let titolo = riga(dati.titolo, F.titolo)
        let data = riga(dati.data, F.data)
        let altezza = F.logo + F.sottoLogo + titolo.altezza + F.sottoTitolo + data.altezza
        var y = (formato.height - altezza) / 2
        let cx = formato.width / 2
        let rettLogo = CGRect(x: cx - F.logo / 2, y: y, width: F.logo, height: F.logo)
        entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: cx, y: rettLogo.midY)) { logo(ctx, in: rettLogo) }
        y += F.logo + F.sottoLogo
        let yTitolo = y
        entrata(ctx, indice: 1, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yTitolo + titolo.altezza / 2)) {
            scrivi(ctx, titolo, x: cx - titolo.larghezza / 2, alto: yTitolo, testo: F.titolo)
        }
        y += titolo.altezza + F.sottoTitolo
        let yData = y
        entrata(ctx, indice: 2, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yData + data.altezza / 2)) {
            scrivi(ctx, data, x: cx - data.larghezza / 2, alto: yData, testo: F.data)
        }
    }

    private static func scenaOggi(_ ctx: CGContext, t: Double, dati: DatiFilm, fermo: Bool) {
        let occhiello = riga(TestiFilm.occhielloOggi, F.occhiello)
        let obiettivi = dati.obiettivi
        guard !obiettivi.isEmpty else { return }
        let nomi = obiettivi.map { righe($0.nome, F.nomeObiettivo, larghezza: F.larghezzaNome, massimo: 2) }
        let altezzaNomi = nomi.map { $0.reduce(0) { $0 + $1.altezza } }.max() ?? 0
        let altezza = occhiello.altezza + F.sottoOcchiello + F.anello + F.sottoAnello + altezzaNomi
        let cx = formato.width / 2
        let y0 = (formato.height - altezza) / 2 - F.sottoSottotitolo
        entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: cx, y: y0 + occhiello.altezza / 2)) {
            scrivi(ctx, occhiello, x: cx - occhiello.larghezza / 2, alto: y0, testo: F.occhiello)
        }
        let yAnelli = y0 + occhiello.altezza + F.sottoOcchiello
        let n = CGFloat(obiettivi.count)
        let larghezzaRiga = n * F.anello + (n - 1) * F.spazioAnelli
        for (i, o) in obiettivi.enumerated() {
            let x = cx - larghezzaRiga / 2 + CGFloat(i) * (F.anello + F.spazioAnelli)
            let centro = CGPoint(x: x + F.anello / 2, y: yAnelli + F.anello / 2)
            let p = fermo ? 1 : progresso(t, ritardo: M.anello.ritardo + Double(i) * M.anello.passo, durata: M.anello.durata, curva: uscita)
            entrata(ctx, indice: 1, t: t, fermo: fermo, centro: centro) {
                anello(ctx, centro: centro, quota: o.quota * p, colore: o.colore)
                let pct = riga(TestiFilm.percentuale(o.quota * p), F.percentuale)
                scrivi(ctx, pct, x: centro.x - pct.larghezza / 2, alto: centro.y - pct.altezza / 2, testo: F.percentuale)
                var yNome = yAnelli + F.anello + F.sottoAnello
                for r in nomi[i] {
                    scrivi(ctx, r, x: centro.x - r.larghezza / 2, alto: yNome, testo: F.nomeObiettivo)
                    yNome += r.altezza
                }
            }
        }
    }

    private static func scenaOgniMese(_ ctx: CGContext, t: Double, dati: DatiFilm, fermo: Bool) {
        let occhiello = riga(TestiFilm.occhielloOgniMese, F.occhiello)
        let cx = formato.width / 2
        let rigaPensione = dati.pensione.map { riga(TestiFilm.pensione($0), F.pensione) }
        if let v = dati.versamento {
            let finale = riga(Formati.euro(v.cifra), F.cifraMese)
            let per = riga(TestiFilm.perObiettivo(v.obiettivo), F.perObiettivo)
            let altezza = occhiello.altezza + F.sottoOcchielloCifra + finale.altezza + per.altezza
                + (rigaPensione.map { F.sottoPerObiettivo + $0.altezza } ?? 0)
            var y = (formato.height - altezza) / 2 - F.sottoSottotitolo
            let yOcchiello = y
            entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yOcchiello + occhiello.altezza / 2)) {
                scrivi(ctx, occhiello, x: cx - occhiello.larghezza / 2, alto: yOcchiello, testo: F.occhiello)
            }
            y += occhiello.altezza + F.sottoOcchielloCifra
            let yCifra = y
            // La cifra si conta da 0 (quartica, 1,1 s) mentre entra
            let ritardo = Double(1) * M.Elemento.passo
            let q = fermo ? 1 : Tema.Apple.Moto.Curva.quartica(max(0, t - ritardo) / M.numero)
            let contata = riga(Formati.euro(v.cifra * q), F.cifraMese)
            entrata(ctx, indice: 1, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yCifra + finale.altezza / 2)) {
                scrivi(ctx, contata, x: cx - contata.larghezza / 2, alto: yCifra, testo: F.cifraMese)
            }
            y += finale.altezza
            let yPer = y
            entrata(ctx, indice: 2, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yPer + per.altezza / 2)) {
                scrivi(ctx, per, x: cx - per.larghezza / 2, alto: yPer, testo: F.perObiettivo)
            }
            y += per.altezza + F.sottoPerObiettivo
            if let r = rigaPensione {
                let yPensione = y
                let a = fermo ? 1 : progresso(t, ritardo: M.secondo.ritardo, durata: M.secondo.durata, curva: ease)
                strato(ctx, alfa: a) {
                    scrivi(ctx, r, x: cx - r.larghezza / 2, alto: yPensione, testo: F.pensione, colore: F.lavanda)
                }
            }
        } else if let r = rigaPensione {
            // Senza versamenti resta solo la pensione
            let altezza = occhiello.altezza + F.sottoOcchielloCifra + r.altezza
            let y = (formato.height - altezza) / 2 - F.sottoSottotitolo
            entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: cx, y: y + occhiello.altezza / 2)) {
                scrivi(ctx, occhiello, x: cx - occhiello.larghezza / 2, alto: y, testo: F.occhiello)
            }
            let yPensione = y + occhiello.altezza + F.sottoOcchielloCifra
            entrata(ctx, indice: 1, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yPensione + r.altezza / 2)) {
                scrivi(ctx, r, x: cx - r.larghezza / 2, alto: yPensione, testo: F.pensione, colore: F.lavanda)
            }
        }
    }

    private static func scenaFuturo(_ ctx: CGContext, t: Double, dati: DatiFilm, fermo: Bool) {
        let occhiello = riga(TestiFilm.occhielloFuturo, F.occhiello)
        let o = F.occhielloFuturo
        entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: o.x + occhiello.larghezza / 2, y: o.y + occhiello.altezza / 2)) {
            scrivi(ctx, occhiello, x: o.x, alto: o.y, testo: F.occhiello)
        }
        let curva = dati.curva
        guard curva.count >= 2 else { return }
        let punti = curva.indices.map { GeometriaFilm.punto($0, di: curva) }
        let p = fermo ? 1 : progresso(t, ritardo: M.linea.ritardo, durata: M.linea.durata, curva: uscita)
        // La curva si disegna da sinistra fino alla frazione `p`
        let fine = Double(punti.count - 1) * p
        let intero = Int(fine)
        let path = CGMutablePath()
        path.move(to: punti[0])
        if intero >= 1 { for i in 1...min(intero, punti.count - 1) { path.addLine(to: punti[i]) } }
        if intero < punti.count - 1 {
            let f = CGFloat(fine - Double(intero))
            let a = punti[intero], b = punti[intero + 1]
            path.addLine(to: CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
        }
        if p > 0.001 {
            ctx.saveGState()
            ctx.addPath(path)
            ctx.setStrokeColor(colore(F.lavanda))
            ctx.setLineWidth(F.spessoreCurva)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
            ctx.restoreGState()
        }
        // L'arrivo all'obiettivo (punto bianco) quando la curva ci è passata; l'etichetta dentro l'area
        if let a = dati.arrivo, punti.indices.contains(a.indice), fine >= Double(a.indice) {
            let pt = punti[a.indice]
            let alfa = fermo ? 1 : progresso(t, ritardo: M.secondo.ritardo, durata: M.secondo.durata, curva: ease)
            strato(ctx, alfa: alfa) {
                punto(ctx, pt, colore: F.testo)
                let r = riga(a.testo, F.etichettaPunto)
                let x = GeometriaFilm.sinistraEtichetta(centro: pt.x, larghezza: r.larghezza)
                let alto = max(F.areaCurva.minY - r.altezza, pt.y - F.sopraEtichettaPunto - r.altezza)
                scrivi(ctx, r, x: x, alto: alto, testo: F.etichettaPunto)
            }
        }
        // Il punto finale con la cifra in euro di oggi
        if let f = dati.fine, p >= 0.999, let pt = punti.last {
            let alfa = fermo ? 1 : progresso(t, ritardo: M.terzo.ritardo, durata: M.terzo.durata, curva: ease)
            strato(ctx, alfa: alfa) {
                punto(ctx, pt, colore: F.lavanda)
                let r = riga(TestiFilm.fine(eta: f.eta, valore: f.valore), F.etichettaFine)
                let x = GeometriaFilm.sinistraEtichettaFine(punto: pt.x, larghezza: r.larghezza)
                let alto = max(F.areaCurva.minY - r.altezza, pt.y - F.lontanoEtichettaFine - r.altezza)
                scrivi(ctx, r, x: x, alto: alto, testo: F.etichettaFine)
            }
        }
    }

    private static func scenaChiusura(_ ctx: CGContext, t: Double, dati: DatiFilm, fermo: Bool) {
        let chiusura = riga(TestiFilm.chiusura, F.chiusura)
        let firme = dati.firme.map { riga($0.testo, F.firma) }
        let avvertenza = righe(dati.avvertenza, F.avvertenza, larghezza: F.larghezzaAvvertenza, massimo: 4)
        let altezzaFirme = firme.reduce(0) { $0 + $1.altezza } + CGFloat(max(0, firme.count - 1)) * F.spazioFirme
        let altezzaAvvertenza = avvertenza.reduce(0) { $0 + $1.altezza }
        let altezza = chiusura.altezza + F.sottoChiusura + altezzaFirme + F.sopraAvvertenza + altezzaAvvertenza
        let cx = formato.width / 2
        var y = (formato.height - altezza) / 2
        let yChiusura = y
        entrata(ctx, indice: 0, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yChiusura + chiusura.altezza / 2)) {
            scrivi(ctx, chiusura, x: cx - chiusura.larghezza / 2, alto: yChiusura, testo: F.chiusura)
        }
        y += chiusura.altezza + F.sottoChiusura
        let yFirme = y
        entrata(ctx, indice: 1, t: t, fermo: fermo, centro: CGPoint(x: cx, y: yFirme + altezzaFirme / 2)) {
            var yf = yFirme
            for (i, r) in firme.enumerated() {
                // Il nome del canale nel suo colore sul fondo scuro (decisione 57), mai il logo
                let c = dati.firme[i].colore
                scrivi(ctx, r, x: cx - r.larghezza / 2, alto: yf, testo: F.firma, colore: c ?? F.testo, opacita: c == nil ? nil : 1)
                yf += r.altezza + F.spazioFirme
            }
        }
        y += altezzaFirme + F.sopraAvvertenza
        let yAvvertenza = y
        let a = fermo ? 1 : progresso(t, ritardo: M.secondo.ritardo, durata: M.secondo.durata, curva: ease)
        strato(ctx, alfa: a) {
            var ya = yAvvertenza
            for r in avvertenza {
                scrivi(ctx, r, x: cx - r.larghezza / 2, alto: ya, testo: F.avvertenza)
                ya += r.altezza
            }
        }
    }

    private static func sottotitolo(_ ctx: CGContext, _ testo: String, t: Double, fermo: Bool) {
        guard !testo.isEmpty else { return }
        let r = riga(testo, F.sottotitolo)
        let a = fermo ? 1 : progresso(t, ritardo: M.sottotitolo.ritardo, durata: M.sottotitolo.durata, curva: ease)
        guard a > 0.001 else { return }
        ctx.saveGState()
        ctx.setAlpha(CGFloat(a))
        // Ombra 0 2 8 nera al 60%: lo spostamento dell'ombra è nello spazio del dispositivo (y verso l'alto)
        let s = ctx.ctm.a
        ctx.setShadow(offset: CGSize(width: 0, height: -F.ombraSottotitolo.y * abs(s)), blur: F.ombraSottotitolo.raggio * abs(s),
                      color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: CGFloat(F.ombraSottotitolo.opacita)))
        scrivi(ctx, r, x: (formato.width - r.larghezza) / 2, alto: formato.height - F.sottoSottotitolo - r.altezza, testo: F.sottotitolo)
        ctx.restoreGState()
    }

    private static func angoloDatiDiProva(_ ctx: CGContext, _ dati: DatiFilm) {
        guard dati.diProva else { return }
        let r = riga(TestiFilm.datiDiProva, F.datiDiProva)
        scrivi(ctx, r, x: formato.width - F.angoloDatiDiProva.x - r.larghezza, alto: F.angoloDatiDiProva.y, testo: F.datiDiProva)
    }

    // MARK: Forme

    private static func logo(_ ctx: CGContext, in rect: CGRect) {
        let spicchi = [GeometriaLogo.sinistra, GeometriaLogo.destra, GeometriaLogo.base]
        for (i, s) in spicchi.enumerated() {
            let opacita = F.opacitaSpicchi.indices.contains(i) ? F.opacitaSpicchi[i] : 1
            ctx.addPath(GeometriaLogo.tracciato(s, in: rect).cgPath)
            ctx.setFillColor(colore(F.testo, alfa: opacita))
            ctx.fillPath()
        }
    }

    private static func anello(_ ctx: CGContext, centro: CGPoint, quota: Double, colore c: ColoreFilm) {
        let raggio = (F.anello - F.spessoreAnello) / 2
        ctx.saveGState()
        ctx.setLineWidth(F.spessoreAnello)
        ctx.setStrokeColor(colore(F.testo, alfa: F.opacitaBinarioAnello))
        ctx.addArc(center: centro, radius: raggio, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()
        let q = min(max(quota, 0), 1)
        if q > 0.001 {
            // In un contesto con y verso il basso gli angoli crescenti girano in senso orario sullo schermo
            let inizio = -CGFloat.pi / 2
            ctx.setLineCap(.round)
            ctx.setStrokeColor(colore(c))
            ctx.addArc(center: centro, radius: raggio, startAngle: inizio, endAngle: inizio + .pi * 2 * CGFloat(q), clockwise: false)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private static func punto(_ ctx: CGContext, _ p: CGPoint, colore c: ColoreFilm) {
        ctx.setFillColor(colore(c))
        ctx.fillEllipse(in: CGRect(x: p.x - F.puntoCurva, y: p.y - F.puntoCurva, width: F.puntoCurva * 2, height: F.puntoCurva * 2))
    }

    // MARK: Testo (Core Text)

    /// Una riga composta: la linea di Core Text con le sue misure.
    struct Riga {
        let linea: CTLine
        let larghezza: CGFloat
        let ascesa: CGFloat
        let discesa: CGFloat
        /// L'altezza della riga: l'interlinea del gradino o ascesa + discesa.
        let altezza: CGFloat
    }

    private static func font(_ t: TestoFilm) -> CTFont {
        let base = carattere(t.dimensione, peso: t.peso)
        guard t.tabellare else { return base }
        // Cifre tabellari: kNumberSpacingType (6) / kMonospacedNumbersSelector (0)
        let impostazioni: [[CFString: Any]] = [[kCTFontFeatureTypeIdentifierKey: 6, kCTFontFeatureSelectorIdentifierKey: 0]]
        let attributi: [CFString: Any] = [kCTFontFeatureSettingsAttribute: impostazioni]
        let descrittore = CTFontDescriptorCreateWithAttributes(attributi as CFDictionary)
        return CTFontCreateCopyWithAttributes(base, 0, nil, descrittore)
    }

    private static func attribuito(_ s: String, _ t: TestoFilm) -> NSAttributedString {
        let attributi: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font(t),
            NSAttributedString.Key(kCTKernAttributeName as String): t.tracking,
            // Il colore lo dà il contesto (`setFillColor` prima di scrivere)
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        return NSAttributedString(string: s, attributes: attributi)
    }

    private static func misura(_ linea: CTLine, _ t: TestoFilm) -> Riga {
        var ascesa: CGFloat = 0, discesa: CGFloat = 0, interlinea: CGFloat = 0
        let larghezza = CGFloat(CTLineGetTypographicBounds(linea, &ascesa, &discesa, &interlinea))
        let naturale = ascesa + discesa
        let altezza = t.interlinea.map { max(naturale, t.dimensione * $0) } ?? naturale
        // La spaziatura dopo l'ultima lettera non conta nella larghezza da centrare
        return Riga(linea: linea, larghezza: max(0, larghezza - max(0, t.tracking)), ascesa: ascesa, discesa: discesa, altezza: altezza)
    }

    static func riga(_ s: String, _ t: TestoFilm) -> Riga {
        misura(CTLineCreateWithAttributedString(attribuito(s, t)), t)
    }

    /// Il testo a capo dentro `larghezza` (al più `massimo` righe; l'ultima finisce con «…» se il testo è più lungo).
    static func righe(_ s: String, _ t: TestoFilm, larghezza: CGFloat, massimo: Int) -> [Riga] {
        let a = attribuito(s, t)
        let tipografo = CTTypesetterCreateWithAttributedString(a)
        let lunghezza = a.length
        var inizio = 0
        var risultato: [Riga] = []
        while inizio < lunghezza && risultato.count < max(1, massimo) {
            var quante = CTTypesetterSuggestLineBreak(tipografo, inizio, Double(larghezza))
            if quante <= 0 { quante = lunghezza - inizio }
            let ultima = risultato.count == max(1, massimo) - 1 && inizio + quante < lunghezza
            var linea = CTTypesetterCreateLine(tipografo, CFRange(location: inizio, length: quante))
            if ultima {
                let resto = a.attributedSubstring(from: NSRange(location: inizio, length: lunghezza - inizio))
                let intera = CTLineCreateWithAttributedString(resto)
                let puntini = CTLineCreateWithAttributedString(attribuito("…", t))
                linea = CTLineCreateTruncatedLine(intera, Double(larghezza), .end, puntini) ?? linea
            }
            risultato.append(misura(linea, t))
            inizio += quante
        }
        return risultato
    }

    /// Scrive una riga con il bordo sinistro `x` e la cima `alto` (contesto con y verso il basso).
    private static func scrivi(_ ctx: CGContext, _ r: Riga, x: CGFloat, alto: CGFloat, testo t: TestoFilm,
                               colore c: ColoreFilm = F.testo, opacita: Double? = nil) {
        ctx.saveGState()
        ctx.setFillColor(colore(c, alfa: opacita ?? t.opacita))
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        let spazio = (r.altezza - r.ascesa - r.discesa) / 2
        ctx.textPosition = CGPoint(x: x, y: alto + spazio + r.ascesa)
        CTLineDraw(r.linea, ctx)
        ctx.restoreGState()
    }

    // MARK: Tempo e colori

    private static let uscita = Tema.Apple.Moto.Curva.uscita
    private static let ease = Tema.Apple.Moto.Curva.ease

    /// Il progresso 0…1 di un movimento che parte dopo `ritardo` e dura `durata`, con la curva data.
    static func progresso(_ t: Double, ritardo: Double, durata: Double, curva c: Tema.Apple.Moto.Curva) -> Double {
        guard durata > 0 else { return t >= ritardo ? 1 : 0 }
        let x = min(max((t - ritardo) / durata, 0), 1)
        return CurveGenio.bezier(x, (c.x1, c.y1, c.x2, c.y2))
    }

    static func colore(_ c: ColoreFilm, alfa: Double = 1) -> CGColor {
        CGColor(srgbRed: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: CGFloat(min(max(alfa, 0), 1)))
    }
}
