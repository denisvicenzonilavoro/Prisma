import SwiftUI

/// L'ingresso della scrivania allo sblocco (Design/template-apple-specifica.md §3.6): con la schermata di blocco i
/// blocchi della scrivania sono nascosti nel punto di partenza della cascata (§2.2: opacità 0, y +18, scala 0,985);
/// quando la schermata se ne va entrano uno dopo l'altro in 0,72 s con la curva `uscita`, dopo
/// `base + indice·0,048` s (base della scrivania 0,12: l'ottavo blocco finisce a circa 1,18 s).
/// È la stessa entrata di `.entrataCascata`, ma guidata da `nascosto` invece che dalla comparsa: le viste restano
/// montate sotto il blocco e non si ricreano. Al blocco escono tutte insieme con la curva del blocco.
/// «Riduci movimento»: solo la dissolvenza di 0,15 s. Istantanee: sempre al loro posto.
/// Niente sfocatura di proposito (`sfocatura: false`): i blocchi della scrivania hanno già il vetro sfocato dentro
/// (e senza sfocatura il filtro non c'è proprio: niente livello fuori schermo a riposo).
/// `sotto`: con una finestra aperta davanti il blocco scende al 25% in 0,5 s (§3.5). L'opacità è quella del blocco,
/// mai dell'intera scrivania: un gruppo a schermo intero costerebbe un livello fuori schermo con tutte le ombre.
///
///     WidgetAgenda().entrataSblocco(2, nascosto: sistema.bloccato)
extension View {
    func entrataSblocco(_ indice: Int, nascosto: Bool,
                        base: Double = Tema.Apple.Moto.Cascata.baseScrivania,
                        sfocatura: Bool = false, sotto: Bool = false) -> some View {
        modifier(EntrataSblocco(indice: indice, nascosto: nascosto, base: base, sfocata: sfocatura, sotto: sotto))
    }
}

private struct EntrataSblocco: ViewModifier {
    let indice: Int
    let nascosto: Bool
    let base: Double
    let sfocata: Bool
    let sotto: Bool
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let stile = Tema.Apple.Moto.StileEntrata.cascata
        let fuori = nascosto && !istantanea
        let muovi = fuori && !calmo
        return content
            .modifier(SfocaturaEntrata(raggio: (muovi && sfocata) ? stile.sfocatura : 0, attiva: sfocata))
            .opacity(fuori ? 0 : (sotto ? Tema.Apple.Scrivania.Moto.opacitaSotto : 1))
            .scaleEffect(muovi ? stile.scala : 1)
            .offset(y: muovi ? stile.spostamentoY : 0)
            .animation(animazione(fuori: fuori, stile: stile), value: fuori)
            // Sotto una finestra (o di nuovo in vista): 0,5 s; la transazione di `fuori` ha la precedenza
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Scrivania.Moto.sotto, calmo: calmo, istantanea: istantanea),
                       value: sotto)
    }

    private func animazione(fuori: Bool, stile: Tema.Apple.Moto.StileEntrata) -> Animation? {
        if istantanea { return nil }
        if calmo { return Tema.Moto.dissolvenzaCalma }
        // Al blocco tutti insieme, sotto la schermata che scende
        if fuori { return Tema.Moto.Blocco.scrivania }
        return stile.animazione.ritardoPrisma(Tema.Apple.Moto.Cascata.ritardo(indice: indice, base: base))
    }
}
