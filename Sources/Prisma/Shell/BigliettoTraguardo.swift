import SwiftUI

// Il biglietto del traguardo (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.1 punto 1.2): 560×420,
// raggio 24, testo bianco su un fondo radiale dal colore del traguardo a #14202B, con i coriandoli sopra. Colori fissi
// nei due temi, come un oggetto da mandare. «Luce» giro 15 (§5.4, decisioni 9 e 115): la stessa vista diventa il PNG da
// condividere (EsportaBiglietto.swift, senza coriandoli né ombra); «Mostra la cifra» spento toglie la cifra e la sua
// didascalia (anche nell'anteprima: si vede ciò che parte); la frase scritta a mano prende il posto di quella di Prisma.
// I testi li sceglie `TestiBiglietto.contenuto` (funzione pura, provata in ProvaCalcoliBiglietto).
//
//   ◯✓
//   Ce l’hai fatta, Sofia.
//   120.000 €  messi al sicuro in 5 anni e mezzo      (solo con «Mostra la cifra»)
//   L’obiettivo che avevamo progettato insieme è raggiunto. …
//   — Denis
//
// Movimento: la cifra si conta, l'anello si riempie dopo 0,2 s, i coriandoli cadono per 6 s e svaniscono entro 8 s.
// «Riduci movimento» e istantanee: cifra completa, anello pieno, niente coriandoli.

struct BigliettoTraguardo: View {
    let traguardo: Traguardo
    /// «Denis» (nil = nessuna firma: Prisma non conosce il nome).
    let firma: String?
    /// «Mostra la cifra» (le chiamate di prima la mostrano; il pannello parte spento).
    var mostraCifra = true
    /// La frase scritta a mano (nil = quella di Prisma, `traguardo.frase`).
    var frase: String? = nil
    var coriandoli = true
    /// Il PNG non ha ombra: fuori dal biglietto non c'è niente.
    var ombra = true
    /// Clic sulla frase (il pannello apre il campo per cambiarla); nil = la frase non si tocca.
    var suFrase: (() -> Void)? = nil

    private typealias B = Tema.Apple.Messaggi.Traguardo

    var body: some View {
        let testi = TestiBiglietto.contenuto(traguardo, mostraCifra: mostraCifra, frase: frase)
        let forma = RoundedRectangle(cornerRadius: B.raggio, style: .continuous)
        ZStack(alignment: .topLeading) {
            B.fondo(B.tinta(traguardo.tipo))
            VStack(alignment: .leading, spacing: 0) {
                AnelliConcentrici(voci: [VoceAnello(id: "biglietto", valore: 1, massimo: 1, colore: B.testo)],
                                  misura: B.anello, spessore: B.spessore, ritardo: Tema.Apple.Moto.Anello.ritardoPredefinito) {
                    Text("✓").carattereApple(B.spunta).foregroundColor(B.testo)
                }
                .accessibilityHidden(true)
                Text(testi.saluto)
                    .carattereApple(B.titolo)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, B.sopraTitolo)
                if let cifra = testi.cifra {
                    HStack(alignment: .firstTextBaseline, spacing: B.spazioCifra) {
                        NumeroCheConta(cifra, formato: .euro)
                            .carattereApple(B.cifra)
                            .lineLimit(1)
                        if let d = testi.didascalia {
                            Text(d)
                                .carattereApple(B.didascalia)
                                .opacity(B.opacitaDidascalia)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.top, B.sopraCifra)
                }
                fraseVista(testi.frase)
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
            if coriandoli {
                CoriandoliApple(seme: traguardo.id)
            }
        }
        .frame(width: B.biglietto.width, height: B.biglietto.height)
        .clipShape(forma)
        .shadow(color: ombra ? B.ombra : .clear, radius: ombra ? B.ombraRaggio : 0, x: 0, y: ombra ? B.ombraY : 0)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func fraseVista(_ testo: String) -> some View {
        let t = Text(testo)
            .carattereApple(B.frase)
            .opacity(B.opacitaFrase)
            .fixedSize(horizontal: false, vertical: true)
        if let suFrase {
            t.contentShape(Rectangle())
                .onTapGesture { suFrase() }
                .help(TestiBiglietto.aiutoFrase)
                .accessibilityAddTraits(.isButton)
        } else {
            t
        }
    }
}
