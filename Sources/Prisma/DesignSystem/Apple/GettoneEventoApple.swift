import SwiftUI

// Il gettone di un evento sulla linea della vita (Design/template-novita-specifica.md §7.2.3, `.vEv` del template):
// capsula con il bordo 2 nel colore dell'evento (verde entrata, arancio uscita, viola pensione, grigio senza cifra),
// nome in grassetto e «{età} anni». Preso: ombra più ampia in 0,2 s; al rilascio un piccolo rimbalzo 1,08 → 1 con la
// molla del tema. Con «Riduci movimento» e nelle istantanee il gettone si posa e basta.
// Lo spostamento (DragGesture) lo fa chi lo usa: qui solo l'aspetto. Valori in Tema.Apple+LineaVita.swift.

struct GettoneEventoApple: View {
    enum Genere: Equatable {
        case entrata, uscita, pensione, senzaCifra
    }

    let nome: String
    let dettaglio: String
    let genere: Genere
    /// Il gettone è preso (trascinato): ombra della presa.
    var preso = false
    /// Non si trascina (un obiettivo del dossier): bordo più tenue.
    var fisso = false

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var statoFinale
    @State private var rimbalzo: CGFloat = 1

    var body: some View {
        let g = Tema.Apple.GettoneEvento.self
        let colore = Self.colore(genere)
        let presa = g.ombraPresa
        return HStack(spacing: g.spazio) {
            Text(nome)
                .carattereApple(g.nome)
                .foregroundColor(g.coloreNome)
            Text(dettaglio)
                .carattereApple(g.dettaglio)
                .foregroundColor(g.coloreDettaglio)
        }
        .lineLimit(1)
        .fixedSize()
        .padding(g.padding)
        .background {
            Capsule(style: .continuous)
                .fill(genere == .pensione ? colore.opacity(g.opacitaFondoPensione) : g.fondo)
                .ombraApple(g.ombra)
                // L'ombra della presa c'è sempre e compare con l'opacità: così passa in 0,2 s
                .shadow(color: presa.colore.opacity(preso ? Tema.Apple.Ombra.opacitaApprossimata(presa) : 0),
                        radius: presa.sfocatura * Tema.Apple.Ombra.raggioPerSfocatura, x: 0, y: presa.y)
                .animation(calmo || statoFinale ? nil : Tema.Apple.Moto.LineaVita.ombra, value: preso)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(colore.opacity(fisso ? g.opacitaFisso : 1), lineWidth: g.bordo)
        }
        .scaleEffect(rimbalzo)
        .onChange(of: preso) { nuovo in
            if !nuovo { rimbalza() }
        }
        .accessibilityElement(children: .combine)
    }

    /// Il colore del bordo (e, per la pensione, del fondo).
    static func colore(_ genere: Genere) -> Color {
        let g = Tema.Apple.GettoneEvento.self
        switch genere {
        case .entrata: return g.coloreEntrata
        case .uscita: return g.coloreUscita
        case .pensione: return g.colorePensione
        case .senzaCifra: return g.coloreSenzaCifra
        }
    }

    /// Al rilascio: scala 1,08 subito, poi la molla a 1 al giro dopo (nello stesso giro SwiftUI li unirebbe).
    private func rimbalza() {
        guard !calmo, !statoFinale else { return }
        var senza = Transaction()
        senza.disablesAnimations = true
        withTransaction(senza) { rimbalzo = Tema.Apple.Moto.LineaVita.scalaRimbalzo }
        DispatchQueue.main.async {
            withAnimation(Tema.Apple.Moto.LineaVita.rimbalzo) { rimbalzo = 1 }
        }
    }
}
