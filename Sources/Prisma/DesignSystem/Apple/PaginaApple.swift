import SwiftUI

// Pagina che cambia (Design/template-apple-specifica.md §2.23) e giro di pagina della sala (§4.5.3).
// Transizioni asimmetriche da mettere sulla pagina che ha un `.id` proprio (scelta e numero di pagina):
// - `.cambioPagina(direzione:)` nell'anteprima: la pagina vecchia esce in 0,18 s ease-in (y −dir·30, scala
//   0,70 → 0,68, opacità 0), poi la nuova entra in 0,52 s con la curva `uscita` (da y +dir·40 e scala 0,68);
// - `.giroPaginaSala(direzione:)` in sala: esce in 0,22 s ease-in verso x −dir·120 (scala 0,88 → 0,85), poi la
//   nuova entra in 0,52 s da x +dir·160.
// Le scale del template sono quelle del foglio a riposo (0,70 e 0,88): qui sono relative alla scala a riposo,
// perché il foglio di Prisma si adatta allo spazio. `direzione` +1 = pagina seguente, −1 = precedente.
// «Riduci movimento» (`calmo`): una dissolvenza di 0,15 s. Nelle istantanee la pagina non cambia mai.
// Le animazioni sono attaccate alla transizione: chi cambia pagina basta che lo faccia dentro `withAnimation`.

/// Lo stato della pagina durante il cambio: scala relativa, spostamento e opacità (solo trasformazioni).
struct EffettoPaginaApple: ViewModifier {
    let scala: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacita: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scala)
            .offset(x: x, y: y)
            .opacity(opacita)
    }

    static let riposo = EffettoPaginaApple(scala: 1, x: 0, y: 0, opacita: 1)
}

extension AnyTransition {
    /// §2.23: la pagina dell'anteprima che cambia (in verticale).
    static func cambioPagina(direzione: Int, calmo: Bool = false) -> AnyTransition {
        if calmo { return AnyTransition.opacity.animation(Tema.Moto.dissolvenzaCalma) }
        let m = Tema.Apple.Moto.Pagina.self
        let d: CGFloat = direzione >= 0 ? 1 : -1
        let scala = m.scalaEntrata / m.scalaUscita
        let entrata = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: scala, x: 0, y: d * m.spostamentoEntrata, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.entrata.ritardoPrisma(m.durataUscita))
        let uscita = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: scala, x: 0, y: -d * m.spostamentoUscita, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.uscita)
        return AnyTransition.asymmetric(insertion: entrata, removal: uscita)
    }

    /// §4.5.3: il giro di pagina nella sala della presentazione (in orizzontale).
    static func giroPaginaSala(direzione: Int, calmo: Bool = false) -> AnyTransition {
        if calmo { return AnyTransition.opacity.animation(Tema.Moto.dissolvenzaCalma) }
        let m = Tema.Apple.Moto.GiroPagina.self
        let d: CGFloat = direzione >= 0 ? 1 : -1
        let scala = m.scala / Tema.Apple.Moto.Sala.scalaFinale
        let entrata = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: scala, x: d * m.spostamentoEntrata, y: 0, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.entrata.ritardoPrisma(m.durataUscita))
        let uscita = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: scala, x: -d * m.spostamentoUscita, y: 0, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.uscita)
        return AnyTransition.asymmetric(insertion: entrata, removal: uscita)
    }
}

extension Tema.Apple.Moto.Sala {
    /// Scala del foglio all'apertura della sala, relativa a quella a riposo (0,74 / 0,88).
    static var scalaApertura: CGFloat { scalaIniziale / scalaFinale }
}
