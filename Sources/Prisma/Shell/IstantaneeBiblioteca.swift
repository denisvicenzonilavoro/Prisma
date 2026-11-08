#if os(macOS)
import Foundation
import CoreGraphics

/// Le istantanee della Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.7, «Luce» giro 6), nello
/// stato finale (contatore sulla pagina, foglio fermo, evidenziatore pieno, risposta completa):
/// - 870: i sei fac-simile, nessuna domanda, chiaro e scuro;
/// - 871: la domanda sul riscatto, risposta completa, pagina 14 con la frase evidenziata, documento acceso, chiaro e scuro;
/// - 872: archivio senza documenti, la zona di rilascio, chiaro e scuro;
/// - 873: tre documenti in lettura con l'avanzamento;
/// - 874: risposta non trovata con le pagine più vicine;
/// - 875: Vera non pronta, la pagina con i passi trovati evidenziati;
/// - 876: «Mostra al cliente», la pagina a tutto schermo con la frase;
/// - 877: la finestra alla larghezza minima (1100).
/// DATI DI PROVA DICHIARATI: i documenti sono i sei fac-simile scritti per Prisma (Risorse/Biblioteca); le risposte di
/// Vera sono JSON di prova passati dalla stessa verifica di Prisma che vale per Qwen.
extension Istantanee {
    nonisolated static var sceneBiblioteca: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("870-biblioteca") { s in
            s.caricaEsempiBiblioteca()
            s.apri(.biblioteca)
        }
        coppia("871-biblioteca-risposta") { s in preparaRispostaBiblioteca(s) }
        coppia("872-biblioteca-vuota") { s in s.apri(.biblioteca) }
        una("873-biblioteca-lettura") { s in
            s.caricaEsempiBiblioteca()
            s.trovaPagina.mostraLetture([
                LetturaBiblioteca(id: "l1", nome: "Set informativo · Piano di risparmio (prova)", lette: 12, totale: 38),
                LetturaBiblioteca(id: "l2", nome: "KID · Fondo obbligazionario (prova)", lette: 1, totale: 3),
                LetturaBiblioteca(id: "l3", nome: "Circolare interna (prova)", lette: 5, totale: 20),
            ])
            s.apri(.biblioteca)
        }
        una("874-biblioteca-non-trovata") { s in
            s.caricaEsempiBiblioteca()
            let domanda = "Il riscatto del fondo pensione si può chiedere online?"
            s.trovaPagina.domanda = domanda
            s.chiediBiblioteca(domanda, subito: true)
            s.applicaEsitoBiblioteca(.nonTrovata)
            s.apri(.biblioteca)
        }
        una("875-biblioteca-senza-ruby") { s in
            s.caricaEsempiBiblioteca()
            let domanda = "Se Marco non paga la temporanea?"
            s.trovaPagina.domanda = domanda
            s.chiediBiblioteca(domanda, subito: true)
            s.senzaVeraBiblioteca()
            s.apri(.biblioteca)
        }
        una("876-biblioteca-cliente") { s in
            preparaRispostaBiblioteca(s)
            s.mostraBibliotecaAlCliente()
        }
        una("877-biblioteca-stretta") { s in
            preparaRispostaBiblioteca(s)
            s.alternaIngrandimento(.biblioteca)
            s.ridimensiona(.biblioteca, dimensione: CGSize(width: 1100, height: 760))
        }
        return scene
    }

    /// La domanda sul riscatto con la risposta di prova di Vera, verificata come quella di Qwen.
    nonisolated static func preparaRispostaBiblioteca(_ s: StatoShell) {
        s.caricaEsempiBiblioteca()
        let domanda = "Il riscatto nei primi anni ha penali?"
        s.trovaPagina.domanda = domanda
        s.chiediBiblioteca(domanda, subito: true)
        let passi = TrovaPaginaVera.passi(s.trovaPagina.risultato?.trovati ?? [], documenti: s.biblioteca.tutti)
        let json = #"{"trovato":true,"passo":"P1","frase":"Fino al quinto anno di contratto si applica una penale dell'1% per ogni anno che manca al quinto.","risposta":"Sì. Dopo il primo anno si può riscattare, ma fino al quinto anno si paga una penale dell'1% per ogni anno che manca al quinto. Dal quinto anno in poi il riscatto non ha penali."}"#
        if let esito = TrovaPaginaVera.leggi(json, passi: passi, domanda: domanda) { s.applicaEsitoBiblioteca(esito) }
        s.apri(.biblioteca)
    }
}
#endif
