import Foundation

// Proprietario: G2 (ciclo di vita).

/// Lettura dell'archivio all'avvio: parte in `PrismaApp.init` (`avvia`) su una coda di fondo, mentre AppKit e
/// SwiftUI preparano la finestra e i menu; `StatoShell.init` ne prende l'esito.
/// `Archivio.carica` usa solo FileManager e i decodificatori: niente stato del thread principale.
///
/// Con la cartella a pezzi la lettura ha due tempi: prima l'indice (piccolo: impostazioni e nomi dei clienti), poi i
/// file dei clienti e le sezioni, in parallelo. Sul Mac `StatoShell` parte appena c'è l'indice (`attendiPrimo`): se il
/// resto è già letto lo prende subito, altrimenti apre la schermata di benvenuto con lo scheletro (nessun dato dei
/// clienti, niente salvataggi, sblocco in attesa) e riceve l'archivio intero con `quandoPronto`.
enum AvvioArchivio {
    typealias Esito = Archivio.EsitoCarica

    /// Che cosa c'è quando `StatoShell` nasce.
    enum Primo {
        /// Tutto l'archivio letto (e il numero di copie non leggibili da sistemare).
        case completo(Esito, copieNonLeggibili: Int)
        /// Solo l'indice: lo scheletro per la schermata di benvenuto, il resto arriva con `quandoPronto`.
        case inArrivo(scheletro: DatiPrisma)
    }

    /// Tutto letto.
    private static let gruppo = DispatchGroup()
    /// L'indice letto (o tutto, se l'archivio non è a pezzi).
    private static let gruppoIndice = DispatchGroup()
    /// Si toccano solo dal thread principale.
    private static var avviata = false
    private static var consegnata = false
    /// Scritti dalla coda di fondo prima di `leave()`, letti dopo `wait()` o in `notify`.
    private static var letto: Esito?
    private static var copie = 0
    private static var scheletro: DatiPrisma?

    /// Fa partire la lettura (una volta sola).
    static func avvia() {
        guard !avviata else { return }
        avviata = true
        gruppo.enter()
        gruppoIndice.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            var indiceSegnato = false
            let e = Archivio.carica(indiceLetto: { s in
                scheletro = s
                indiceSegnato = true
                gruppoIndice.leave()
            })
            letto = e
            copie = Archivio.copieNonLeggibili.count
            // Prima il tutto, poi (se non era già successo) l'indice: chi aspetta l'indice trova già il tutto
            gruppo.leave()
            if !indiceSegnato { gruppoIndice.leave() }
        }
    }

    /// Sul Mac: aspetta solo l'indice. Se il resto è già letto restituisce tutto; altrimenti lo scheletro.
    static func attendiPrimo() -> Primo {
        guard avviata, !consegnata else {
            let a = attendi()
            return .completo(a.esito, copieNonLeggibili: a.copieNonLeggibili)
        }
        gruppoIndice.wait()
        if gruppo.wait(timeout: .now()) == .success || scheletro == nil {
            let a = attendi()
            return .completo(a.esito, copieNonLeggibili: a.copieNonLeggibili)
        }
        return .inArrivo(scheletro: scheletro ?? ArchivioPezzi.vuoto)
    }

    /// Dopo `attendiPrimo` → `.inArrivo`: l'archivio intero sul thread principale, appena letto.
    static func quandoPronto(_ consegna: @escaping (Esito, Int) -> Void) {
        gruppo.notify(queue: .main) {
            consegnata = true
            let e = letto ?? Archivio.carica()
            letto = nil
            scheletro = nil
            consegna(e, copie)
        }
    }

    /// L'archivio letto e il numero di copie non leggibili da sistemare. Aspetta la lettura avviata in
    /// `PrismaApp.init`; senza (o la seconda volta) legge sul momento.
    static func attendi() -> (esito: Esito, copieNonLeggibili: Int) {
        if avviata && !consegnata {
            gruppo.wait()
            consegnata = true
            scheletro = nil
            if let e = letto {
                letto = nil
                return (e, copie)
            }
        }
        let e = Archivio.carica()
        return (e, Archivio.copieNonLeggibili.count)
    }

    static func esito() -> Esito {
        attendi().esito
    }
}
