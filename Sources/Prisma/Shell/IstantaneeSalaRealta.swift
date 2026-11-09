#if os(macOS)
import Foundation
import CoreGraphics

/// Le istantanee della realtà aumentata e del tavolo a doppio senso, giro 16 di «Luce» (Design/template-luce-specifica.md
/// §2.3.7 e §1.3.7), tutte nello stato finale (`\.modoIstantanea`): il cristallo con `CristalloFermo` (niente RealityKit).
/// - 630: Giulia, oggi, cristallo chiuso, targhetta, «✓ Tavolo trovato» (chiaro e scuro: il palco resta chiaro);
/// - 631: esploso con le pillole degli strati (chiaro e scuro); 632: cliente senza posizioni in essere;
/// - 633: il gioco del rischio con «Il cliente risponde sull'iPad» (chiaro e scuro); 634: Lancia l'anno al tavolo;
/// - 635: la riga di conferma delle cifre (decisione 49) in testa al palco; 636: i Documenti di Giulia con lo scatto;
/// - 695: la testata del palco del prisma di luce con «▣ Mostra sul tavolo» acceso e l'iPad collegato.
/// DATI DI PROVA DICHIARATI: lo stato di prova `ScenaRealtaDiProva`, lo scatto disegnato da `CristalloFermo` (nessuna
/// foto, nessuna stanza), la partita di Lancia l'anno a seme fisso; le cifre le calcola MotoreRealtaAumentata.
extension Istantanee {
    nonisolated static var sceneSalaRealta: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        func realta(_ s: StatoShell, _ prova: ScenaRealtaDiProva = ScenaRealtaDiProva()) {
            s.sala.realtaIstantanea = prova
            s.apriEsperienza(.realtaAumentata, cliente: "giulia")
        }
        func collegato(_ s: StatoShell, _ mostrato: String?) {
            s.tavolo.mostraPerIstantanea(iPad: "iPad di prova", mostrato: mostrato, pannello: false)
        }
        // §2.3.7: la realtà aumentata
        coppia("630-sala-realta-aumentata") { s in realta(s) }
        coppia("631-sala-realta-aumentata-esploso") { s in realta(s, ScenaRealtaDiProva(allaPensione: true, esploso: true)) }
        una("632-sala-realta-aumentata-vuota") { s in
            s.dati.posizioni.removeAll { $0.clienteId == "giulia" && $0.stato == .inEssere }
            realta(s)
        }
        // Il tavolo a doppio senso
        coppia("633-sala-rischio-al-tavolo") { s in
            collegato(s, "Il gioco del rischio · 1 di 3")
            s.sala.tavoloEsperienza = .giocoRischio
            s.sala.rischioIstantanea = PuntoGiocoRischio(scenario: 0, risposte: [])
            s.apriEsperienza(.giocoRischio, cliente: "giulia")
        }
        una("634-sala-lancia-al-tavolo") { s in
            preparaLancia(s)
            collegato(s, "Lancia l'anno · 3 di 12")
            s.sala.tavoloEsperienza = .lanciaAnno
            s.sala.lanciaIstantanea = ProvaLanciaAnno(seme: semeLancia, anni: 3)
            s.apriEsperienza(.lanciaAnno, cliente: "giulia")
        }
        una("635-sala-realta-conferma-cifre") { s in
            collegato(s, nil)
            s.sala.confermaCifreTavolo = .realtaAumentata
            realta(s)
        }
        una("636-documenti-scatto-realta") { s in
            s.clienteAttivoId = "giulia"
            MainActor.assumeIsolated {
                let e = MotoreRealtaAumentata.calcola(cliente: s.cliente("giulia") ?? Cliente.nuovo(tinta: .blu),
                                                      posizioni: s.posizioniCliente("giulia"), obiettivi: s.obiettiviCliente("giulia"),
                                                      eventi: s.eventiVitaCliente("giulia"), analisi: s.dati.analisi["giulia"])
                if let immagine = CristalloFermo.scatto(e, anno: e.annoFine, esploso: true, lato: 600),
                   let id = s.archiviaScattoRealta(immagine, cliente: "giulia", anno: e.annoFine ?? e.annoOggi ?? 2_031, esploso: true,
                                                   conStanza: false, origine: .ipad) {
                    s.documentoSelezionato = id
                }
            }
            s.apri(.documenti)
        }
        una("695-sala-tavolo") { s in
            collegato(s, nil)
            s.sala.provaLuce = ProvaLuce()
            s.apriEsperienza(.prismaLuce, cliente: "giulia")
        }
        return scene
    }
}
#endif
