import SwiftUI

// Le sovrapposizioni della realtà aumentata («Luce» giro 16, §2.3.1): le stesse sul palco del Mac (dentro la cornice
// dell'iPad), sull'iPad e sull'iPhone. SwiftUI puro, valori solo da `Tema.Apple.RealtaAumentata`:
// la pillola «◉ Prisma · AR» e quella di stato, la guida al centro, la targhetta con la cifra sopra il cristallo, le
// pillole degli strati con «Esploso», la barra in basso (anno, cursore degli anni, «Esploso», scatto), il lampo, gli
// avvisi e la colonna del Mac.

private typealias RA = Tema.Apple.RealtaAumentata

/// Una pillola scura in alto sullo schermo.
struct PillolaRealta: View {
    let testo: String
    /// Il testo verde («✓ Tavolo trovato»).
    var verde = false

    var body: some View {
        Text(testo)
            .carattereApple(RA.Pillola.testo)
            .foregroundStyle(verde ? RA.Pillola.verde : RA.Pillola.inchiostro)
            .padding(RA.Pillola.padding)
            .background(Capsule().fill(RA.Pillola.fondo))
            .lineLimit(1)
    }
}

/// La guida al centro: due quadrati arrotondati che ruotano in prospettiva e la frase.
struct GuidaRealta: View {
    let testo: String

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var giro = false

    var body: some View {
        let fermo = calmo || istantanea
        VStack(spacing: RA.Guida.spazio) {
            ZStack {
                quadrato(sfasato: true).opacity(RA.Guida.secondaOpacita)
                quadrato(sfasato: false)
            }
            .frame(width: RA.Guida.lato + RA.Guida.salto * 2, height: RA.Guida.lato + RA.Guida.salto * 2)
            Text(testo)
                .carattereApple(RA.Guida.testo)
                .foregroundStyle(RA.Guida.colore)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            guard !fermo else { return }
            withAnimation(.linear(duration: Tema.Apple.Moto.RealtaAumentata.guida).repeatForever(autoreverses: false)) { giro = true }
        }
        .accessibilityElement(children: .combine)
    }

    private func quadrato(sfasato: Bool) -> some View {
        let fase = sfasato ? Tema.Apple.Moto.RealtaAumentata.guidaSfasamento / Tema.Apple.Moto.RealtaAumentata.guida : 0
        let angolo = (giro ? 1.0 : 0.0) + fase
        return RoundedRectangle(cornerRadius: RA.Guida.raggio, style: .continuous)
            .strokeBorder(RA.Guida.colore, lineWidth: RA.Guida.bordo)
            .frame(width: RA.Guida.lato, height: RA.Guida.lato)
            .rotation3DEffect(.degrees(RA.Guida.inclinazione), axis: (x: 1, y: 0, z: 0))
            .rotationEffect(.degrees(RA.Guida.giro * angolo))
            .offset(y: -RA.Guida.salto * CGFloat(sin(angolo * .pi)))
    }
}

/// La targhetta sopra il cristallo: la cifra contata e «Giulia · 2026», con l'asta verso il cristallo.
struct TarghettaRealta: View {
    let valore: Double
    let nome: String
    let anno: Int?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: RA.Targhetta.spazio) {
                NumeroCheConta(valore, da: nil, durataCambio: Tema.Apple.Moto.RealtaAumentata.cifra)
                    .carattereApple(RA.Targhetta.cifra)
                    .foregroundStyle(RA.Targhetta.inchiostroCifra)
                Text(anno.map { TestiRealta.targhetta(nome, anno: $0) } ?? nome)
                    .carattereApple(RA.Targhetta.nome)
                    .foregroundStyle(RA.Targhetta.inchiostroNome)
            }
            .padding(RA.Targhetta.padding)
            .background(RoundedRectangle(cornerRadius: RA.Targhetta.raggio, style: .continuous).fill(RA.Targhetta.fondo)
                .shadow(color: RA.Targhetta.ombra, radius: RA.Targhetta.raggioOmbra))
            Rectangle()
                .fill(RA.Targhetta.coloreAsta)
                .frame(width: RA.Targhetta.asta.width, height: RA.Targhetta.asta.height)
        }
        .fixedSize()
        .lineLimit(1)
    }
}

/// La pillola di uno strato con «Esploso»: pallino del colore, nome e valore.
struct PillolaStrato: View {
    let strato: StratoRealta
    let valore: Double
    var spenta = false

    var body: some View {
        HStack(spacing: RA.Strato.spazio) {
            Circle().fill(RA.Strati.colore(strato.classe)).frame(width: RA.Strato.pallino, height: RA.Strato.pallino)
            Text(strato.nome).carattereApple(RA.Strato.nome).foregroundStyle(RA.Strato.inchiostro)
            Text(Formati.euro(valore)).carattereApple(RA.Strato.valore).foregroundStyle(RA.Strato.inchiostroValore)
        }
        .padding(RA.Strato.padding)
        .background(Capsule().fill(RA.Strato.fondo))
        .opacity(spenta ? RA.Strato.opacitaAltri : 1)
        .fixedSize()
        .lineLimit(1)
    }
}

/// La barra in basso: l'anno, il cursore degli anni (da oggi alla pensione), «Esploso» e lo scatto.
struct BarraRealta: View {
    let anni: [AnnoRealta]
    @Binding var anno: Int?
    @Binding var esploso: Bool
    /// Lo scatto salva nel dossier (Mac e tavolo); spento da soli sull'iPhone e sull'iPad, con l'aiuto.
    let scattoAcceso: Bool
    var aiutoScatto: String?
    let scatta: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @State private var premuto = false

    var body: some View {
        HStack(spacing: RA.Barra.spazio) {
            Text(String(anno ?? anni.first?.anno ?? 0))
                .carattereApple(RA.Barra.anno)
                .foregroundStyle(RA.Barra.inchiostro.opacity(RA.Barra.opacitaAnno))
                .frame(width: RA.Barra.larghezzaAnno)
                .opacity(anni.isEmpty ? 0 : 1)
            if let primo = anni.first?.anno, let ultimo = anni.last?.anno, ultimo > primo {
                Slider(value: Binding(get: { Double(anno ?? primo) },
                                      set: { anno = Int($0.rounded()) }),
                       in: Double(primo)...Double(ultimo), step: 1)
                    .tint(RA.Barra.inchiostro)
                    .frame(width: RA.Barra.larghezzaCursore)
                    .accessibilityLabel(Text("Anno"))
            }
            Button {
                withAnimation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.RealtaAumentata.molla, calmo: calmo)) { esploso.toggle() }
            } label: {
                Text(TestiRealta.esploso)
                    .carattereApple(RA.Interruttore.testo)
                    .foregroundStyle(esploso ? RA.Interruttore.inchiostroAcceso : RA.Interruttore.inchiostroSpento)
                    .padding(RA.Interruttore.padding)
                    .background(Capsule().fill(esploso ? RA.Interruttore.acceso : RA.Interruttore.spento))
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(esploso ? .isSelected : [])
            Button {
                scatta()
            } label: {
                ZStack {
                    Circle().fill(RA.Scatto.colore)
                    Circle().strokeBorder(RA.Scatto.coloreAnelloInterno, lineWidth: RA.Scatto.anelloInterno)
                    Circle().strokeBorder(RA.Scatto.coloreAnelloEsterno, lineWidth: RA.Scatto.anelloEsterno)
                        .padding(-RA.Scatto.anelloEsterno)
                }
                .frame(width: RA.Scatto.lato, height: RA.Scatto.lato)
                .scaleEffect(premuto ? RA.Scatto.scalaPremuto : 1)
                .opacity(scattoAcceso ? 1 : RA.Scatto.opacitaSpento)
            }
            .buttonStyle(.plain)
            .disabled(!scattoAcceso)
            .help(aiutoScatto ?? "Lo scatto: il cristallo su fondo neutro, nel dossier del cliente")
            .accessibilityLabel(Text("Scatto"))
            .accessibilityHint(Text(aiutoScatto ?? ""))
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard scattoAcceso, !premuto else { return }
                    withAnimation(.easeOut(duration: Tema.Apple.Moto.RealtaAumentata.scattoPremuto)) { premuto = true }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: Tema.Apple.Moto.RealtaAumentata.scattoPremuto)) { premuto = false }
                })
        }
        .padding(RA.Barra.padding)
        .background(Capsule().fill(RA.Barra.fondo))
        .fixedSize()
    }
}

/// Il lampo bianco dello scatto.
struct LampoRealta: View {
    let attivo: Bool

    var body: some View {
        RA.Scatto.lampo
            .opacity(attivo ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Un avviso in basso sullo schermo («Foto salvata nel dossier di …», la fotocamera che manca).
struct AvvisoRealta: View {
    let testo: String
    var azione: (titolo: String, fai: () -> Void)?

    var body: some View {
        HStack(spacing: RA.Barra.spazio) {
            Text(testo)
                .carattereApple(RA.Avviso.testo)
                .foregroundStyle(RA.Avviso.inchiostro)
                .multilineTextAlignment(.leading)
            if let azione {
                Button(azione.titolo) { azione.fai() }
                    .buttonStyle(.plain)
                    .carattereApple(RA.Avviso.testo)
                    .foregroundStyle(RA.Pillola.verde)
            }
        }
        .padding(RA.Avviso.padding)
        .background(RoundedRectangle(cornerRadius: RA.Avviso.raggio, style: .continuous).fill(RA.Avviso.fondo))
        .frame(maxWidth: RA.Avviso.larghezza)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Le etichette sopra il cristallo (targhetta e pillole degli strati), nelle posizioni date dalla scena.
struct EtichetteSopraRealta: View {
    @ObservedObject var etichette: EtichetteRealta
    let esito: EsitoRealta
    let nome: String
    let anno: Int?
    let esploso: Bool
    let scelto: String?
    /// La targhetta compare (ritardo dell'apertura o dopo la posa).
    let targhettaVisibile: Bool

    var body: some View {
        EtichettePosizionateRealta(targhetta: etichette.targhetta, strati: etichette.strati, esito: esito, nome: nome, anno: anno,
                                   esploso: esploso, scelto: scelto, targhettaVisibile: targhettaVisibile)
    }
}

/// Le etichette sopra il fermo-immagine: le posizioni del disegno di `CristalloFermo`, calcolate subito (le istantanee
/// le disegnano senza aspettare un `onAppear`).
struct EtichetteFermeRealta: View {
    let esito: EsitoRealta
    let nome: String
    let anno: Int?
    let esploso: Bool
    let scelto: String?
    let targhettaVisibile: Bool

    var body: some View {
        GeometryReader { geo in
            EtichettePosizionateRealta(targhetta: CristalloFermo.puntoTarghetta(esito, anno: anno, esploso: esploso, misura: geo.size),
                                       strati: CristalloFermo.puntiStrati(esito, anno: anno, esploso: esploso, misura: geo.size),
                                       esito: esito, nome: nome, anno: anno, esploso: esploso, scelto: scelto,
                                       targhettaVisibile: targhettaVisibile)
        }
    }
}

/// La targhetta e le pillole degli strati in posizioni date.
struct EtichettePosizionateRealta: View {
    let targhetta: CGPoint?
    let strati: [String: CGPoint]
    let esito: EsitoRealta
    let nome: String
    let anno: Int?
    let esploso: Bool
    let scelto: String?
    let targhettaVisibile: Bool

    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if esploso {
                    ForEach(esito.strati) { s in
                        if let p = strati[s.id] {
                            PillolaStrato(strato: s, valore: esito.valore(s, anno: anno), spenta: scelto != nil && scelto != s.id)
                                .position(x: p.x + RA.Strato.scostamento.width + RA.Strato.mezzaLarghezza, y: p.y + RA.Strato.scostamento.height)
                                .transition(.opacity)
                        }
                    }
                }
                if targhettaVisibile, let p = targhetta {
                    TarghettaRealta(valore: valoreTarghetta, nome: nome, anno: anno ?? esito.annoOggi)
                        .position(x: p.x, y: max(RA.Targhetta.distanzaAlto, p.y) - RA.Targhetta.asta.height * 2)
                        .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(Tema.Apple.Moto.animazione(.easeOut(duration: Tema.Apple.Moto.RealtaAumentata.pilloleStrati), calmo: calmo), value: esploso)
        .allowsHitTesting(false)
    }

    private var valoreTarghetta: Double {
        if let scelto, let s = esito.strati.first(where: { $0.id == scelto }) { return esito.valore(s, anno: anno) }
        return esito.totale(anno: anno)
    }
}

/// La colonna a destra del palco del Mac: etichetta, titolo, testo, il patrimonio dell'anno, le classi e la nota.
struct ColonnaRealta: View {
    let esito: EsitoRealta
    let primo: String
    let anno: Int?

    private typealias K = Tema.Apple.RealtaAumentata.Colonna

    var body: some View {
        VStack(alignment: .leading, spacing: K.spazio) {
            Text(TestiRealta.colonna(primo))
                .carattereApple(K.etichetta)
                .foregroundStyle(K.inchiostro2)
            Text(TestiRealta.titolo)
                .carattereApple(K.titolo)
                .foregroundStyle(K.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiRealta.testo)
                .carattereApple(K.testo)
                .foregroundStyle(K.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            if esito.vuota {
                Text(TestiRealta.senzaPosizioni(primo))
                    .carattereApple(K.testo)
                    .foregroundStyle(K.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: K.spazioTile) {
                    NumeroCheConta(esito.totale(anno: anno), da: nil, durataCambio: Tema.Apple.Moto.RealtaAumentata.cifra)
                        .carattereApple(K.cifraTile)
                        .foregroundStyle(K.inchiostro)
                    Text(TestiRealta.patrimonioNel(anno ?? esito.annoOggi ?? Calendar.current.component(.year, from: Date())))
                        .carattereApple(K.etichettaTile)
                        .foregroundStyle(K.inchiostro2)
                }
                .padding(K.paddingTile)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: K.raggioTile, style: .continuous).fill(K.tile))
                VStack(spacing: 0) {
                    ForEach(esito.strati) { s in
                        HStack(spacing: K.paddingRiga) {
                            RoundedRectangle(cornerRadius: K.raggioQuadratino, style: .continuous)
                                .fill(RA.Strati.colore(s.classe))
                                .frame(width: K.quadratino, height: K.quadratino)
                            Text(s.nome).carattereApple(K.riga).foregroundStyle(K.inchiostro)
                            Spacer(minLength: K.paddingRiga)
                            Text(Formati.percentuale((s.quota * 100).rounded()))
                                .carattereApple(K.rigaForte)
                                .foregroundStyle(K.inchiostro)
                        }
                        .padding(.vertical, K.paddingRiga)
                        .overlay(alignment: .bottom) { Rectangle().fill(K.separatore).frame(height: 1) }
                    }
                }
                if esito.stimata {
                    Text(TestiRealta.stimata).carattereApple(K.nota).foregroundStyle(K.inchiostro2)
                }
                if let motivo = esito.motivoSenzaAnni {
                    Text(motivo).carattereApple(K.nota).foregroundStyle(K.inchiostro2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Text(TestiRealta.notaAnteprima)
                .carattereApple(K.nota)
                .foregroundStyle(K.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
