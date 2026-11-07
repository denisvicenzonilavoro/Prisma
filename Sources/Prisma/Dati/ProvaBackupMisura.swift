import Foundation

// «Misura la velocità su questo Mac» (giro 0 di «Prisma istantaneo») dentro `Prisma --prova-backup`: la misura non
// tocca l'archivio dell'utente. La prova della fluidità che la misura lancia (`--prova-fluidita`) sostituisce
// Application Support con una cartella vuota (`Archivio.cartellaDiProva`) e lavora con uno stato non persistente;
// qui, in breve, lo stesso: con la cartella finta al suo posto, uno stato non persistente modificato, salvato e
// lasciato lavorare non deve scrivere nulla, e la cartella dell'archivio non deve essere più quella vera.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaMisuraVelocita(radice: URL) throws -> String? {
        let fm = FileManager.default
        let finta = radice.appendingPathComponent("Supporto-finto", isDirectory: true)
        try fm.createDirectory(at: finta, withIntermediateDirectories: true)
        let vera = Archivio.cartella
        Archivio.cartellaDiProva = finta
        defer { Archivio.cartellaDiProva = nil }
        guard Archivio.cartella.path.hasPrefix(finta.path), Archivio.cartella != vera,
              Archivio.file.path.hasPrefix(finta.path), Archivio.cartellaVera.path.hasPrefix(finta.path) else {
            return "misura della velocità: con la cartella di prova l'archivio punta ancora alla cartella vera"
        }
        // Come la prova della fluidità: stato non persistente, dati modificati, salvataggio chiesto, lavori rimandati
        let stato = StatoShell(persistente: false)
        if let i = stato.dati.note.indices.first {
            stato.dati.note[i].testo += "x"
        }
        stato.dati.impostazioni.nomeUtente += " prova"
        stato.ricalcolaNotifiche()
        _ = stato.memoriaVera
        _ = stato.biblioteca
        stato.salvaOra()
        let fine = Date().addingTimeInterval(0.6)
        while Date() < fine {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
        }
        let scritti = (fm.enumerator(at: finta, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? [])
            .map(\.lastPathComponent)
        guard scritti.isEmpty else {
            return "misura della velocità: lo stato di prova ha scritto dove starebbe l'archivio (\(scritti.prefix(3).joined(separator: ", ")))"
        }
        #if os(macOS)
        // L'app lancia proprio la prova della fluidità, che si isola da sé, e ne legge la tabella
        let uscita = radice.appendingPathComponent("velocita.md")
        guard MisuraVelocita.argomenti(uscita: uscita) == ["--prova-fluidita", uscita.path] else {
            return "misura della velocità: l'app non lancia la prova della fluidità"
        }
        let righe = MisuraVelocita.leggi("""
            | Scenario | Azione | Mediana | Massimo | Aggiornamento | Disegno | Prima volta | Avvisi StatoShell | Avvisi StatoFinestre |
            |---|---|---:|---:|---:|---:|---:|---:|---:|
            | 5 clienti | Luce · apri il radar | 12 ms | 15 ms | 10 ms | 2 ms | 30 ms | 1 | 2 |
            """)
        guard righe == [MisuraVelocita.Riga(scenario: "5 clienti", azione: "Luce · apri il radar", tempo: "10 ms", primaVolta: "30 ms")] else {
            return "misura della velocità: la tabella della prova non si legge (\(righe))"
        }
        #endif
        print("OK    misura della velocità: con la cartella di prova lo stato non persistente non scrive nulla, l'archivio vero resta fuori portata")
        return nil
    }
}
