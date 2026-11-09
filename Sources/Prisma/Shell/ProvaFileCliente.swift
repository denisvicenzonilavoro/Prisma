import Foundation
import PDFKit
import SwiftUI

// `Prisma --prova-file-cliente <cartella>` («Luce» giro 15, §2.1): prepara il Prisma del cliente di Giulia dai dati di
// prova (DATI DI PROVA DICHIARATI: i clienti del template, password di prova `Prova-Lettore-Node-42`, mai una password
// vera) e scrive nella cartella:
// - `prova.html`: il file per il browser con 600.000 iterazioni, che la prova Node del workflow
//   (`Supporto/prova-file-cliente.mjs`) apre con il lettore vero;
// - `atteso.json`: la password di prova, il nome e gli obiettivi che il lettore deve ritrovare;
// - `prisma-cliente.pdf` (protetto) e `pagina-1.png`… (le pagine del PDF non protetto, per le anteprime).
// In Swift controlla: decifra = contenuto; password sbagliata rifiutata; fuori dal blocco niente nome né obiettivi; il PDF
// protetto è bloccato e si sblocca con la password. Esce con 1 al primo errore.
@MainActor enum ProvaFileCliente {
    static let password = "Prova-Lettore-Node-42"

    static func esegui(cartella: URL) -> Int32 {
        var errori = 0
        func verifica(_ nome: String, _ ok: Bool, _ dettaglio: String = "") {
            print("\(ok ? "OK   " : "ERRORE") \(nome)\(dettaglio.isEmpty ? "" : ": \(dettaglio)")")
            if !ok { errori += 1 }
        }
        do {
            try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        } catch {
            print("ERRORE cartella \(cartella.path): \(error.localizedDescription)")
            return 1
        }

        let stato = StatoShell(persistente: false)
        guard let giulia = stato.cliente("giulia") else {
            print("ERRORE cliente di prova «giulia» non trovato")
            return 1
        }
        let fino = Calendar(identifier: .gregorian).date(byAdding: .year, value: 1, to: Date()) ?? Date()
        let voci = stato.vociInizialiPrismaCliente(giulia)
        verifica("Voci iniziali con gli obiettivi", voci.contains(.obiettivi))
        let contenuto = stato.contenutoPrismaCliente(giulia, voci: voci.union([.posizioni, .luce, .giornata]).subtracting(stato.disponibilitaPrismaCliente(giulia).keys),
                                                     validoFinoAl: fino, immagini: true)
        verifica("Contenuto con il nome di battesimo", contenuto.nomeBattesimo == "Giulia")
        verifica("Contenuto con gli obiettivi", contenuto.obiettivi?.isEmpty == false)
        verifica("Contenuto con la linea della vita", contenuto.lineaVita?.serie.isEmpty == false)
        verifica("Dati di prova segnati", contenuto.diProva)

        // L'HTML con le iterazioni vere
        guard let dati = try? FilePrismaCliente.html(contenuto, password: password),
              let html = String(data: dati, encoding: .utf8) else {
            verifica("HTML del file prodotto", false)
            return 1
        }
        verifica("HTML del file prodotto", true, "\(dati.count / 1024) KB")
        let fuori = FilePrismaCliente.fuoriDalBlocco(html)
        verifica("Fuori dal blocco niente nome", !fuori.contains("Giulia"))
        let titoli = contenuto.obiettivi?.map(\.titolo) ?? []
        verifica("Fuori dal blocco niente obiettivi", !titoli.contains { fuori.contains($0) })
        verifica("Nel file niente password", !html.contains(password))
        if let parti = FilePrismaCliente.parti(html) {
            let (i, blocco) = parti
            verifica("600.000 iterazioni", i.iterazioni == 600_000)
            verifica("Decifrato con la password = contenuto", (try? FilePrismaCliente.decifra(blocco, i, password: password)) == contenuto)
            var rifiutata = false
            do { _ = try FilePrismaCliente.decifra(blocco, i, password: password + "x") } catch { rifiutata = true }
            verifica("Password sbagliata rifiutata", rifiutata)
        } else {
            verifica("Parti del file leggibili", false)
        }
        do {
            try dati.write(to: cartella.appendingPathComponent("prova.html"), options: .atomic)
            let atteso: [String: Any] = ["password": password, "nome": contenuto.nomeBattesimo, "obiettivi": titoli]
            let json = try JSONSerialization.data(withJSONObject: atteso, options: [.sortedKeys])
            try json.write(to: cartella.appendingPathComponent("atteso.json"), options: .atomic)
        } catch {
            verifica("File di prova scritti", false, error.localizedDescription)
        }

        // Il PDF: protetto bloccato e sbloccabile; le pagine del PDF chiaro per le anteprime
        let documento = PaginePrismaCliente.documento(contenuto)
        if let pdf = StampaCarta.pdf(documento) {
            verifica("PDF composto", true, "\(documento.pagine.count) pagine")
            if let protetto = StampaCarta.protetto(pdf, password: password), let p = PDFDocument(data: protetto) {
                verifica("PDF protetto bloccato", p.isLocked)
                verifica("PDF protetto sbloccato con la password", p.unlock(withPassword: password))
                try? protetto.write(to: cartella.appendingPathComponent("prisma-cliente.pdf"), options: .atomic)
            } else {
                verifica("PDF protetto prodotto", false)
            }
            for (n, pagina) in documento.pagine.enumerated() {
                let immagine = StatoShell.pngPrisma(pagina.background(Tema.Apple.Carta.fondo), misura: documento.formato)
                if let immagine {
                    try? immagine.write(to: cartella.appendingPathComponent("pagina-\(n + 1).png"), options: .atomic)
                }
                verifica("Pagina \(n + 1) del PDF in PNG", immagine != nil)
            }
        } else {
            verifica("PDF composto", false)
        }

        // Il messaggio non porta la password
        verifica("Testo di Messaggi senza password", !TestiPrismaCliente.messaggio(giulia).contains(password))

        print(errori == 0 ? "Prova del file del cliente: tutto bene" : "Prova del file del cliente: \(errori) errori")
        return errori == 0 ? 0 : 1
    }
}
