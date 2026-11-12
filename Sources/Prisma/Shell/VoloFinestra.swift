import SwiftUI

// La finestra che esce dall'icona del dock e vi rientra (Design/template-apple-specifica.md §3.5) e i pezzi
// del dock che servono a saperlo: dove sta ogni icona, il rimbalzo al clic.
// Tempi e curve in Tema.Apple.Moto (`FinestraApre`, `FinestraChiude`, `VoloFinestra`, `RimbalzoIcona`).
// Solo trasformazioni e opacità sopra una cornice ferma: il contenuto dell'app non si reimpagina durante il volo.

// MARK: - Dove sono le icone del dock

/// Le cornici delle icone del dock e i rettangoli da cui le finestre escono (o in cui rientrano).
/// Una classe non pubblicata: il dock la aggiorna a ogni impaginazione (anche mentre si ingrandisce) senza
/// ridisegnare niente; lo stato la legge quando apre, chiude, riduce o ripristina.
final class RegistroIconeDock {
    /// Le cornici delle icone com'è il dock adesso, ingrandimento compreso (spazio `ShellView.spazioShell`).
    var cornici: [AppPrisma: CGRect] = [:]
    /// Da dove esce o dove rientra la finestra di ogni app (spazio `ShellView.spazioShell`); senza: al suo posto.
    var voli: [AppPrisma: CGRect] = [:]

    /// Tiene le cornici nuove solo se sono cambiate (il dock le manda a ogni impaginazione).
    func aggiorna(_ nuove: [AppPrisma: CGRect]) {
        if cornici != nuove { cornici = nuove }
    }
}

/// Le cornici delle icone del dock, dalla fila delle icone su fino al dock.
struct ChiaveIconeDock: PreferenceKey {
    static let defaultValue: [AppPrisma: CGRect] = [:]

    static func reduce(value: inout [AppPrisma: CGRect], nextValue: () -> [AppPrisma: CGRect]) {
        value.merge(nextValue()) { _, nuovo in nuovo }
    }
}

extension View {
    /// Manda su la cornice di questa icona del dock (spazio `ShellView.spazioShell`), per l'app data.
    func corniceIconaDock(_ app: AppPrisma?) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ChiaveIconeDock.self,
                    value: app.map { [$0: geo.frame(in: CoordinateSpace.named(ShellView.spazioShell))] } ?? [:]
                )
            }
        )
    }
}

// MARK: - Il volo della finestra

/// La finestra fra l'icona e la sua cornice. A 1 è al suo posto, a 0 è dentro l'icona (invisibile).
/// - verso il suo posto (apertura, ripristino): la curva `(0.3,1.12,0.5,1)` porta posizione e scale x e y
///   separate dall'icona alla cornice; l'opacità parte da 0,2 ed è piena al 35% del tempo;
/// - verso l'icona (chiusura, riduzione): curva `(0.5,0,0.3,1)`, svanisce solo dopo il 60% del tempo.
/// Il tempo si ricava dal valore della curva (lo stato la anima con quella curva): un solo valore animato.
/// Con «Riduci movimento» niente spostamenti né scale: solo la dissolvenza breve (la curva la sceglie lo stato).
struct VoloDallIcona: ViewModifier, Animatable {
    var progresso: CGFloat
    /// L'icona nelle coordinate della finestra (0,0 è il suo angolo in alto a sinistra); nil = al suo posto.
    let icona: CGRect?
    /// La misura della finestra.
    let misura: CGSize
    let calmo: Bool
    /// Il verso (da dove va): true verso il suo posto, false verso l'icona.
    let esce: Bool
    @Environment(\.prismaCalmo) private var calmoPrisma

    /// `alSuoPosto`: dove deve arrivare la finestra.
    init(alSuoPosto: Bool, icona: CGRect?, misura: CGSize, calmo: Bool) {
        progresso = alSuoPosto ? 1 : 0
        esce = alSuoPosto
        self.icona = icona
        self.misura = misura
        self.calmo = calmo
    }

    var animatableData: CGFloat {
        get { progresso }
        set { progresso = newValue }
    }

    func body(content: Content) -> some View {
        let fermo = calmo || calmoPrisma
        content
            .transformEffect(fermo ? CGAffineTransform.identity : trasformazione)
            .opacity(opacita(fermo: fermo))
            // In volo verso l'icona la finestra non prende più i clic
            .allowsHitTesting(esce)
    }

    /// Dall'icona (o da appena più piccola, al suo posto) alla cornice: scale x e y separate, dall'angolo in alto a sinistra.
    private var trasformazione: CGAffineTransform {
        let p = progresso
        guard p != 1, misura.width > 0, misura.height > 0 else { return .identity }
        let da = partenza
        let w = da.width + (misura.width - da.width) * p
        let h = da.height + (misura.height - da.height) * p
        let x = da.minX * (1 - p)
        let y = da.minY * (1 - p)
        return CGAffineTransform(translationX: x, y: y)
            .scaledBy(x: max(w, 0.001) / misura.width, y: max(h, 0.001) / misura.height)
    }

    /// Il rettangolo dell'icona o, senza, la finestra appena rimpicciolita attorno al suo centro.
    private var partenza: CGRect {
        if let icona, icona.width > 0, icona.height > 0 { return icona }
        let k = Tema.Apple.Moto.VoloFinestra.scalaSulPosto
        return CGRect(x: misura.width * (1 - k) / 2, y: misura.height * (1 - k) / 2,
                      width: misura.width * k, height: misura.height * k)
    }

    /// L'opacità dipende solo da quanto la finestra è uscita dall'icona, uguale nei due versi: così un volo che
    /// cambia verso a metà (ridotta e subito ripristinata, chiusa mentre si apre) non lampeggia. Piena da
    /// `valoreOpaco` in su: in chiusura svanisce nell'ultimo tratto, come prima; in apertura è subito piena.
    private func opacita(fermo: Bool) -> Double {
        let p = min(max(Double(progresso), 0), 1)
        if fermo { return p }
        return min(1, p / Tema.Apple.Moto.VoloFinestra.valoreOpaco)
    }
}

/// Il contenuto della finestra appena montata entra con una dissolvenza lineare di 0,2 s (le cascate dei
/// componenti partono da sole, con la base della finestra). Già pieno con «Riduci movimento» e nelle istantanee.
struct DissolvenzaContenutoFinestra: ViewModifier {
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var dentro = false

    func body(content: Content) -> some View {
        content
            .opacity(dentro || fermo ? 1 : 0)
            .onAppear {
                guard !fermo, !dentro else { return }
                withAnimation(Tema.Apple.Moto.ContenutoFinestra.animazione) { dentro = true }
            }
    }
}

// MARK: - Il rimbalzo dell'icona

/// Il rimbalzo dell'icona del dock al clic: y −16, 0, −7, 0 in 0,7 s (`Tema.Apple.Moto.RimbalzoIcona`).
/// `fase` conta i clic: da n a n + 1 la parte frazionaria va da 0 a 1 e l'icona rimbalza; a riposo
/// (fase intera) è ferma, così non serve rimettere niente a zero.
struct RimbalzoIconaDock: GeometryEffect {
    var fase: CGFloat

    var animatableData: CGFloat {
        get { fase }
        set { fase = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let f = fase - fase.rounded(.down)
        guard f > 0 else { return ProjectionTransform(CGAffineTransform.identity) }
        let y = Tema.Apple.Moto.RimbalzoIcona.spostamento(fase: Double(f))
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: y))
    }
}
