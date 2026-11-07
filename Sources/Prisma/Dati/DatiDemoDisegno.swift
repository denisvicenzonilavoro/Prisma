import Foundation
import CoreGraphics

/// DATI DI PROVA (Design/template-luce-specifica.md §3.3.6, «Luce» giro 4): i tratti fissi di «Disegna il tuo futuro»
/// per le istantanee, come se li avesse disegnati Giulia con il mouse. Punti 0…1 nell'area del grafico: x = età da oggi
/// a 90 anni, y = patrimonio da 0 al massimo dell'asse (2,1 volte il massimo del piano), con un piccolo tremolio della
/// mano. Non sono dati di nessun cliente: servono solo a mostrare la tela.
enum DisegnoDiProva {
    /// Un tremolio fisso, sempre lo stesso (niente numeri casuali: istantanee riproducibili).
    private static func tremolio(_ i: Int) -> Double { sin(Double(i) * 1.7) * 0.006 + sin(Double(i) * 0.6) * 0.004 }

    /// Un tratto che sale ben sopra il piano e resta alto: «servono circa … € in più al mese».
    static let sopraIlPiano: [CGPoint] = (0...25).map { i in
        let x = Double(i) / 25
        let salita = 1 / (1 + exp(-(x - 0.38) * 9))
        return CGPoint(x: x, y: min(1, max(0, 0.11 + 0.62 * salita + tremolio(i))))
    }

    /// Un tratto basso che sale piano: «Il tuo disegno è già alla portata del piano di oggi».
    static let sottoIlPiano: [CGPoint] = (0...25).map { i in
        let x = Double(i) / 25
        return CGPoint(x: x, y: min(1, max(0, 0.1 + 0.08 * x + tremolio(i))))
    }
}
