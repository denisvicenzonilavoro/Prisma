#if os(macOS)
import Foundation

/// Le istantanee del gioco del rischio e di una giornata della pensione (Design/template-luce-specifica.md §4.1.7 e
/// §4.2.7, «Luce» giro 4), tutte nello stato finale (`\.modoIstantanea`: linee tracciate, numeri completi, anelli pieni):
/// - 660: Giulia, scenario 1 (80.000 € in rosso, linea e area, riferimento a 100.000 €, tre risposte, nessuna scelta),
///   chiaro e scuro; 661: scenario 3, le due strade, risposta B scelta (accento neutro);
/// - 662: il risultato (anello pieno, «Dinamica», tre reazioni con i secondi, «Dichiarato: Moderata · Emerso:
///   Dinamica» in arancio), chiaro e scuro; 663: il risultato per un cliente senza propensione dichiarata;
/// - 664: il riquadro «L'ultima volta…» prima dello scenario 1 (una partita salvata nel dossier);
/// - 665: Giulia senza piano (colazione e casa accese, le altre spente), chiaro e scuro; 666: con il piano;
/// - 667: la giornata da compilare (scene senza importi, «Scrivi con Giulia quanto costa»);
/// - 668: cliente senza ipotesi di previdenza (la frase e il pulsante verso Analisi 360).
/// DATI DI PROVA DICHIARATI: le ipotesi di previdenza di Giulia (1.400 € di pensione pubblica, 2.200 € desiderati,
/// confermate) e la giornata con le cinque scene e gli importi del template (`MotoreGiornataPensione.giornataDiProva`,
/// etichetta «dati di prova»); risposte e secondi del gioco scritti qui; i testi del gioco sono «testi di prova».
extension Istantanee {
    nonisolated static var sceneSalaGiochi: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        // §4.1: il gioco del rischio
        coppia("660-sala-rischio-scenario") { s in
            s.sala.rischioIstantanea = PuntoGiocoRischio(scenario: 0, risposte: [])
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        una("661-sala-rischio-strade") { s in
            s.sala.rischioIstantanea = PuntoGiocoRischio(scenario: 2, risposte: risposteDiProva(2), scelta: 1)
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        coppia("662-sala-rischio-profilo") { s in
            s.sala.rischioIstantanea = PuntoGiocoRischio(scenario: 3, risposte: risposteDiProva(3), risultato: true)
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        una("663-sala-rischio-senza-dichiarato") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) { s.dati.clienti[i].profilo.propensione = nil }
            s.sala.rischioIstantanea = PuntoGiocoRischio(scenario: 3, risposte: risposteDiProva(3), risultato: true)
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        una("664-sala-rischio-ultima-volta") { s in
            s.dati.partiteRischio = MotoreGiocoRischio.partiteDiProva(clienti: ["giulia"])
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        // §4.2: una giornata della pensione
        coppia("665-sala-giornata-senza") { s in
            preparaGiornata(s, giornata: MotoreGiornataPensione.giornataDiProva())
            s.sala.giornataConPiano = false
            s.apriEsperienza(.giornataPensione, cliente: "giulia")
        }
        una("666-sala-giornata-con") { s in
            preparaGiornata(s, giornata: MotoreGiornataPensione.giornataDiProva())
            s.sala.giornataConPiano = true
            s.apriEsperienza(.giornataPensione, cliente: "giulia")
        }
        una("667-sala-giornata-da-compilare") { s in
            preparaGiornata(s, giornata: nil)
            s.apriEsperienza(.giornataPensione, cliente: "giulia")
        }
        una("668-sala-giornata-dati-mancanti") { s in
            s.dati.analisi["giulia"] = nil
            s.apriEsperienza(.giornataPensione, cliente: "giulia")
        }
        return scene
    }

    /// Le risposte di prova dei primi `n` scenari: B, B, C (4 punti: «Dinamica»), con i secondi.
    nonisolated static func risposteDiProva(_ n: Int) -> [RispostaRischio] {
        let tre = [RispostaRischio(scenario: "calo", scelta: 1, secondi: 1.0),
                   RispostaRischio(scenario: "risalita", scelta: 1, secondi: 1.6),
                   RispostaRischio(scenario: "strade", scelta: 2, secondi: 2.3)]
        return Array(tre.prefix(n))
    }

    /// DATI DI PROVA: le ipotesi di previdenza di Giulia confermate (1.400 / 2.200) e la giornata data.
    nonisolated static func preparaGiornata(_ s: StatoShell, giornata: GiornataPensione?) {
        guard let giulia = s.cliente("giulia") else { return }
        var a = s.dati.analisi["giulia"] ?? Analisi360(cliente: giulia, posizioni: s.posizioniCliente("giulia"))
        a.previdenza.pensionePubblica = 1_400
        a.previdenza.redditoDesiderato = 2_200
        a.confermate = [.previdenza]
        a.giornata = giornata
        s.dati.analisi["giulia"] = a
    }
}
#endif
