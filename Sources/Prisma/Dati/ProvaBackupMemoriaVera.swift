import CryptoKit
import Foundation

// La memoria di Vera (fase 2 del brief: ricordi, lezioni, riassunti) e la biblioteca delle norme dentro
// `Prisma --prova-backup`: il file cifrato della memoria e la chiave cifrata con la password dei backup entrano nel backup
// e tornano uguali; nei byte del backup protetto e del file non si legge il testo di un ricordo; con la chiave giusta il
// file si apre, con una chiave sbagliata no; su un altro Mac (senza la chiave nel Portachiavi) la chiave torna con la
// password dei backup e non con una sbagliata; la biblioteca torna con i suoi articoli. Il Portachiavi non si tocca mai.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaMemoriaVera(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("MemoriaVera", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati.appendingPathComponent("Vera", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: dati.appendingPathComponent("Biblioteca", isDirectory: true), withIntermediateDirectories: true)
        try Archivio.salva(DatiPrisma.demo(), in: dati)

        // La memoria: un ricordo, una lezione, un riassunto
        guard let chiave = MemoriaVera.nuovaChiave() else { return "memoria di Vera: niente chiave casuale" }
        var c = ContenutoMemoriaVera()
        let segreto = "Sofia decide sempre insieme a Paolo, il marito"
        c.ricordi = [RicordoVera(testo: segreto, clienteId: "sofia", fonte: "in chat", data: Date(timeIntervalSinceReferenceDate: 800_000_000))]
        c.lezioni = [LezioneVera(testo: "Con i clienti Alleanza parla di «piano», non di «prodotto»", data: Date(timeIntervalSinceReferenceDate: 800_000_000))]
        c.fili = ["laura": FiloVera(riassunto: "Laura vuole smettere a 60 anni.", finoA: "msg-1", data: Date(timeIntervalSinceReferenceDate: 800_000_000))]
        let cifrato = try MemoriaVera.scrivi(c, chiave: chiave)
        guard cifrato.range(of: Data("Paolo".utf8)) == nil else { return "memoria di Vera: il file non è cifrato" }
        try cifrato.write(to: dati.appendingPathComponent("Vera/memoria.cifrato"))
        let password = "prova-memoria-vera"
        try MemoriaVera.avvolgi(chiave, password: password, in: dati.appendingPathComponent("Vera/chiave-memoria.cifrato"), iterazioni: 1_000)
        // La biblioteca: un testo diviso per articolo
        var norma = TestoNorma(titolo: "Codice delle assicurazioni private", sigla: "D.Lgs. 209/2005", edizione: "prova", file: "codice.pdf")
        norma.articoli = NormeVera.articoli(["Art. 177 – Diritto di recesso\nIl contraente può recedere entro trenta giorni."], testoId: norma.id)
        try JSONEncoder().encode([norma]).write(to: dati.appendingPathComponent("Biblioteca/biblioteca.json"))

        // Backup protetto e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup, password: "backup-di-prova", iterazioni: 1_000)
        guard (try Data(contentsOf: creato)).range(of: Data("Paolo".utf8)) == nil else { return "memoria di Vera: nel backup protetto si legge un ricordo" }
        let estratto = try GestoreBackup.estrai(creato, password: "backup-di-prova")
        defer { GestoreBackup.pulisciEstrazione(estratto.cartella) }
        let fileMemoria = estratto.cartella.appendingPathComponent("Vera/memoria.cifrato")
        let fileChiave = estratto.cartella.appendingPathComponent("Vera/chiave-memoria.cifrato")
        guard let tornato = try? Data(contentsOf: fileMemoria), tornato == cifrato else { return "memoria di Vera: il file non torna uguale dal backup" }
        guard (try? MemoriaVera.leggi(tornato, chiave: chiave)) == c else { return "memoria di Vera: con la chiave giusta non si apre uguale" }
        guard let altra = MemoriaVera.nuovaChiave(), (try? MemoriaVera.leggi(tornato, chiave: altra)) == nil else {
            return "memoria di Vera: si apre con una chiave sbagliata"
        }
        // Un altro Mac: la chiave torna con la password dei backup, non con una sbagliata
        guard let ripresa = try? MemoriaVera.svolgi(fileChiave, password: password),
              ripresa.withUnsafeBytes({ Data($0) }) == chiave.withUnsafeBytes({ Data($0) }) else {
            return "memoria di Vera: la chiave non torna con la password dei backup"
        }
        guard (try? MemoriaVera.svolgi(fileChiave, password: "sbagliata")) == nil else { return "memoria di Vera: la chiave si apre con una password sbagliata" }
        // La biblioteca torna con i suoi articoli
        let biblio = try? JSONDecoder().decode([TestoNorma].self, from: Data(contentsOf: estratto.cartella.appendingPathComponent("Biblioteca/biblioteca.json")))
        guard biblio?.first?.articoli.first?.numero == "177" else { return "biblioteca: i testi non tornano dal backup" }
        // L'istantanea di «Prisma ovunque» non porta niente della memoria (che non sta nell'archivio)
        let istantanea = try Archivio.codificatore.encode(SpazioOvunque.datiIstantanea(DatiPrisma.demo()))
        guard istantanea.range(of: Data("Paolo, il marito".utf8)) == nil else { return "memoria di Vera: un ricordo nell'istantanea di Prisma ovunque" }
        return nil
    }
}
