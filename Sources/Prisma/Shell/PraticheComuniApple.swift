import SwiftUI

// La parte comune dell'app Pratiche (Design/template-luce-specifica.md §7.0, «Luce» giro 3): la barra laterale delle
// schede con barra laterale (Proposta, e poi Moduli e Sinistri), le sue voci (avatar o tassello, titolo, sottotitolo su
// una o più righe) e lo stato vuoto comune (tassello del glifo della scheda, frase e pulsante). Valori in
// Tema.Apple.Pratiche.

/// La barra laterale di una scheda di Pratiche: raggio 20, fondo `pannello`, bordo 1, padding 14/12, titolo etichetta
/// con 8 sotto e le voci che scorrono.
struct BarraLateralePratiche<Contenuto: View>: View {
    let titolo: String
    var larghezza: CGFloat = Tema.Apple.Pratiche.laterale
    @ViewBuilder let contenuto: () -> Contenuto

    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: P.raggioLaterale, style: .continuous)
        VStack(alignment: .leading, spacing: P.sottoTitoloLaterale) {
            Text(titolo)
                .carattereApple(P.titoloLaterale)
                .foregroundColor(P.coloreTitoloLaterale)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, P.paddingVoce.leading)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: P.spazioVoci) {
                    contenuto()
                }
            }
        }
        .padding(P.paddingLaterale)
        .frame(width: larghezza, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(forma.fill(P.fondoLaterale))
        .overlay(forma.strokeBorder(P.bordoLaterale, lineWidth: Tema.Apple.Misura.bordo))
    }
}

/// Una voce della barra laterale di Pratiche: a sinistra l'avatar (o il tassello), il titolo 14 grassetto e sotto il
/// sottotitolo 12 su una o più righe (largo al più 200). Scelta `selezioneVoce`, sotto il puntatore `chip`; il fondo
/// cambia in 0,25 s. È `VoceRubricaApple` generalizzata.
struct VoceLateralePratiche<Iniziale: View>: View {
    let titolo: String
    let sottotitolo: String
    var multiriga = true
    let scelta: Bool
    let azione: () -> Void
    @ViewBuilder let iniziale: () -> Iniziale

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: P.raggioVoce, style: .continuous)
        Button(action: azione) {
            HStack(alignment: .top, spacing: P.spazioVoce) {
                iniziale()
                VStack(alignment: .leading, spacing: P.spazioTitoloMotivo) {
                    Text(titolo)
                        .carattereApple(P.titoloVoce)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sottotitolo)
                        .carattereApple(P.motivoVoce)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(multiriga ? nil : 1)
                        .fixedSize(horizontal: false, vertical: multiriga)
                        .frame(maxWidth: P.larghezzaMotivo, alignment: .leading)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(P.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if scelta { forma.fill(P.fondoScelta) } else if sopra { forma.fill(P.fondoSopra) }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { dentro in sopra = dentro && !istantanea }
        .animation(Tema.Apple.Moto.animazione(P.animazioneFondo, calmo: calmo, istantanea: istantanea), value: scelta)
        .animation(Tema.Apple.Moto.animazione(P.animazioneFondo, calmo: calmo, istantanea: istantanea), value: sopra)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

/// Lo stato vuoto comune delle schede di Pratiche: al centro il tassello del glifo della scheda, una frase, una nota
/// facoltativa e il pulsante giusto. Entra a cascata.
struct VuotoPratiche: View {
    let glifo: GlifoLuce
    let frase: String
    var nota: String? = nil
    var pulsante: String? = nil
    var azione: () -> Void = {}

    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        VStack(spacing: P.spazioVuoto) {
            TasselloGlifo(glifo: glifo, lato: P.tasselloVuoto, raggio: Tema.Apple.Raggio.voce)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Text(frase)
                .carattereApple(P.fraseVuota)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            if let nota {
                Text(nota)
                    .carattereApple(P.notaVuota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            if let pulsante {
                Button(pulsante, action: azione)
                    .buttonStyle(.applePrimario)
                    .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: P.larghezzaVuota)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

/// L'etichetta «dati di prova» accanto a ciò che viene dal catalogo d'esempio.
struct EtichettaDatiDiProvaPratiche: View {
    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        Text("dati di prova")
            .carattereApple(P.datiDiProva)
            .foregroundColor(P.coloreDatiDiProva)
            .padding(P.paddingDatiDiProva)
            .background(Capsule(style: .continuous).fill(P.fondoDatiDiProva))
            .fixedSize()
    }
}
