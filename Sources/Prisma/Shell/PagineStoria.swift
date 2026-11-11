import SwiftUI

// Le pagine della storia (versione «Luce», giro 5, Design/template-luce-specifica.md §5.2.1): una vista per caso di
// `PaginaStoria`, centrata, testo bianco, elementi in cascata (`.sA`: da y +30, scala 0,96, sfocatura 10, 0,85 s,
// ritardo 0,12 + i·0,17), numeri contati, avatar e pallini che saltano, colonne che crescono dal basso, l'anello che si
// riempie, la linea che si disegna. Con «Riduci movimento» e nelle istantanee tutto è già fermo nello stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Storie.swift.

extension View {
    /// Entrata degli elementi della storia (`.sA`).
    func entrataStoria(_ indice: Int) -> some View {
        modifier(EntrataApple(stile: .storia, ritardo: Tema.Apple.Moto.Storia.ritardo(indice: indice), sfocata: true))
    }

    /// Il salto (`.sP`): da scala 0 a 1 con la curva dei punti, dopo `ritardo`.
    func saltoStoria(_ ritardo: Double) -> some View {
        modifier(SaltoStoria(ritardo: ritardo))
    }
}

/// Il salto di avatar e pallini; fermo nello stato finale (calmo, istantanee).
private struct SaltoStoria: ViewModifier {
    let ritardo: Double
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var dentro = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(fermo || dentro ? 1 : 0.001)
            .onAppear {
                guard !fermo, !dentro else { return }
                withAnimation(Tema.Apple.Moto.Storia.animazioneSalto.ritardoPrisma(ritardo)) { dentro = true }
            }
    }
}

/// Una colonna di «In arrivo» che cresce dal basso.
private struct ColonnaStoria: View {
    let altezza: CGFloat
    let ritardo: Double
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var cresciuta = false

    var body: some View {
        let c = Tema.Apple.Storia.Colonne.self
        UnevenRoundedRectangleStoria(alto: c.raggioAlto, basso: c.raggioBasso)
            .fill(c.colore)
            .frame(width: c.larghezza, height: altezza)
            .scaleEffect(x: 1, y: fermo || cresciuta ? 1 : 0.001, anchor: .bottom)
            .onAppear {
                guard !fermo, !cresciuta else { return }
                withAnimation(Tema.Apple.Moto.Storia.animazioneColonne.ritardoPrisma(ritardo)) { cresciuta = true }
            }
    }
}

/// Rettangolo con i raggi in alto diversi da quelli in basso (raggio 10 10 4 4): `UnevenRoundedRectangle` c'è solo da
/// macOS 14.
private struct UnevenRoundedRectangleStoria: Shape {
    let alto: CGFloat
    let basso: CGFloat

    func path(in r: CGRect) -> Path {
        let a = min(alto, r.width / 2, r.height / 2)
        let b = min(basso, r.width / 2, max(0, r.height - a))
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + a))
        p.addArc(center: CGPoint(x: r.minX + a, y: r.minY + a), radius: a, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX - a, y: r.minY))
        p.addArc(center: CGPoint(x: r.maxX - a, y: r.minY + a), radius: a, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - b))
        p.addArc(center: CGPoint(x: r.maxX - b, y: r.maxY - b), radius: b, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + b, y: r.maxY))
        p.addArc(center: CGPoint(x: r.minX + b, y: r.maxY - b), radius: b, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Una pagina della storia.
struct PaginaStoriaVista: View {
    @Environment(StatoShell.self) var stato
    let pagina: PaginaStoria
    let storia: StatoStoria

    private typealias S = Tema.Apple.Storia
    private typealias M = Tema.Apple.Moto.Storia

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(spacing: 0) {
            contenuto
        }
        .multilineTextAlignment(.center)
        .foregroundColor(S.testo)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var contenuto: some View {
        switch pagina {
        case .saluto(let nome, let periodo):
            logo.entrataStoria(0)
            titolo(TestiStorie.buongiorno(nome)).padding(.top, S.sopraTitoloLogo).entrataStoria(1)
            testo(TestiStorie.eccoSettimana(periodo)).entrataStoria(2)
            if storia.diProva {
                Text(TestiStorie.datiDiProva)
                    .carattereApple(S.prova)
                    .opacity(S.opacitaProva)
                    .padding(.top, S.sopraTesto)
                    .entrataStoria(3)
            }
        case .incontri(let numero, let clienti, let principale):
            testo(TestiStorie.questaSettimana, sopra: 0).entrataStoria(0)
            numeroConParola(Double(numero), parola: TestiStorie.incontri(numero)).entrataStoria(1)
            avatar(clienti).padding(.top, S.sopraAvatar).entrataStoria(2)
            if let principale { testo(principale).entrataStoria(3) }
            apri(4)
        case .inArrivo(let totale, let giorni, let didascalia, _):
            testo(TestiStorie.inArrivo, sopra: 0).entrataStoria(0)
            NumeroCheConta(totale, formato: .euro)
                .carattereApple(S.numero)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .entrataStoria(1)
            colonne(giorni).padding(.top, S.sopraAvatar).entrataStoria(2)
            if !didascalia.isEmpty { testo(didascalia).entrataStoria(3) }
            apri(4)
        case .daChiamare(let id, let motivo):
            testo(TestiStorie.daChiamare, sopra: 0).entrataStoria(0)
            avatarGrande(id).padding(.top, S.sopraAvatar).entrataStoria(1)
            titolo(stato.cliente(id)?.nome ?? "").padding(.top, S.sopraAvatar).entrataStoria(2)
            testo(motivo).frame(maxWidth: S.larghezzaTesto).entrataStoria(3)
            apri(4)
        case .traguardo(let id, let titoloTraguardo, let traguardoId):
            testo(TestiStorie.unTraguardo, sopra: 0).entrataStoria(0)
            anello.padding(.top, S.sopraAvatar).entrataStoria(1)
            titolo(titoloTraguardo).frame(maxWidth: S.larghezzaMomento).padding(.top, S.sopraAvatar).entrataStoria(2)
            Button {
                stato.festeggiaDallaStoria(traguardoId, clienteId: id)
            } label: {
                Text(TestiStorie.festeggialo).carattereApple(S.pulsante)
                    .foregroundColor(S.testoPieno)
                    .padding(S.paddingPulsante)
                    .background(Capsule().fill(S.fondoPieno))
            }
            .buttonStyle(StileSemplice())
            .padding(.top, S.sopraPulsante)
            .entrataStoria(3)
        case .finaleSettimana(let tranquilla):
            titolo(TestiStorie.buonaSettimana).entrataStoria(0)
            testo(tranquilla ? TestiStorie.tranquilla : TestiStorie.prontaAnche).entrataStoria(1)
            Button {
                stato.apriStoria(.anno)
            } label: {
                Label(TestiStorie.guardaAnno, systemImage: "play.fill")
                    .carattereApple(S.pulsante)
                    .foregroundColor(S.testo)
                    .padding(S.paddingPulsante)
                    .background(Capsule().fill(S.fondoVetro))
                    .overlay(Capsule().strokeBorder(S.bordoVetro, lineWidth: S.spessoreBordoVetro))
            }
            .buttonStyle(StileSemplice())
            .padding(.top, S.sopraPulsante)
            .entrataStoria(2)
        case .annoTitolo(let anno, let consulente):
            if !consulente.isEmpty { testo(consulente, sopra: 0).entrataStoria(0) }
            Text(String(anno)).carattereApple(S.anno).lineLimit(1).entrataStoria(1)
            testo(TestiStorie.annoSottotitolo).entrataStoria(2)
            if storia.diProva {
                Text(TestiStorie.datiDiProva).carattereApple(S.prova).opacity(S.opacitaProva)
                    .padding(.top, S.sopraTesto).entrataStoria(3)
            }
        case .protette(let famiglie, let capitale):
            testo(TestiStorie.protetto, sopra: 0).entrataStoria(0)
            numeroConParola(Double(famiglie), parola: TestiStorie.famiglie(famiglie)).entrataStoria(1)
            if let capitale { testo(TestiStorie.capitale(capitale)).entrataStoria(2) }
            apri(3)
        case .patrimonio(let valore, let serie, let variazione):
            testo(TestiStorie.segui, sopra: 0).entrataStoria(0)
            NumeroCheConta(valore, formato: .euro)
                .carattereApple(S.numero)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .entrataStoria(1)
            linea(serie).padding(.top, S.sopraAvatar).entrataStoria(2)
            testo(variazione.map(TestiStorie.variazione) ?? TestiStorie.primoAnno).entrataStoria(3)
        case .nuoviClienti(let numero, let passaparola):
            numeroConParola(Double(numero), parola: numero == 1 ? "cliente nuovo" : "clienti nuovi").entrataStoria(0)
            pallini(numero, passaparola: passaparola).padding(.top, S.sopraAvatar).entrataStoria(1)
            if let passaparola, passaparola > 0 { testo(TestiStorie.passaparola(passaparola)).entrataStoria(2) }
        case .chilometri(let km, let paragone, let stima):
            // Dai giri di Studio › Spese: «almeno» se qualche giro è da completare
            testo(stima ? TestiStorie.percorso + " " + TestiStorie.almenoKm : TestiStorie.percorso, sopra: 0).entrataStoria(0)
            numeroConParola(km, parola: "km").entrataStoria(1)
            // Il paragone solo da una tabella approvata dall'utente (decisione 72)
            if let paragone { testo(paragone).entrataStoria(2) }
        case .momento(_, let frase, _):
            testo(TestiStorie.momento, sopra: 0).entrataStoria(0)
            Text(frase)
                .carattereApple(S.titoloLungo)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: S.larghezzaMomento)
                .padding(.top, S.sopraTesto)
                .entrataStoria(1)
        case .grazie:
            logo.entrataStoria(0)
            titolo(TestiStorie.grazie).padding(.top, S.sopraTitoloLogo).entrataStoria(1)
        }
    }

    // MARK: Pezzi

    private var logo: some View {
        LogoPrisma(colore: S.testo)
            .frame(width: S.logo, height: S.logo)
            .accessibilityHidden(true)
    }

    private func titolo(_ t: String) -> some View {
        Text(t)
            .carattereApple(S.titolo)
            .lineLimit(3)
            .minimumScaleFactor(0.6)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func testo(_ t: String, sopra: CGFloat = Tema.Apple.Storia.sopraTesto) -> some View {
        Text(t)
            .carattereApple(S.testoPagina)
            .opacity(S.opacitaTesto)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, sopra)
    }

    /// «7 incontri»: il numero contato e la parola, tutto a 110.
    private func numeroConParola(_ v: Double, parola: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            NumeroCheConta(v, formato: .intero)
            Text("\u{00A0}" + parola)
        }
        .carattereApple(S.numero)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    /// Fino a 6 avatar da 74 sovrapposti di 16, con il bordo bianco; saltano uno dopo l'altro.
    private func avatar(_ ids: [String]) -> some View {
        HStack(spacing: -S.sovrapposizione) {
            ForEach(Array(ids.enumerated()), id: \.element) { i, id in
                if let c = stato.cliente(id) {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: S.avatar)
                        .overlay(Circle().strokeBorder(S.coloreBordoAvatar, lineWidth: S.bordoAvatar))
                        .saltoStoria(M.ritardoSalti + Double(i) * M.passoAvatar)
                        .zIndex(Double(ids.count - i))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func avatarGrande(_ id: String) -> some View {
        Group {
            if let c = stato.cliente(id) {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: S.avatarGrande)
                    .overlay(Circle().strokeBorder(S.coloreBordoAvatarGrande, lineWidth: S.bordoAvatarGrande))
            }
        }
        .accessibilityHidden(true)
    }

    /// Le colonne bianche dei giorni (alte valore/massimo·160), con il giorno sotto.
    private func colonne(_ giorni: [GiornoInArrivo]) -> some View {
        let c = S.Colonne.self
        let massimo = max(giorni.map(\.importo).max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: c.spazio) {
            ForEach(Array(giorni.enumerated()), id: \.offset) { i, g in
                VStack(spacing: c.sottoColonne) {
                    ColonnaStoria(altezza: g.importo > 0 ? max(c.minima, CGFloat(g.importo / massimo) * c.altezzaMassima) : c.vuota,
                                  ritardo: M.ritardoColonne + Double(i) * M.passoColonne)
                        .frame(height: c.altezzaMassima, alignment: .bottom)
                    Text(TestiStorie.giornoBreve(g.giorno))
                        .carattereApple(c.giorno)
                        .opacity(S.opacitaGiorni)
                }
                .help(Formati.giornoMese.string(from: g.giorno) + " · " + FormatoCifra.euro.testo(g.importo))
            }
        }
        .frame(height: c.contenitore + c.sottoColonne + c.giorno.dimensione * 1.3, alignment: .bottom)
    }

    private var anello: some View {
        AnelliConcentrici(voci: [VoceAnello(id: "traguardo", valore: 1, massimo: 1, colore: S.testo)],
                          misura: S.anello, spessore: S.spessoreAnello, ritardo: M.ritardoAnello) {
            Text("✓").carattereApple(S.spunta).foregroundColor(S.testo)
        }
        .accessibilityHidden(true)
    }

    /// La linea del patrimonio da inizio anno (normalizzata fra il minimo e il massimo della serie).
    private func linea(_ serie: [Double]) -> some View {
        let lo = serie.min() ?? 0, hi = serie.max() ?? 0
        let n = max(serie.count - 1, 1)
        let punti: [CGPoint] = serie.enumerated().map { i, v in
            CGPoint(x: Double(i) / Double(n), y: hi > lo ? 0.1 + 0.8 * (v - lo) / (hi - lo) : 0.5)
        }
        return TracciatoGrafico(punti: punti, colore: S.testo, spessore: S.spessoreLinea)
            .frame(width: S.linea.width, height: S.linea.height)
            .accessibilityHidden(true)
    }

    /// I pallini dei clienti nuovi (al più 40); senza il dato del passaparola tutti pieni.
    private func pallini(_ n: Int, passaparola: Int?) -> some View {
        let p = S.Pallini.self
        let quanti = min(n, p.massimo)
        let perRiga = max(1, Int((p.larghezza + p.spazio) / (p.lato + p.spazio)))
        let colonne = Array(repeating: GridItem(.fixed(p.lato), spacing: p.spazio), count: min(quanti, perRiga))
        return LazyVGrid(columns: colonne, spacing: p.spazio) {
            ForEach(0..<quanti, id: \.self) { i in
                Circle()
                    .fill(S.testo.opacity(passaparola.map { i < $0 ? 1 : p.spento } ?? 1))
                    .frame(width: p.lato, height: p.lato)
                    .saltoStoria(M.ritardoSalti + Double(i) * M.passoPallini)
            }
        }
        .frame(maxWidth: p.larghezza)
        .accessibilityHidden(true)
    }

    /// «Apri ›»: porta dove nasce la cifra (proposta della specifica).
    @ViewBuilder private func apri(_ indice: Int) -> some View {
        Button {
            stato.apriDallaStoria(pagina)
        } label: {
            Text(TestiStorie.apri)
                .carattereApple(S.apri)
                .foregroundColor(S.testo)
                .opacity(S.opacitaApri)
                .padding(S.paddingPulsante)
                .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .padding(.top, S.sopraTesto)
        .entrataStoria(indice)
    }
}
