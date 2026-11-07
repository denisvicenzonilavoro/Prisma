import SwiftUI

// Le pillole dei clienti con l'avatar 24 e il nome (Design/template-luce-specifica.md §1.3.5): estratte da Analisi 360
// (prima `PilloleClienti360`) per usarle anche nella Sala, con lo stesso comportamento (preferiti prima, il cliente
// attivo c'è sempre, cinque poi quattro e tre voci se lo spazio manca).

/// Le pillole dei clienti della testata: cinque, quattro o tre voci (ViewThatFits), con ingressi semplici così il
/// confronto `Equatable` evita di rifare le tre varianti (dodici voci con l'avatar) quando non cambia niente.
struct PilloleClienti: View, Equatable {
    /// Una voce: ciò che la pillola mostra del cliente.
    struct Voce: Equatable {
        let id: String
        let nome: String
        let iniziali: String
        let tinta: TintaAvatar

        init(_ c: Cliente) {
            id = c.id
            nome = StatoShell.nomeBreve(c)
            iniziali = c.iniziali
            tinta = c.tinta
        }
    }

    /// Le voci delle tre varianti (cinque, quattro e tre clienti).
    let lunga: [Voce]
    let media: [Voce]
    let corta: [Voce]
    let scelto: String
    /// Sceglie il cliente: resta fuori dal confronto (scrive sempre il cliente attivo).
    let scegli: (String) -> Void

    static func == (a: Self, b: Self) -> Bool {
        a.lunga == b.lunga && a.media == b.media && a.corta == b.corta && a.scelto == b.scelto
    }

    var body: some View {
        let selezione = Binding(get: { scelto }, set: { scegli($0) })
        return ViewThatFits(in: .horizontal) {
            segmentato(lunga, selezione: selezione)
            segmentato(media, selezione: selezione)
            segmentato(corta, selezione: selezione)
        }
    }

    private func segmentato(_ voci: [Voce], selezione: Binding<String>) -> some View {
        let tinte = Dictionary(voci.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        return SegmentatoPillola(selezione: selezione, voci: voci.map { ($0.id, $0.nome) }, icona: { id in
            if let v = tinte[id] {
                return AnyView(AvatarCliente(iniziali: v.iniziali, tinta: v.tinta.colori,
                                             lato: Tema.Apple.Aree360.Testata.avatar))
            }
            return AnyView(EmptyView())
        })
        .fixedSize()
    }

    /// Le voci di ogni variante: i preferiti prima, poi gli altri nell'ordine dell'archivio; il cliente attivo prende
    /// l'ultimo posto se non c'è.
    static func varianti(_ tutti: [Cliente], attivo: Cliente?, numeri: [Int]) -> [[Voce]] {
        let ordinati = tutti.filter(\.preferito) + tutti.filter { !$0.preferito }
        return numeri.map { n in
            var scelti = Array(ordinati.prefix(max(1, n)))
            if let attivo, !scelti.contains(where: { $0.id == attivo.id }) {
                if scelti.count >= n { scelti.removeLast() }
                scelti.append(attivo)
            }
            return scelti.map(Voce.init)
        }
    }
}
