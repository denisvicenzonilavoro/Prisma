import Foundation

/// **Dati di prova** (dichiarati): la nota vocale del template della specifica (§6.2.1), «dettata» da nessuno, su Giulia,
/// cliente di prova. Esiste solo nelle istantanee e nelle prove (id con il prefisso `nota-prova-`): `DatiDemo` e
/// `ClientiFittizi` non la usano, perché una nota arriva dal telefono e si decide, non sta nei dati dell'app. «Togli i
/// dati di prova» la toglie comunque, se c'è.
enum NotaVocaleDiProva {
    static let prefisso = "nota-prova-"
    static let testo = "Giulia vuole anticipare la casa di un anno. Risentirla a gennaio per il mutuo, e mandarle il confronto con 650 euro al mese."
    static let nota = "Dati di prova: la nota del template, dettata da nessuno."
    static let dispositivo = "iPhone di prova"

    /// Il messaggio del ponte, come lo manderebbe l'iPhone.
    static func ponte(quando: Date, id: String = prefisso + "template") -> NotaVocalePonte {
        NotaVocalePonte(id: id, testo: testo, quando: NotaInArrivo.alSecondo(quando), durata: 11, dispositivo: dispositivo)
    }

    /// La nota arrivata sul Mac, con il cliente riconosciuto e le proposte delle regole (come `riceviNotaVocale`).
    static func inArrivo(_ d: DatiPrisma, oggi: Date, testo: String = testo, id: String = prefisso + "template") -> NotaInArrivo {
        var p = ponte(quando: oggi, id: id)
        p.testo = testo
        var n = NotaInArrivo(da: p, arrivataIl: oggi)
        switch MotoreNotaVocale.cliente(in: testo, clienti: d.clienti, appuntamenti: d.appuntamenti, quando: oggi) {
        case .sicuro(let c): n.clienteId = c
        case .dubbio(let c): n.candidati = c
        case .nessuno: break
        }
        let cliente = n.clienteId.flatMap { c in d.clienti.first { $0.id == c } }
        n.proposte = MotoreNotaVocale.proposte(testo: testo, cliente: cliente, obiettivi: d.obiettivi, oggi: oggi)
        return n
    }
}
