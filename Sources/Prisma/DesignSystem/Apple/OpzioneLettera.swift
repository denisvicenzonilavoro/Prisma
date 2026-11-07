import SwiftUI

// La risposta con la lettera (`.opz` del template: cerchio della lettera e testo), estratta da `OpzioneOCFVista` di
// Studio › Esame OCF per il gioco del rischio della Sala (Design/template-luce-specifica.md §4.1.2, «Luce» giro 4) e,
// più avanti, la palestra della trattativa. Aperta, si sposta di 4 al passaggio del puntatore; chiusa:
// - `.scelta`: la risposta scelta quando non c'è una risposta giusta (gioco del rischio): accento neutro;
// - `.giusta` (verde) e `.sbagliata` (rossa, trema): l'esame;
// - `.attenuata`: le altre, al 50%.
// Le scorciatoie (A/B/C) non stanno qui: le aggiunge chi la usa. «Riduci movimento» e istantanee: nessuna animazione.

extension Tema.Apple {
    /// Gettoni comuni della risposta con la lettera (prima `Tema.Apple.Studio.OCF.Opzione`, che ora li riprende).
    enum OpzioneLettera {
        /// `.opz`: spazio 14, padding 13 / 16, raggio 16, bordo 1, fondo `cardPiena`, 10 fra loro, testo 15, al più 860.
        static let spazio: CGFloat = 14
        static let padding = Tema.Apple.Misura.padding(13, 16)
        static let raggio: CGFloat = 16
        static let bordo = Tema.Apple.Misura.bordo
        static let coloreBordo = Tema.Apple.Colore.separatore
        static let fondo = Tema.Apple.Colore.cardPiena
        static let fraOpzioni: CGFloat = 10
        static let larghezza: CGFloat = 860
        static let testo = Tema.Apple.Carattere(dimensione: 15, peso: .regular, interlinea: 1.35)
        static let coloreTesto = Tema.Apple.Colore.inchiostro
        /// Il cerchio della lettera `.ol`: 30, fondo `chip`, lettera 15 bold.
        static let lettera: CGFloat = 30
        static let fondoLettera = Tema.Apple.Colore.chip
        static let carattereLettera = Tema.Apple.Carattere(dimensione: 15, peso: .bold)
        static let coloreLettera = Tema.Apple.Colore.inchiostro
        /// Al passaggio del puntatore (risposta aperta): 4 a destra.
        static let spostamentoPassaggio: CGFloat = 4
        static let lettere = ["A", "B", "C", "D"]
        /// Giusta: bordo #30B15C, fondo verde al 10%; sbagliata: bordo #E5484D, fondo rosso all'8%; lettera bianca.
        static let bordoGiusta = Tema.Apple.Colore.anello1
        static let fondoGiusta = Color(r: 48, g: 177, b: 92, a: 0.10)
        static let bordoSbagliata = Tema.Apple.Colore.rosso
        static let fondoSbagliata = Color(r: 229, g: 72, b: 77, a: 0.08)
        /// Scelta (nessuna risposta giusta): bordo `accento`, fondo `selezioneVoce`, lettera bianca su `accento`.
        static let bordoScelta = Tema.Apple.Colore.accento
        static let fondoScelta = Tema.Apple.Colore.selezioneVoce
        static let letteraPiena = Color.white
        static let opacitaAttenuata: Double = 0.5
        /// Colori e opacità in 0,30 s `ease`.
        static let durata = 0.30
        static var animazione: Animation { Tema.Apple.Moto.Curva.ease.animazione(durata) }
        /// Tremolio della sbagliata: 0 → −8 → +8 → −5 → 0 in 0,38 s, a passo lineare.
        static let durataTremolio = 0.38
        static let passiTremolio: [CGFloat] = [0, -8, 8, -5, 0]
        static var animazioneTremolio: Animation { .linear(duration: durataTremolio) }
        /// Lo spostamento del tremolio a una fase 0…1 (interpolazione lineare fra i passi).
        static func spostamentoTremolio(fase: CGFloat) -> CGFloat {
            let t = min(max(fase, 0), 1)
            let segmenti = CGFloat(passiTremolio.count - 1)
            let x = t * segmenti
            let i = min(Int(x), passiTremolio.count - 2)
            let f = x - CGFloat(i)
            return passiTremolio[i] + (passiTremolio[i + 1] - passiTremolio[i]) * f
        }
    }
}

/// Una risposta con la lettera.
struct OpzioneLettera: View {
    enum Esito: Equatable { case aperta, scelta, giusta, sbagliata, attenuata }

    let lettera: String
    let testo: String
    let esito: Esito
    var tremolio: CGFloat = 0
    /// Larghezza massima (nil = quella dei gettoni, 860).
    var larghezza: CGFloat? = nil
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    private typealias O = Tema.Apple.OpzioneLettera

    init(lettera: String, testo: String, esito: Esito, tremolio: CGFloat = 0, larghezza: CGFloat? = nil,
         azione: @escaping () -> Void) {
        self.lettera = lettera
        self.testo = testo
        self.esito = esito
        self.tremolio = tremolio
        self.larghezza = larghezza
        self.azione = azione
    }

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: O.raggio, style: .continuous)
        let aperta = esito == .aperta
        let piena = esito == .giusta || esito == .sbagliata || esito == .scelta
        return Button(action: { if aperta { azione() } }) {
            HStack(alignment: .center, spacing: O.spazio) {
                Text(lettera)
                    .carattereApple(O.carattereLettera)
                    .foregroundColor(piena ? O.letteraPiena : O.coloreLettera)
                    .frame(width: O.lettera, height: O.lettera)
                    .background(Circle().fill(fondoLettera))
                Text(testo)
                    .carattereApple(O.testo)
                    .foregroundColor(O.coloreTesto)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(O.padding)
            .frame(maxWidth: larghezza ?? O.larghezza, alignment: .leading)
            .background(forma.fill(fondo))
            .overlay(forma.strokeBorder(bordo, lineWidth: O.bordo))
            .contentShape(forma)
        }
        .buttonStyle(.plain)
        .opacity(esito == .attenuata ? O.opacitaAttenuata : 1)
        .offset(x: aperta && sopra && !calmo && !istantanea ? O.spostamentoPassaggio : 0)
        .modifier(TremolioOpzione(fase: tremolio))
        .animation(calmo || istantanea ? nil : O.animazione, value: esito)
        .animation(calmo || istantanea ? nil : O.animazione, value: sopra)
        .onHover { dentro in
            guard !istantanea, sopra != dentro else { return }
            sopra = dentro
        }
        .accessibilityLabel(Text("\(lettera). \(testo)"))
        .accessibilityAddTraits(esito == .scelta ? .isSelected : [])
    }

    private var fondo: Color {
        switch esito {
        case .giusta: return O.fondoGiusta
        case .sbagliata: return O.fondoSbagliata
        case .scelta: return O.fondoScelta
        case .aperta, .attenuata: return O.fondo
        }
    }

    private var bordo: Color {
        switch esito {
        case .giusta: return O.bordoGiusta
        case .sbagliata: return O.bordoSbagliata
        case .scelta: return O.bordoScelta
        case .aperta, .attenuata: return O.coloreBordo
        }
    }

    private var fondoLettera: Color {
        switch esito {
        case .giusta: return O.bordoGiusta
        case .sbagliata: return O.bordoSbagliata
        case .scelta: return O.bordoScelta
        case .aperta, .attenuata: return O.fondoLettera
        }
    }
}

/// Il tremolio della risposta sbagliata: x 0 → −8 → +8 → −5 → 0 lungo la fase 0…1 (animata in modo lineare).
struct TremolioOpzione: GeometryEffect {
    var fase: CGFloat

    var animatableData: CGFloat {
        get { fase }
        set { fase = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: Tema.Apple.OpzioneLettera.spostamentoTremolio(fase: fase), y: 0))
    }
}
