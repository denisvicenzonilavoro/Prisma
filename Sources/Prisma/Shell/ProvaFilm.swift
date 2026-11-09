import Foundation

// `Prisma --prova-film [cartella]` («Luce» giro 15, §3.2): il video dei dati di prova di Giulia e i cinque fotogrammi.
// Stub del giro 15·0 (esce con 0): la parte 15b sostituisce il corpo senza cambiare la firma (chiamata da PrismaApp).
@MainActor enum ProvaFilm {
    static func esegui(cartella: URL?) -> Int32 {
        print("Prova del film: in arrivo con il giro 15 (nessuna verifica)")
        return 0
    }
}
