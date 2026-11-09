import SwiftUI

/// L'etichetta sotto ogni risposta di Vera: chi l'ha scritta («Sul Mac · Qwen · dati del cliente», «Sul Mac · regole e
/// calcoli di Prisma», «Motore esterno · nessun dato dei clienti»). Regola 3 del cervello grande, bloccata: sempre
/// visibile, nessuna impostazione la spegne. Riceve solo il messaggio (la usano anche la Vera della scrivania, iPhone e
/// iPad): niente AppKit, niente stato dell'app.
struct EtichettaMotoreVista: View {
    let messaggio: MessaggioVera

    var body: some View {
        if let e = EtichettaMotore.per(messaggio) {
            let g = Tema.Apple.EtichettaMotore.self
            let colore = Self.colore(e.tono)
            Text(e.testo)
                .carattereApple(g.carattere)
                .foregroundColor(colore)
                .lineLimit(1)
                .padding(g.padding)
                .background(Capsule(style: .continuous).fill(colore.opacity(g.alfaFondo)))
                .accessibilityLabel("Ha risposto: \(e.testo)")
        }
    }

    static func colore(_ t: EtichettaMotore.Tono) -> Color {
        switch t {
        case .sulMac: return Tema.Apple.EtichettaMotore.sulMac
        case .esterno: return Tema.Apple.EtichettaMotore.esterno
        case .prisma: return Tema.Apple.EtichettaMotore.prisma
        }
    }
}
