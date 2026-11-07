import Foundation
import CoreGraphics

/// Prove di «Disegna il tuo futuro» (Design/template-luce-specifica.md §3.3.5 punto 4, «Luce» giro 4): un tratto
/// orizzontale è alla portata se il piano cresce; un tratto altissimo chiede un versamento e, ricalcolando la linea della
/// vita con quel versamento (non arrotondato), il piano arriva al disegno entro 1 €; tre punti non bastano; i punti
/// all'indietro si scartano; un tratto che non arriva a 90 anni tiene l'ultimo valore; un disegno sotto il piano alla
/// pensione ma sopra dopo è segnalato; l'asse è in italiano. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliDisegno {
    static func esegui(_ verifica: VerificaCalcoli) {
        let ingresso = IngressoLineaVita(etaOggi: 40, etaPensione: 67, patrimonioIniziale: 100_000, risparmioAnnuo: 6_000,
                                         rendimentoReale: 1.5, redditoDesiderato: nil)
        let piano = MotoreLineaVita.calcola(ingresso)
        let assi = MotoreDisegno.assi(piano, area: CGRect(x: 60, y: 20, width: 820, height: 460))
        verifica("Disegno: asse fino a 2,1 volte il massimo del piano", assi.massimo, piano.massimo * MotoreDisegno.scalaMassimo, tolleranza: 0.5)

        /// Un tratto in età ed euro, campionato a ogni anno da `da` ad `a`.
        func tratto(da: Int, a: Int, _ valore: (Int) -> Double) -> TrattoDisegno {
            TrattoDisegno(punti: (da...a).map { CGPoint(x: Double($0), y: valore($0)) })
        }

        // Orizzontale al patrimonio di oggi: il piano cresce, il disegno è alla portata
        let piatto = tratto(da: 40, a: 90) { _ in 100_000 }
        if let e = MotoreDisegno.esito(piatto, ingresso: ingresso, assi: assi) {
            verifica.vero("Disegno: tratto orizzontale alla portata", e.versamentoInPiu == nil)
            verifica("Disegno: piano alla pensione dalla linea della vita", e.alPiano, max(0, piano.allaPensione))
        } else {
            verifica.vero("Disegno: esito del tratto orizzontale", false)
        }

        // Altissimo: serve un versamento, e con quel versamento il piano arriva al disegno
        let alto = tratto(da: 40, a: 90) { Double($0 - 40) / 50 * assi.massimo * 0.95 }
        if let e = MotoreDisegno.esito(alto, ingresso: ingresso, assi: assi) {
            verifica.vero("Disegno: tratto altissimo, versamento in più", (e.versamentoInPiu ?? 0) > 0)
            var con = ingresso
            con.risparmioAnnuo += 12 * e.versamentoEsatto
            verifica("Disegno: con il versamento il piano arriva al disegno", MotoreLineaVita.calcola(con).allaPensione, e.alDisegno, tolleranza: 1)
            verifica("Disegno: versamento arrotondato a 10 €", (e.versamentoInPiu ?? 0).truncatingRemainder(dividingBy: 10), 0)
        } else {
            verifica.vero("Disegno: esito del tratto altissimo", false)
        }

        // Tre punti: vuoto
        let corto = TrattoDisegno(punti: [CGPoint(x: 40, y: 1), CGPoint(x: 41, y: 2), CGPoint(x: 42, y: 3)])
        verifica.vero("Disegno: tre punti non bastano", MotoreDisegno.esito(corto, ingresso: ingresso, assi: assi) == nil)

        // Punti all'indietro scartati (più di 2 punti della tela a sinistra dell'ultimo)
        var t = TrattoDisegno()
        MotoreDisegno.aggiungi(CGPoint(x: 300, y: 300), a: &t, assi: assi)
        let indietro = MotoreDisegno.aggiungi(CGPoint(x: 290, y: 280), a: &t, assi: assi)
        let pocoIndietro = MotoreDisegno.aggiungi(CGPoint(x: 299, y: 280), a: &t, assi: assi)
        verifica.vero("Disegno: punto all'indietro scartato", !indietro && pocoIndietro && t.punti.count == 2)

        // Fino a 60 anni: dopo vale l'ultimo valore; prima del primo punto il primo
        let breve = tratto(da: 45, a: 60) { Double($0) * 1000 }
        let valori = MotoreDisegno.valori(breve, assi: assi)
        verifica("Disegno: un valore per età fino a 90", Double(valori.count), 51)
        verifica("Disegno: dopo l'ultimo punto resta l'ultimo valore", valori.last ?? 0, 60_000)
        verifica("Disegno: prima del primo punto vale il primo", valori.first ?? 0, 45_000)

        // Sotto il piano alla pensione, sopra dopo: alla portata ma con la frase sul dopo pensione
        let dopo = tratto(da: 40, a: 90) { $0 <= 67 ? 100_000 : 100_000 + Double($0 - 67) * 40_000 }
        if let e = MotoreDisegno.esito(dopo, ingresso: ingresso, assi: assi) {
            verifica.vero("Disegno: sopra il piano dopo la pensione segnalato", e.versamentoInPiu == nil && e.sopraDopoPensione)
        }
        if let e = MotoreDisegno.esito(piatto, ingresso: ingresso, assi: assi) {
            verifica.vero("Disegno: tratto piatto non sopra dopo la pensione", !e.sopraDopoPensione || e.possibile.last ?? 0 < 100_000)
            verifica("Disegno: il rendimento della frase è quello reale", e.rendimentoReale, 1.5)
        }

        // Il bordo alto allarga l'asse di un gradino
        let tocca = TrattoDisegno(punti: [CGPoint(x: 50, y: assi.massimo)])
        verifica.vero("Disegno: il tratto tocca il bordo alto", MotoreDisegno.toccaIlBordo(tocca, assi: assi))
        verifica("Disegno: un gradino allarga l'asse", MotoreDisegno.assi(piano, area: assi.area, gradini: 1).massimo,
                 assi.massimo * MotoreDisegno.gradino, tolleranza: 0.5)

        // L'asse in italiano
        verifica.vero("Disegno: asse «0 €»", MotoreDisegno.etichettaAsse(0) == "0 €")
        verifica.vero("Disegno: asse «350 mila»", MotoreDisegno.etichettaAsse(350_000) == "350 mila")
        verifica.vero("Disegno: asse «1,4 milioni»", MotoreDisegno.etichettaAsse(1_400_000) == "1,4 milioni")
        verifica.vero("Disegno: asse «1 milione»", MotoreDisegno.etichettaAsse(1_000_000) == "1 milione")

        // Il tratto di prova delle istantanee sta nella tela
        verifica.vero("Disegno: tratti di prova dentro la tela",
                      (DisegnoDiProva.sopraIlPiano + DisegnoDiProva.sottoIlPiano).allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }
}
