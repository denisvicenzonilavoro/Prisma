import Foundation

// `Prisma --prova-file-cliente <cartella>` («Luce» giro 15, §2.1): il file di prova per il lettore JavaScript (Node) e le
// pagine del PDF. Stub del giro 15·0 (esce con 0): la parte 15a sostituisce il corpo senza cambiare la firma.
@MainActor enum ProvaFileCliente {
    static func esegui(cartella: URL) -> Int32 {
        print("Prova del file del cliente: in arrivo con il giro 15 (nessuna verifica)")
        return 0
    }
}
