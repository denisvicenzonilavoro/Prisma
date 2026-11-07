import SwiftUI

// Entrata a cascata (Design/template-apple-specifica.md §2.2).
// Ogni blocco va da opacità 0, y +18, scala 0,985 e sfocatura 6 allo stato normale in 0,72 s con la
// curva `uscita`, dopo `base + indice·0,048` s; durante il ritardo resta invisibile. Parte quando compare.
// Varianti: `.entrataLaterale(_:)` (impegni, x +30) e `.entrataNotifica(_:)` (x +20, 0,4 s).
// Per farla ripartire senza ricreare le viste: `.riavviaCascata(valore)` sul contenitore (cambio cliente,
// cambio scheda); in alternativa basta cambiare `.id` alla schermata.
// «Riduci movimento» e istantanee: il blocco è subito al suo posto, senza animazione.
// Prestazioni: la sfocatura vale 0 a riposo (nessun filtro); per i blocchi che hanno già un vetro
// sfocato dentro si passa `sfocatura: false`, così le sfocature non si annidano.

private struct ChiaveGiroCascata: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// Cambia quando il contenitore vuole far ripartire le cascate dei blocchi che contiene.
    var giroCascata: Int {
        get { self[ChiaveGiroCascata.self] }
        set { self[ChiaveGiroCascata.self] = newValue }
    }
}

extension View {
    /// Entrata a cascata: `indice` segue l'ordine del contenuto (dall'alto in basso, da sinistra a destra).
    /// `base`: 0,14 in una finestra, 0,12 sulla scrivania, 0 dentro un'app (`Tema.Apple.Moto.Cascata`).
    func entrataCascata(_ indice: Int, base: Double = Tema.Apple.Moto.Cascata.baseFinestra,
                        sfocatura: Bool = true) -> some View {
        modifier(EntrataApple(stile: .cascata,
                              ritardo: Tema.Apple.Moto.Cascata.ritardo(indice: indice, base: base),
                              sfocata: sfocatura))
    }

    /// Entrata degli impegni dell'agenda: da x +30, ritardo 0,12 + i·0,08.
    func entrataLaterale(_ indice: Int) -> some View {
        modifier(EntrataApple(stile: .laterale,
                              ritardo: Tema.Apple.Moto.CascataLaterale.ritardo(indice: indice),
                              sfocata: false))
    }

    /// Entrata delle voci delle notifiche: da x +20, ritardo 0,08 + i·0,07.
    func entrataNotifica(_ indice: Int) -> some View {
        modifier(EntrataApple(stile: .notifica,
                              ritardo: Tema.Apple.Moto.VoceNotifica.ritardo(indice: indice),
                              sfocata: false))
    }

    /// Entrata delle voci della griglia del pannello Novità di «Luce» (Tema.Apple+Luce.swift): da y +8, ritardo
    /// 0,04 + i·0,014 (le 29 voci in fila, etichette escluse).
    func entrataVoceNovitaGriglia(_ indice: Int) -> some View {
        modifier(EntrataApple(stile: .voceNovitaGriglia,
                              ritardo: Tema.Apple.Moto.VoceNovitaGriglia.ritardo(indice: indice),
                              sfocata: false))
    }

    /// Entrata delle voci del pannello Novità (Tema.Apple+Novita.swift): da x +16, ritardo 0,06 + i·0,035.
    func entrataVoceNovita(_ indice: Int) -> some View {
        modifier(EntrataApple(stile: .voceNovita,
                              ritardo: Tema.Apple.Moto.VoceNovita.ritardo(indice: indice),
                              sfocata: false))
    }

    /// Entrata con uno stile dato, senza sfocatura (Inquadra e capisci: le righe della scheda «Prisma sul Mac» da
    /// x −14 e la tabella del confronto da y +10, Tema.Apple+Inquadra.swift).
    func entrataStile(_ stile: Tema.Apple.Moto.StileEntrata, ritardo: Double = 0) -> some View {
        modifier(EntrataApple(stile: stile, ritardo: ritardo, sfocata: false))
    }

    /// Fa ripartire le cascate dei blocchi qui dentro ogni volta che `valore` cambia.
    func riavviaCascata<V: Hashable>(_ valore: V) -> some View {
        environment(\.giroCascata, valore.hashValue)
    }
}

/// Il blocco che entra: opacità, spostamento, scala e sfocatura partono dallo stile e tornano a riposo.
struct EntrataApple: ViewModifier {
    let stile: Tema.Apple.Moto.StileEntrata
    let ritardo: Double
    var sfocata = true

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.giroCascata) private var giro
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var entrato = false

    func body(content: Content) -> some View {
        let fuori = !(entrato || fermo)
        let sfocatura: CGFloat = (fuori && sfocata) ? stile.sfocatura : 0
        // Nelle istantanee (che non cambiano mai durante la vita della vista) niente filtro di sfocatura a 0:
        // la cascata è già ferma e il ramo non cambia l'identità del contenuto
        return content
            .opacity(fuori ? 0 : 1)
            .scaleEffect(fuori ? stile.scala : 1)
            .offset(x: fuori ? stile.spostamentoX : 0, y: fuori ? stile.spostamentoY : 0)
            .modifier(SfocaturaEntrata(raggio: sfocatura, attiva: sfocata && !istantanea))
            .onAppear(perform: entra)
            .onChange(of: giro) { _ in riparti() }
    }

    private func entra() {
        guard !entrato else { return }
        if fermo {
            // A riposo il blocco è già al suo posto (`fermo`): nelle istantanee non serve ricordarlo
            if !scatto { entrato = true }
            return
        }
        withAnimation(stile.animazione.delay(ritardo)) { entrato = true }
    }

    private func riparti() {
        guard !fermo else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { entrato = false }
        // Al giro dopo: il blocco torna al punto di partenza prima che l'animazione cominci.
        DispatchQueue.main.async {
            withAnimation(stile.animazione.delay(ritardo)) { entrato = true }
        }
    }
}

/// La sfocatura dell'entrata solo dove serve: `attiva` non cambia mai per un blocco (è una scelta di chi chiama),
/// quindi il ramo non cambia l'identità del contenuto; senza, nessun filtro (nemmeno a raggio 0).
struct SfocaturaEntrata: ViewModifier {
    let raggio: CGFloat
    let attiva: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if attiva {
            content.blur(radius: raggio)
        } else {
            content
        }
    }
}
