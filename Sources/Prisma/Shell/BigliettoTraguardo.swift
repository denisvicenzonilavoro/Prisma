import SwiftUI

// Il biglietto del traguardo (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.1 punto 1.2): 560×420,
// raggio 24, testo bianco su un fondo radiale dal colore del traguardo a #14202B, con i coriandoli sopra. Colori fissi
// nei due temi, come un oggetto da mandare. Si vede ma non si condivide ancora: l'immagine da passare al foglio di
// condivisione del Mac arriva con il giro 15 (decisioni 9 e 115).
//
//   ◯✓
//   Ce l’hai fatta, Sofia.
//   120.000 €  messi al sicuro in 5 anni e mezzo
//   L’obiettivo che avevamo progettato insieme è raggiunto. …
//   — Denis
//
// Movimento: la cifra si conta, l'anello si riempie dopo 0,2 s, i coriandoli cadono per 6 s e svaniscono entro 8 s.
// «Riduci movimento» e istantanee: cifra completa, anello pieno, niente coriandoli.

struct BigliettoTraguardo: View {
    let traguardo: Traguardo
    /// «Denis» (nil = nessuna firma: Prisma non conosce il nome).
    let firma: String?

    private typealias B = Tema.Apple.Messaggi.Traguardo

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: B.raggio, style: .continuous)
        ZStack(alignment: .topLeading) {
            B.fondo(B.tinta(traguardo.tipo))
            VStack(alignment: .leading, spacing: 0) {
                AnelliConcentrici(voci: [VoceAnello(id: "biglietto", valore: 1, massimo: 1, colore: B.testo)],
                                  misura: B.anello, spessore: B.spessore, ritardo: Tema.Apple.Moto.Anello.ritardoPredefinito) {
                    Text("✓").carattereApple(B.spunta).foregroundColor(B.testo)
                }
                .accessibilityHidden(true)
                Text(traguardo.saluto)
                    .carattereApple(B.titolo)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, B.sopraTitolo)
                if let cifra = traguardo.cifra {
                    HStack(alignment: .firstTextBaseline, spacing: B.spazioCifra) {
                        NumeroCheConta(cifra, formato: .euro)
                            .carattereApple(B.cifra)
                            .lineLimit(1)
                        if let d = traguardo.didascaliaCifra {
                            Text(d)
                                .carattereApple(B.didascalia)
                                .opacity(B.opacitaDidascalia)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.top, B.sopraCifra)
                }
                Text(traguardo.frase)
                    .carattereApple(B.frase)
                    .opacity(B.opacitaFrase)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, B.sopraFrase)
                if let firma, !firma.isEmpty {
                    Text("— " + firma)
                        .carattereApple(B.firma)
                        .opacity(B.opacitaFirma)
                        .padding(.top, B.sopraFirma)
                }
                Spacer(minLength: 0)
            }
            .foregroundColor(B.testo)
            .padding(B.padding)
            CoriandoliApple(seme: traguardo.id)
        }
        .frame(width: B.biglietto.width, height: B.biglietto.height)
        .clipShape(forma)
        .shadow(color: B.ombra, radius: B.ombraRaggio, x: 0, y: B.ombraY)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }
}
