import SwiftUI

// Numero che si conta (Design/template-apple-specifica.md §2.1).
// Parte da 0 (o da `da`) e arriva al valore in 1,10 + min(i,6)·0,06 s con la quartica 1 − (1−t)^4.
// Un valore nuovo riparte dal numero mostrato in quel momento e arriva in 0,9 s.
// Con «Riduci movimento» e nelle istantanee il valore finale c'è subito.
// SwiftUI anima un avanzamento lineare 0 → 1 (Animatable, macOS 13): la quartica si applica a mano,
// così la curva è esattamente quella del template. Niente Timer e niente contentTransition.

/// Come si scrive il numero (formato italiano, meno tipografico).
enum FormatoCifra {
    /// «12.345 €»
    case euro
    /// «12.345»
    case intero
    /// «48%»
    case percentuale
    /// «4,5»: una cifra decimale se il valore finale non è intero, nessuna altrimenti.
    case mesi
    /// Una formattazione propria.
    case personalizzato((Double) -> String)

    /// Il testo del numero `v`; `finale` è il valore d'arrivo (decide i decimali di `.mesi`).
    func testo(_ v: Double, finale: Double? = nil) -> String {
        switch self {
        case .euro:
            return Self.migliaia(v) + "\u{00A0}€"
        case .intero:
            return Self.migliaia(v)
        case .percentuale:
            return Self.migliaia(v) + "%"
        case .mesi:
            let arrivo = finale ?? v
            let intero = arrivo.rounded() == arrivo
            return intero ? Self.migliaia(v) : Self.unDecimale(v)
        case .personalizzato(let f):
            return f(v)
        }
    }

    /// Arrotonda all'intero e mette il punto delle migliaia (anche a quattro cifre: «7.650»).
    static func migliaia(_ v: Double) -> String {
        guard v.isFinite else { return "–" }
        let n = Int(v.rounded())
        let cifre = String(n.magnitude)
        var gruppi: [Substring] = []
        var fine = cifre.endIndex
        while fine > cifre.startIndex {
            let inizio = cifre.index(fine, offsetBy: -3, limitedBy: cifre.startIndex) ?? cifre.startIndex
            gruppi.insert(cifre[inizio..<fine], at: 0)
            fine = inizio
        }
        return (n < 0 ? Formati.meno : "") + gruppi.joined(separator: ".")
    }

    /// Una cifra decimale con la virgola: «4,5», «−0,3».
    static func unDecimale(_ v: Double) -> String {
        guard v.isFinite else { return "–" }
        let decimi = Int((v * 10).rounded())
        let segno = decimi < 0 ? Formati.meno : ""
        let m = decimi.magnitude
        return segno + migliaia(Double(m / 10)) + "," + String(m % 10)
    }
}

extension FormatoCifra {
    /// Il testo che `NumeroCheConta` mostra prima che il conteggio parta (o senza conteggio):
    /// nello stato finale (calmo o istantanea) sempre il valore d'arrivo, altrimenti il punto di partenza.
    /// La usa anche `ProvaStatoFinaleApple` (`--prova-calcoli`).
    func testoFermo(_ valore: Double, da: Double?, statoFinale: Bool) -> String {
        testo(statoFinale ? valore : (da ?? valore), finale: valore)
    }
}

/// Un numero che si conta fino al valore. Lo stile si applica fuori:
/// `NumeroCheConta(318_400).carattereApple(Tema.Apple.Carattere.valore)`.
struct NumeroCheConta: View {
    let valore: Double
    var formato: FormatoCifra = .euro
    /// Posizione del numero nella schermata: allunga la durata di 0,06 s per indice (fino a 6).
    var indice: Int = 0
    /// Da dove parte la prima volta; nil = nessun conteggio all'apparire (conta solo ai cambi).
    var da: Double? = 0
    /// Durata del primo conteggio; nil = quella della specifica per l'indice.
    var durata: Double? = nil
    /// Durata dei conteggi ai cambi (nil = `Moto.NumeroCambio`, 0,9 s; Lancia l'anno: 0,7 s).
    var durataCambio: Double? = nil

    @Environment(\.prismaStatoFinale) private var fermo
    /// Istantanee: lo stato finale è per sempre, niente corsa da preparare alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var corsa: CorsaCifraApple?

    init(_ valore: Double, formato: FormatoCifra = .euro, indice: Int = 0, da: Double? = 0, durata: Double? = nil,
         durataCambio: Double? = nil) {
        self.valore = valore
        self.formato = formato
        self.indice = indice
        self.da = da
        self.durata = durata
        self.durataCambio = durataCambio
    }

    var body: some View {
        contenuto
            .monospacedDigit()
            .onAppear(perform: parti)
            .onChange(of: valore, perform: cambia)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(formato.testo(valore, finale: valore)))
    }

    @ViewBuilder private var contenuto: some View {
        if !fermo, let c = corsa {
            TrattoCifraApple(corsa: c, formato: formato, finale: valore)
                .id(c.giro)
                .transition(.identity)
        } else {
            Text(formato.testoFermo(valore, da: da, statoFinale: fermo))
                .transition(.identity)
        }
    }

    private func parti() {
        // Nelle istantanee il numero fermo è già quello finale (`contenuto`): niente da scrivere
        guard corsa == nil, !(fermo && scatto) else { return }
        let partenza = fermo ? valore : (da ?? valore)
        corsa = CorsaCifraApple(da: partenza, a: valore,
                                durata: fermo ? 0 : (durata ?? Tema.Apple.Moto.Numero.durata(indice: indice)),
                                inizio: Date(), giro: 0)
    }

    private func cambia(_ nuovo: Double) {
        let ora = Date()
        let mostrato = fermo ? nuovo : (corsa?.valore(al: ora) ?? nuovo)
        corsa = CorsaCifraApple(da: mostrato, a: nuovo,
                                durata: fermo ? 0 : (durataCambio ?? Tema.Apple.Moto.NumeroCambio.durata),
                                inizio: ora, giro: (corsa?.giro ?? 0) + 1)
    }
}

/// Un tratto del conteggio: da, a, quanto dura e quando è partito (per ripartire dal numero mostrato).
private struct CorsaCifraApple: Equatable {
    let da: Double
    let a: Double
    let durata: Double
    let inizio: Date
    let giro: Int

    func valore(al momento: Date) -> Double {
        guard durata > 0 else { return a }
        let t = momento.timeIntervalSince(inizio) / durata
        return da + (a - da) * Tema.Apple.Moto.Curva.quartica(t)
    }
}

/// Il tratto in corso: nasce a ogni nuovo valore (id del giro) e anima il proprio avanzamento 0 → 1.
private struct TrattoCifraApple: View {
    let corsa: CorsaCifraApple
    let formato: FormatoCifra
    let finale: Double
    @State private var avanzamento: Double = 0

    var body: some View {
        // Il contenuto lo ignora il modificatore (scrive lui il testo): non si usa EmptyView,
        // su cui `onAppear` può non arrivare mai.
        Text(verbatim: "")
            .modifier(TestoCifraApple(da: corsa.da, a: corsa.a, avanzamento: avanzamento,
                                      formato: formato, finale: finale))
            .onAppear {
                guard corsa.durata > 0, corsa.da != corsa.a else {
                    avanzamento = 1
                    return
                }
                withAnimation(.linear(duration: corsa.durata)) { avanzamento = 1 }
            }
    }
}

/// Il testo mentre conta: SwiftUI interpola l'avanzamento, la quartica dà il numero del fotogramma.
private struct TestoCifraApple: ViewModifier, Animatable {
    let da: Double
    let a: Double
    var avanzamento: Double
    let formato: FormatoCifra
    let finale: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func body(content: Content) -> some View {
        let t = Tema.Apple.Moto.Curva.quartica(avanzamento)
        return Text(formato.testo(da + (a - da) * t, finale: finale))
    }
}
