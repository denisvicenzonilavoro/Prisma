import SwiftUI

/// Le notifiche come nel template Apple (Design/template-apple-specifica.md §3.8): un pannello di vetro largo 360,
/// a destra sotto la barra, che scende dalla campanella con la molla (da y −10, scala 0,97, in 0,38 s); dentro, le
/// voci entrano una dopo l'altra da destra (x +20, 0,4 s, ritardo 0,08 + i·0,07). Ogni voce ha il pallino del suo
/// gruppo, il titolo in grassetto e il dettaglio; il canale resta riconoscibile con la sua etichetta. Un clic su una
/// voce chiude il pannello e porta dove si risolve; un clic fuori lo chiude. Le notifiche vengono tutte dai dati
/// (MotoreNotifiche). Con «Riduci movimento» e nelle istantanee il pannello e le voci sono già al loro posto.
/// Lo usa anche iPhone e iPad (PannelliMobile), sotto la loro barra.
struct PannelloNotifiche: View {
    @EnvironmentObject var stato: StatoShell
    @Environment(\.prismaCalmo) private var calmo

    private typealias N = Tema.Apple.CentroNotifiche

    var body: some View {
        let elenco = stato.notifiche
        ZStack(alignment: .topTrailing) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { stato.pannelloNotifiche = false }
            pannello(elenco)
                .frame(width: N.larghezza)
                // La scheda scende dalla campanella (in alto a destra); il contenitore fa solo l'opacità
                .entrataScheda(Tema.Apple.Moto.animazione(Tema.Apple.Moto.PannelloNotifiche.animazione, calmo: calmo),
                               scala: Tema.Apple.Moto.PannelloNotifiche.scala, ancora: .topTrailing,
                               y: Tema.Apple.Moto.PannelloNotifiche.spostamento)
                .padding(.top, Misure.Notifiche.alto)
                .padding(.trailing, N.destra)
                .padding(.bottom, N.basso)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func pannello(_ elenco: [Notifica]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            intestazione(elenco)
            if elenco.isEmpty {
                Text("Niente in sospeso: tutto in ordine.")
                    .carattereApple(N.testo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .padding(.top, N.spazioVoci)
            } else if elenco.count <= N.vociSenzaScorrere {
                // Poche voci: il pannello è alto quanto il contenuto; se non ci sta, scorre
                ViewThatFits(in: .vertical) {
                    voci(elenco, pigre: false)
                    ScrollView { voci(elenco, pigre: false) }
                        .scrollIndicators(.hidden)
                }
            } else {
                // Molte voci: si impaginano solo quelle in vista
                ScrollView { voci(elenco, pigre: true) }
                    .scrollIndicators(.hidden)
            }
        }
        .padding(N.padding)
        // Vetro che sfoca nell'app; senza sfocatura (istantanee) coprente, la scrivania sotto non si legge
        .superficieApple(.vetroSopra, raggio: N.raggio)
    }

    /// «Notifiche» e, a destra, quante erano nuove all'apertura (o quante sono in sospeso).
    private func intestazione(_ elenco: [Notifica]) -> some View {
        let nuove = stato.eventiShell.nuoveAllApertura
        let conteggio: String
        if nuove > 0 {
            conteggio = nuove == 1 ? "1 nuova" : "\(nuove) nuove"
        } else {
            conteggio = elenco.isEmpty ? "" : "\(elenco.count) in sospeso"
        }
        return HStack(alignment: .firstTextBaseline) {
            Text("Notifiche")
                .carattereApple(N.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Spacer(minLength: N.spazioVoce)
            Text(conteggio)
                .carattereApple(N.conteggio)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
        }
        .accessibilityElement(children: .combine)
    }

    /// Le voci per gruppo, nell'ordine dei gruppi; l'indice della cascata segue l'ordine di lettura.
    @ViewBuilder private func voci(_ elenco: [Notifica], pigre: Bool) -> some View {
        let gruppi = Notifica.Gruppo.allCases.compactMap { g -> (Notifica.Gruppo, [Notifica])? in
            let v = elenco.filter { $0.gruppo == g }
            return v.isEmpty ? nil : (g, v)
        }
        let soloUno = gruppi.count == 1
        if pigre {
            LazyVStack(alignment: .leading, spacing: 0) {
                righe(gruppi, soloUno: soloUno)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                righe(gruppi, soloUno: soloUno)
            }
        }
    }

    @ViewBuilder private func righe(_ gruppi: [(Notifica.Gruppo, [Notifica])], soloUno: Bool) -> some View {
        let partenze = PannelloNotifiche.partenze(gruppi.map { $0.1.count })
        ForEach(Array(gruppi.enumerated()), id: \.offset) { posto, coppia in
            let g = coppia.0
            let voci = coppia.1
            // Con un gruppo solo il titolo non serve (come nel template)
            if !soloUno {
                Text(g.titolo)
                    .carattereApple(N.gruppo)
                    .foregroundColor(g == .daFare ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro2)
                    .padding(.top, posto == 0 ? N.gruppoPrimo : N.gruppoAltri)
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(Array(voci.enumerated()), id: \.element.id) { i, n in
                VoceNotificaApple(notifica: n, indice: partenze[posto] + i)
                    .padding(.top, N.spazioVoci)
            }
        }
    }

    /// L'indice della prima voce di ogni gruppo nella cascata.
    private static func partenze(_ conteggi: [Int]) -> [Int] {
        var somma = 0
        return conteggi.map { c in
            defer { somma += c }
            return somma
        }
    }
}

/// Una voce: pallino del gruppo, titolo in grassetto, dettaglio (con l'etichetta del canale se c'è).
/// Entra da destra con il suo ritardo; più chiara sotto il puntatore.
private struct VoceNotificaApple: View {
    @EnvironmentObject var stato: StatoShell
    let notifica: Notifica
    let indice: Int
    @State private var sopra = false

    private typealias N = Tema.Apple.CentroNotifiche

    var body: some View {
        if indice < N.vociInCascata {
            pulsante.entrataNotifica(indice)
        } else {
            pulsante
        }
    }

    private var pulsante: some View {
        let forma = RoundedRectangle(cornerRadius: N.raggioVoce, style: .continuous)
        return Button { stato.apriNotifica(notifica) } label: {
            HStack(alignment: .top, spacing: N.spazioVoce) {
                Circle()
                    .fill(colorePallino)
                    .frame(width: N.pallino, height: N.pallino)
                    .padding(.top, N.pallinoAlto)
                VStack(alignment: .leading, spacing: 0) {
                    Text(notifica.titolo)
                        .carattereApple(N.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(2)
                    dettaglio
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(N.paddingVoce)
            .background {
                ZStack {
                    forma.fill(Tema.Apple.Colore.card)
                    if sopra { forma.fill(N.voceSopra) }
                }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { s in sopra = s }
    }

    /// Il dettaglio, con l'etichetta del canale davanti quando la notifica ne ha uno.
    @ViewBuilder private var dettaglio: some View {
        let testo = Text(notifica.dettaglio)
            .carattereApple(N.testo)
            .foregroundColor(Tema.Apple.Colore.inchiostro2)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        if let c = notifica.canale {
            HStack(alignment: .firstTextBaseline, spacing: Tema.Apple.Misura.Spazio.etichettaCanale) {
                EtichettaCanaleApple(canale: c, compatta: true)
                testo
            }
        } else {
            testo
        }
    }

    /// Rosso per ciò che è da recuperare, blu per oggi, arancio per i prossimi giorni e per ciò che è da sistemare.
    private var colorePallino: Color {
        switch notifica.gruppo {
        case .daFare: return N.pallinoUrgente
        case .oggi: return N.pallinoInformazione
        case .prossimi, .daSistemare: return N.pallinoAvviso
        }
    }
}
