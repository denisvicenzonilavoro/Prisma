import Foundation

// Le capsule del tempo dei clienti di prova («Luce» giro 15, §3.4; «dati di prova»). Stub del giro 15·0: la parte 15c
// sostituisce il corpo (capsule di Giulia, Marco, Laura e Sofia sigillate con `SigilloCapsule.chiaveDiProva`, `diProva =
// true`) senza cambiare la firma.
enum CapsuleDiProva {
    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {}
}
