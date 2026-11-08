import Foundation
import CoreGraphics
import CoreText
import PDFKit
#if os(macOS)
import AppKit
/// Il carattere di PDFKit (NSFont sul Mac, UIFont su iPhone e iPad).
typealias PDFFontPlatform = NSFont
#else
import UIKit
typealias PDFFontPlatform = UIFont
#endif

// I moduli fac-simile di Prisma (Pratiche › Moduli, «Luce» giro 10, decisione 61): due pagine A4 disegnate da Prisma
// stesso, con la scritta «FAC-SIMILE» di traverso e i testi di prova, mai copiate da un modulo vero di una compagnia o di
// un intermediario. Servono alle prove (riconoscimento e compilazione), alle istantanee e ai clienti di prova di
// Impostazioni › Strumenti. Con `compilabile` i campi sono AcroForm (widget di testo con il loro nome); senza, il PDF è
// piatto e Prisma riconosce le etichette con le regole.

enum FacSimileModulo {
    /// Una casella del fac-simile: etichetta, quante colonne (su 4) e altezza.
    struct Casella {
        let etichetta: String
        let nome: String
        let colonne: Int
        var firma = false
    }

    struct Sezione {
        let titolo: String
        let righe: [[Casella]]
    }

    struct Pagina {
        let occhiello: String
        let titolo: String
        let sezioni: [Sezione]
    }

    // MARK: I due fac-simile

    /// «Proposta di polizza · fac-simile»: i 15 campi del template e le due firme.
    static let proposta = Pagina(
        occhiello: "PROPOSTA DI POLIZZA · FAC-SIMILE",
        titolo: "Proposta di polizza",
        sezioni: [
            Sezione(titolo: "IL CONTRAENTE", righe: [
                [Casella(etichetta: "Cognome", nome: "cognome", colonne: 2), Casella(etichetta: "Nome", nome: "nome", colonne: 2)],
                [Casella(etichetta: "Codice fiscale", nome: "codice_fiscale", colonne: 2),
                 Casella(etichetta: "Data di nascita", nome: "data_nascita", colonne: 1),
                 Casella(etichetta: "Luogo di nascita", nome: "luogo_nascita", colonne: 1)],
                [Casella(etichetta: "Indirizzo", nome: "indirizzo", colonne: 2), Casella(etichetta: "CAP", nome: "cap", colonne: 1),
                 Casella(etichetta: "Comune", nome: "comune", colonne: 1)],
                [Casella(etichetta: "Telefono", nome: "telefono", colonne: 2), Casella(etichetta: "Email", nome: "email", colonne: 2)],
                [Casella(etichetta: "Professione", nome: "professione", colonne: 2),
                 Casella(etichetta: "Beneficiari", nome: "beneficiari", colonne: 2)],
                [Casella(etichetta: "Premio", nome: "premio", colonne: 2), Casella(etichetta: "Decorrenza", nome: "decorrenza", colonne: 2)],
                [Casella(etichetta: "IBAN per l'addebito", nome: "iban", colonne: 4)],
            ]),
            Sezione(titolo: "FIRME", righe: [
                [Casella(etichetta: "Firma del contraente", nome: "firma_contraente", colonne: 2, firma: true),
                 Casella(etichetta: "Firma del consulente", nome: "firma_consulente", colonne: 2, firma: true)],
            ]),
        ])

    /// «Adeguata verifica · fac-simile»: l'anagrafica e il documento (che Prisma compila) e le dichiarazioni che dà il
    /// cliente (che Prisma non compila mai, decisione 62).
    static let adeguataVerifica = Pagina(
        occhiello: "ADEGUATA VERIFICA · FAC-SIMILE",
        titolo: "Adeguata verifica",
        sezioni: [
            Sezione(titolo: "IL CLIENTE", righe: [
                [Casella(etichetta: "Cognome", nome: "cognome", colonne: 2), Casella(etichetta: "Nome", nome: "nome", colonne: 2)],
                [Casella(etichetta: "Codice fiscale", nome: "codice_fiscale", colonne: 2),
                 Casella(etichetta: "Data di nascita", nome: "data_nascita", colonne: 1),
                 Casella(etichetta: "Luogo di nascita", nome: "luogo_nascita", colonne: 1)],
                [Casella(etichetta: "Tipo di documento", nome: "documento_tipo", colonne: 2),
                 Casella(etichetta: "Numero del documento", nome: "documento_numero", colonne: 2)],
                [Casella(etichetta: "Rilasciato il", nome: "documento_rilascio", colonne: 2),
                 Casella(etichetta: "Scadenza del documento", nome: "documento_scadenza", colonne: 2)],
            ]),
            Sezione(titolo: "DICHIARAZIONI DEL CLIENTE", righe: [
                [Casella(etichetta: "Titolare effettivo", nome: "titolare_effettivo", colonne: 4)],
                [Casella(etichetta: "Persona politicamente esposta", nome: "pep", colonne: 2),
                 Casella(etichetta: "Origine dei fondi", nome: "origine_fondi", colonne: 2)],
                [Casella(etichetta: "Scopo del rapporto", nome: "scopo_rapporto", colonne: 4)],
            ]),
            Sezione(titolo: "FIRME", righe: [
                [Casella(etichetta: "Firma del cliente", nome: "firma_cliente", colonne: 2, firma: true),
                 Casella(etichetta: "Firma del consulente", nome: "firma_consulente", colonne: 2, firma: true)],
            ]),
        ])

    static let piede = "Fac-simile di prova generato da Prisma: non è il modulo di nessuna compagnia. Testi di prova."
    static let versione = "fac-simile, ed. di prova"

    // MARK: Misure (punti PDF, A4)

    static let formato = CGSize(width: 595, height: 842)
    private static let margine: CGFloat = 46
    private static let alto: CGFloat = 44
    private static let spazioColonne: CGFloat = 10
    private static let altezzaEtichetta: CGFloat = 11
    private static let altezzaCasella: CGFloat = 24
    private static let altezzaFirma: CGFloat = 44
    private static let spazioRighe: CGFloat = 9

    private static let inchiostro = CGColor(srgbRed: 20 / 255, green: 32 / 255, blue: 43 / 255, alpha: 1)
    private static let grigio = CGColor(srgbRed: 90 / 255, green: 104 / 255, blue: 115 / 255, alpha: 1)
    private static let chiaro = CGColor(srgbRed: 122 / 255, green: 135 / 255, blue: 144 / 255, alpha: 1)
    private static let bordo = CGColor(srgbRed: 213 / 255, green: 220 / 255, blue: 226 / 255, alpha: 1)
    private static let filigrana = CGColor(srgbRed: 229 / 255, green: 72 / 255, blue: 77 / 255, alpha: 0.10)

    /// Le caselle con il loro riquadro (punti PDF, origine in basso a sinistra).
    static func riquadri(_ p: Pagina) -> [(casella: Casella, riquadro: CGRect, etichetta: CGPoint)] {
        let larghezza = formato.width - margine * 2
        let colonna = (larghezza - spazioColonne * 3) / 4
        var y = formato.height - alto - 76   // sotto occhiello e titolo
        var r: [(Casella, CGRect, CGPoint)] = []
        for s in p.sezioni {
            y -= 22   // la riga del titolo della sezione
            for riga in s.righe {
                var x = margine
                let alta = riga.contains(where: \.firma) ? altezzaFirma : altezzaCasella
                for c in riga {
                    let w = colonna * CGFloat(c.colonne) + spazioColonne * CGFloat(c.colonne - 1)
                    let etichetta = CGPoint(x: x, y: y - altezzaEtichetta + 3)
                    let riquadro = CGRect(x: x, y: y - altezzaEtichetta - alta, width: w, height: alta)
                    r.append((c, riquadro, etichetta))
                    x += w + spazioColonne
                }
                y -= altezzaEtichetta + alta + spazioRighe
            }
            y -= 10
        }
        return r
    }

    /// Le posizioni dei titoli di sezione.
    private static func titoliSezione(_ p: Pagina) -> [(String, CGFloat)] {
        var y = formato.height - alto - 76
        var r: [(String, CGFloat)] = []
        for s in p.sezioni {
            r.append((s.titolo, y - 12))
            y -= 22
            for riga in s.righe {
                y -= altezzaEtichetta + (riga.contains(where: \.firma) ? altezzaFirma : altezzaCasella) + spazioRighe
            }
            y -= 10
        }
        return r
    }

    // MARK: Il PDF

    /// Il PDF del fac-simile (una pagina). nil se il disegno non riesce.
    static func pdf(_ p: Pagina, compilabile: Bool = true) -> Data? {
        let dati = NSMutableData()
        guard let consumatore = CGDataConsumer(data: dati as CFMutableData) else { return nil }
        var box = CGRect(origin: .zero, size: formato)
        let info: [CFString: Any] = [kCGPDFContextTitle: "\(p.titolo) · fac-simile", kCGPDFContextCreator: "Prisma (fac-simile di prova)"]
        guard let ctx = CGContext(consumer: consumatore, mediaBox: &box, info as CFDictionary) else { return nil }
        ctx.beginPDFPage(nil)
        // La scritta di traverso
        ctx.saveGState()
        ctx.translateBy(x: formato.width / 2, y: formato.height / 2)
        ctx.rotate(by: .pi / 5)
        let fil = riga("FAC-SIMILE", 96, grassetto: true, colore: filigrana)
        let lf = CTLineGetTypographicBounds(fil, nil, nil, nil)
        ctx.textPosition = CGPoint(x: -lf / 2, y: -30)
        CTLineDraw(fil, ctx)
        ctx.restoreGState()
        // Occhiello, titolo e la nota in alto a destra
        scrivi(p.occhiello, 8.5, grassetto: true, colore: grigio, a: CGPoint(x: margine, y: formato.height - alto - 8), ctx)
        scrivi(p.titolo, 24, grassetto: true, colore: inchiostro, a: CGPoint(x: margine, y: formato.height - alto - 40), ctx)
        let nota = riga("Fac-simile generato da Prisma · pagina 1 di 1", 7.5, grassetto: false, colore: chiaro)
        let ln = CTLineGetTypographicBounds(nota, nil, nil, nil)
        ctx.textPosition = CGPoint(x: formato.width - margine - ln, y: formato.height - alto - 8)
        CTLineDraw(nota, ctx)
        for (t, y) in titoliSezione(p) {
            scrivi(t, 8.5, grassetto: true, colore: grigio, a: CGPoint(x: margine, y: y), ctx)
        }
        // Le caselle con le etichette sopra
        ctx.setStrokeColor(bordo)
        ctx.setLineWidth(0.8)
        for (c, r, e) in riquadri(p) {
            scrivi(c.etichetta.uppercased(), 7, grassetto: true, colore: chiaro, a: e, ctx)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 4, cornerHeight: 4, transform: nil))
            ctx.strokePath()
        }
        // Il piede con il filo sopra
        ctx.move(to: CGPoint(x: margine, y: 52))
        ctx.addLine(to: CGPoint(x: formato.width - margine, y: 52))
        ctx.strokePath()
        scrivi(piede, 7.5, grassetto: false, colore: chiaro, a: CGPoint(x: margine, y: 40), ctx)
        ctx.endPDFPage()
        ctx.closePDF()
        guard compilabile else { return dati as Data }
        // I campi compilabili (AcroForm): un widget di testo per casella, con il suo nome
        guard let documento = PDFDocument(data: dati as Data), let pagina = documento.page(at: 0) else { return nil }
        for (c, r, _) in riquadri(p) {
            let w = PDFAnnotation(bounds: r.insetBy(dx: 1, dy: 1), forType: .widget, withProperties: nil)
            w.widgetFieldType = .text
            w.fieldName = c.nome
            if let f = PDFFontPlatform(name: "Helvetica", size: 10) { w.font = f }
            pagina.addAnnotation(w)
        }
        return documento.dataRepresentation()
    }

    private static func riga(_ s: String, _ dimensione: CGFloat, grassetto: Bool, colore: CGColor) -> CTLine {
        let font = CTFontCreateWithName((grassetto ? "Helvetica-Bold" : "Helvetica") as CFString, dimensione, nil)
        let attributi: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): colore,
        ]
        return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributi))
    }

    private static func scrivi(_ s: String, _ dimensione: CGFloat, grassetto: Bool, colore: CGColor, a punto: CGPoint, _ ctx: CGContext) {
        ctx.textPosition = punto
        CTLineDraw(riga(s, dimensione, grassetto: grassetto, colore: colore), ctx)
    }
}
