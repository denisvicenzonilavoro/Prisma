#if os(macOS)
import Foundation

/// Le istantanee di Sala › Il film del piano (giro 15 di «Luce», §3.2.7 e §6 del piano), con lo schermo fermo sulla scena
/// chiesta nel suo stato finale (`\.modoIstantanea`: cifre complete, anelli pieni, curva tracciata) e il tempo all'inizio
/// della scena:
/// - 644: il titolo, «0:00 / 0:20» (chiaro e scuro);
/// - 645: oggi, anelli pieni e sottotitolo (chiaro e scuro);
/// - 646: ogni mese, la cifra completa;
/// - 647: il futuro, curva tracciata, etichette dentro l'area (chiaro e scuro);
/// - 648-esportato: la chiusura e la tile «✓ Il piano di Giulia.mp4 · 20 secondi · senza voce · pronto» (chiaro e scuro);
/// - 648-vuoto: Andrea senza obiettivi, data di nascita né Analisi 360: lo stato vuoto con i collegamenti.
/// DATI DI PROVA DICHIARATI (solo dentro queste scene, lo stato non si salva): un versamento mensile di prova
/// (`ProvaFilm.versamentoDiProva`) per «Anticipo per la casa» di Giulia, che nei dati di prova non ne ha (senza, la scena «Ogni
/// mese» si salterebbe); la tile «pronto» viene da `sala.provaUscite.filmEsportato`, senza un video vero. Andrea nei dati
/// di prova ha la data di nascita: la scena la toglie.
extension Istantanee {
    nonisolated static var sceneSalaFilm: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("644-sala-film-titolo") { s in apriScenaFilm(s, scena: 0) }
        coppia("645-sala-film-oggi") { s in apriScenaFilm(s, scena: 1) }
        una("646-sala-film-ogni-mese") { s in apriScenaFilm(s, scena: 2) }
        coppia("647-sala-film-futuro") { s in apriScenaFilm(s, scena: 3) }
        coppia("648-sala-film-esportato") { s in apriScenaFilm(s, scena: 4, esportato: true) }
        una("648-sala-film-vuoto") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
            s.dati.obiettivi.removeAll { $0.clienteId == "andrea" }
            s.dati.analisi["andrea"] = nil
            s.apriEsperienza(.film, cliente: "andrea")
        }
        return scene
    }

    /// Giulia con il versamento di prova, il film fermo sulla scena chiesta (e la tile «pronto»).
    nonisolated static func apriScenaFilm(_ s: StatoShell, scena: Int, esportato: Bool = false) {
        ProvaFilm.preparaDati(s)
        s.sala.provaUscite.filmScena = scena
        s.sala.provaUscite.filmEsportato = esportato
        s.apriEsperienza(.film, cliente: "giulia")
    }
}
#endif
