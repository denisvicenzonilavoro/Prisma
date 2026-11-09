import Foundation

// I sinistri dei clienti di prova («Luce» giro 15, §7.4; «dati di prova»). Stub del giro 15·0: la parte 15e sostituisce
// il corpo (Marco «Infortunio di Pietro», Sofia «Danni da acqua in cucina», Giulia «Furto della bicicletta») senza
// cambiare la firma né il prefisso degli id (`rimuoviDatiDiProva` li toglie da qui).
enum SinistriDiProva {
    /// Il prefisso degli id dei sinistri di prova.
    static let prefisso = "sinistro-prova-"

    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {}
}
