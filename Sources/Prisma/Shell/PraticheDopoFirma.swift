import SwiftUI

// Pratiche › Dopo la firma (Design/template-luce-specifica.md §7.3, «Luce» giro 3), a tutta larghezza:
//
//   DOPO LA FIRMA · dati di prova
//   ┌ Pratiche aperte ┐ ┌ Ferme da più di 7 giorni ┐ ┌ Concluse a ottobre ┐
//   │ 3               │ │ 1 (rosso)                │ │ 1                  │
//   └─────────────────┘ └──────────────────────────┘ └────────────────────┘
//   ┌ (MB) Marco Bianchi   [Alleanza]   ●──●──●──◉──○──○          3 di 6 ┐
//   │      Infortuni famiglia            Moduli … Consegnata   Fermo da 9 giorni: … │
//   │                                                              [Sollecita]     │
//   └──────────────────────────────────────────────────────────────────────────────┘
//
// - Le cifre e le frasi vengono da MotorePratiche (passi riconosciuti dai dati, segno a mano che vince, soglia delle
//   Impostazioni, mese scorso calcolato); qui solo la disposizione. Il canale resta in vista su ogni card.
// - Clic sulla card: il dettaglio nasce dalla card e ci torna (`presentatoreDettaglio`, come il radar) con i passi, la
//   loro data, «riconosciuto da …» o «segnato a mano», i documenti collegati, le note e «Apri in Posizioni».
//   Clic su un passo (nella card o nel dettaglio): lo segna o lo toglie a mano, con la data di oggi modificabile.
// - «Sollecita» prepara la bozza in Messaggi (niente parte da solo) e diventa «✓ Sollecito pronto» finché il messaggio
//   non viene aperto; se manca l'emissione dice «Sollecita la compagnia».
// - Tile: clic su «Ferme…» mostra solo le ferme, su «Concluse a …» le concluse del mese scorso; un secondo clic torna
//   a tutte. Sotto 1100 di larghezza il canale va sotto il nome.
// - Movimento: tile e card a cascata, numeri che si contano, passi uno dopo l'altro (y +6, 0,40 s, ritardo 0,20 + i·0,025
//   su tutta la pagina). «Riduci movimento» e istantanee: tutto subito fermo nello stato finale.

struct PraticheDopoFirma: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoPraticheDopo(stato: stato, dettaglioAperto: stato.praticaDettaglioIstantanea)
    }
}

/// Quale elenco mostra la scheda (clic sulle tile).
private enum FiltroPratiche: Hashable {
    case ferme, concluse
}

private struct CorpoPraticheDopo: View {
    let stato: StatoShell
    @StateObject private var dettaglio: StatoDettaglio
    @State private var filtro: FiltroPratiche?

    private typealias P = Tema.Apple.PraticheDopo
    private typealias D = Tema.Apple.PraticheDopo.Dettaglio

    init(stato: StatoShell, dettaglioAperto: String?) {
        self.stato = stato
        _dettaglio = StateObject(wrappedValue: dettaglioAperto.map { StatoDettaglio(aperto: $0, misura: D.misura) }
                                 ?? StatoDettaglio())
    }

    var body: some View {
        let oggi = Date()
        let stati = stato.statiPratiche(oggi: oggi)
        let soglia = stato.dati.impostazioni.pratiche.giorniFerma
        let r = MotorePratiche.riepilogo(stati, soglia: soglia, oggi: oggi)
        let d = dettaglio
        return GeometryReader { g in
            let compatta = g.size.width < P.larghezzaCompatta
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    intestazione(prova: stati.contains { $0.pratica.diProva })
                        .padding(.bottom, P.sottoTitoloScheda)
                    tile(r)
                        .padding(.bottom, P.sottoTile)
                    elenco(stati, riepilogo: r, oggi: oggi, compatta: compatta)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .presentatoreDettaglio(dettaglio) { id in
            if let s = stati.first(where: { $0.id == id }) {
                DettaglioPratica(stato: stato, pratica: s) {
                    d.chiudi(subito: true)
                    stato.apriPosizioneDellaPratica(s.id)
                }
            }
        }
        .onDisappear { dettaglio.chiudi(subito: true) }
    }

    // MARK: Intestazione e tile

    private func intestazione(prova: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: P.Dettaglio.spazioControlli) {
            Text(SchedaPratiche.dopoLaFirma.titolo)
                .carattereApple(P.titoloScheda)
                .foregroundColor(P.coloreTitoloScheda)
            if prova {
                Text("· dati di prova")
                    .carattereApple(P.etichettaProva)
                    .foregroundColor(P.coloreProva)
            }
        }
        .entrataCascata(0, base: P.Moto.baseCascata)
    }

    private func tile(_ r: RiepilogoPratiche) -> some View {
        HStack(spacing: P.spazioTile) {
            TilePratiche(titolo: TestiPratiche.tileAperte, numero: r.aperte, indice: 0, rossa: false, scelta: false) {
                filtro = nil
            }
            TilePratiche(titolo: TestiPratiche.tileFerme(r.soglia), numero: r.ferme, indice: 1, rossa: r.ferme > 0,
                         scelta: filtro == .ferme) {
                filtro = filtro == .ferme ? nil : .ferme
            }
            TilePratiche(titolo: TestiPratiche.tileConcluse(r.meseScorso), numero: r.concluseMeseScorso, indice: 2,
                         rossa: false, scelta: filtro == .concluse) {
                filtro = filtro == .concluse ? nil : .concluse
            }
        }
    }

    // MARK: Elenco

    @ViewBuilder
    private func elenco(_ stati: [StatoPratica], riepilogo r: RiepilogoPratiche, oggi: Date, compatta: Bool) -> some View {
        let aperte = stati.filter { !$0.conclusa }
        let delMese = MotorePratiche.concluseMeseScorso(stati, oggi: oggi)
        if stati.isEmpty {
            StatoVuotoPratiche(frase: TestiPratiche.nessuna, verde: false) { stato.vaiAlleProposte() }
                .entrataCascata(3, base: P.Moto.baseCascata)
        } else {
            switch filtro {
            case .ferme:
                carte(aperte.filter(\.ferma), compatta: compatta)
            case .concluse:
                sezione(TestiPratiche.tileConcluse(r.meseScorso), delMese, compatta: compatta)
            case nil:
                if aperte.isEmpty {
                    StatoVuotoPratiche(frase: TestiPratiche.tuttoInOrdine, verde: true, azione: nil)
                        .entrataCascata(3, base: P.Moto.baseCascata)
                    if !delMese.isEmpty { sezione(TestiPratiche.tileConcluse(r.meseScorso), delMese, compatta: compatta) }
                } else {
                    // Le aperte, poi le concluse recenti (di questo mese e del mese scorso): le più vecchie non tornano
                    let recenti = stati.filter { s in
                        s.conclusa && (s.conclusaIl.map { $0 >= MotorePratiche.meseScorso(oggi).start } ?? true)
                    }
                    carte(aperte + recenti, compatta: compatta)
                }
            }
        }
    }

    private func sezione(_ titolo: String, _ stati: [StatoPratica], compatta: Bool) -> some View {
        VStack(alignment: .leading, spacing: P.sottoTitoloScheda) {
            Text(titolo)
                .carattereApple(P.titoloScheda)
                .foregroundColor(P.coloreTitoloScheda)
                .padding(.top, P.sopraSezione)
            carte(stati, compatta: compatta)
        }
    }

    private func carte(_ stati: [StatoPratica], compatta: Bool) -> some View {
        // L'indice del primo passo di ogni card, contato su tutta la pagina (la cascata dei passi corre da card a card)
        var primi: [Int] = []
        var conta = 0
        for s in stati {
            primi.append(conta)
            conta += s.passi.count
        }
        return VStack(alignment: .leading, spacing: P.spazioCard) {
            ForEach(Array(stati.enumerated()), id: \.element.id) { i, s in
                CardPratica(stato: stato, pratica: s, compatta: compatta, primoPasso: primi[i],
                            pronto: stato.sollecitoPronto(s.pratica)) {
                    dettaglio.apri(s.id, misura: D.misura)
                }
                .entrataCascata(3 + i, base: P.Moto.baseCascata)
            }
        }
    }
}

// MARK: - Tile

private struct TilePratiche: View {
    let titolo: String
    let numero: Int
    let indice: Int
    let rossa: Bool
    let scelta: Bool
    let azione: () -> Void

    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        Button(action: azione) {
            VStack(alignment: .leading, spacing: P.spazioDentroTile) {
                Text(titolo)
                    .carattereApple(P.etichettaTile)
                    .foregroundColor(P.coloreEtichettaTile)
                    .lineLimit(1)
                NumeroCheConta(Double(numero), formato: .intero, indice: indice)
                    .carattereApple(P.numeroTile)
                    .foregroundColor(rossa ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro)
            }
            .padding(P.paddingTile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(P.superficieTile)
            .overlay {
                if scelta {
                    RoundedRectangle(cornerRadius: P.superficieTile.raggio, style: .continuous)
                        .strokeBorder(P.bordoTileScelta, lineWidth: P.spessoreTileScelta)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .entrataCascata(1 + indice / 2, base: P.Moto.baseCascata)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(scelta ? .isSelected : [])
    }
}

// MARK: - Stato vuoto

private struct StatoVuotoPratiche: View {
    let frase: String
    let verde: Bool
    let azione: (() -> Void)?

    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        VStack(spacing: P.spazioVuoto) {
            if verde {
                Text(frase)
                    .carattereApple(P.tuttoInOrdine)
                    .foregroundColor(P.coloreTuttoInOrdine)
            } else {
                TasselloGlifo(glifo: .cartella, lato: P.tasselloVuoto, raggio: Tema.Apple.Raggio.voce)
                Text(frase)
                    .carattereApple(Tema.Apple.Carattere.corpo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let azione {
                Button("Vai alle proposte", action: azione)
                    .buttonStyle(.applePrimario)
            }
        }
        .frame(maxWidth: P.larghezzaVuoto)
        .padding(P.paddingVuoto)
        .frame(maxWidth: .infinity)
        .superficieApple(P.superficieCard)
    }
}

// MARK: - Card di una pratica

private struct CardPratica: View {
    let stato: StatoShell
    let pratica: StatoPratica
    let compatta: Bool
    let primoPasso: Int
    let pronto: Bool
    let apri: () -> Void

    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        let s = pratica
        let cliente = stato.cliente(s.clienteId)
        let forma = RoundedRectangle(cornerRadius: P.raggioCard, style: .continuous)
        return HStack(alignment: .center, spacing: P.spazioRiga) {
            AvatarCliente(iniziali: cliente?.iniziali ?? "", tinta: (cliente?.tinta ?? .blu).colori, lato: P.avatar)
            VStack(alignment: .leading, spacing: P.spazioNome) {
                Text(cliente?.nome ?? "Cliente non trovato")
                    .carattereApple(P.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                Text(s.posizione.nome)
                    .carattereApple(P.prodotto)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
                if compatta { EtichettaCanaleApple(canale: s.canale, compatta: true) }
            }
            .frame(width: P.colonnaNome, alignment: .leading)
            if !compatta {
                EtichettaCanaleApple(canale: s.canale, compatta: true)
                    .frame(width: P.colonnaCanale, alignment: .leading)
            }
            LineaPassi(stato: stato, pratica: s, primoIndice: primoPasso)
                .padding(.horizontal, P.margineLinea)
                .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: P.spazioStato) {
                Text(s.testoStato)
                    .carattereApple(P.stato)
                    .foregroundColor(s.conclusa ? Tema.Apple.Colore.verde : (s.ferma ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro))
                Text(s.nota)
                    .carattereApple(P.nota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                if s.ferma {
                    PulsanteSollecito(pratica: s, pronto: pronto) { stato.sollecitaPratica(s.id) }
                        .padding(.top, P.sopraPulsante)
                }
            }
            .frame(width: P.colonnaStato, alignment: .trailing)
        }
        .padding(P.paddingCard)
        .background {
            forma.fill(P.superficieCard.riempimento)
            if s.ferma { forma.fill(P.fondoFerma) }
        }
        .overlay {
            forma.strokeBorder(s.ferma ? P.bordoFerma : Tema.Apple.Colore.separatore, lineWidth: P.spessoreBordo)
        }
        .contentShape(forma)
        .onTapGesture(perform: apri)
        .origineDettaglio(id: s.id)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(cliente?.nome ?? ""), \(s.posizione.nome), \(s.canale.nome): \(s.testoStato). \(s.nota)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { apri() }
    }
}

/// «Sollecita», «Sollecita la compagnia» o «✓ Sollecito pronto» (pulsante primario piccolo, padding 5/12).
private struct PulsanteSollecito: View {
    let pratica: StatoPratica
    let pronto: Bool
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Text(pronto ? "✓ Sollecito pronto" : (pratica.sollecitoCompagnia ? "Sollecita la compagnia" : "Sollecita"))
        }
        .buttonStyle(StilePulsantePiccoloPratiche(pronto: pronto))
        .help(pronto ? "Il messaggio è in Messaggi, da rivedere e spedire: un clic lo riapre."
                     : "Prepara il messaggio in Messaggi: lo rivedi e lo spedisci tu.")
    }
}

/// Il pulsante primario piccolo della card (padding 5/12); pronto: testo verde su fondo chiaro.
private struct StilePulsantePiccoloPratiche: ButtonStyle {
    let pronto: Bool

    func makeBody(configuration: Configuration) -> some View {
        let P = Tema.Apple.PraticheDopo.self
        let forma = Capsule(style: .continuous)
        return configuration.label
            .carattereApple(P.caratterePulsante)
            .foregroundColor(pronto ? P.colorePronto : Tema.Apple.Controlli.Pulsante.testoPrincipale)
            .lineLimit(1)
            .padding(P.paddingPulsante)
            .background {
                if pronto {
                    forma.fill(Tema.Apple.Colore.cardPiena)
                        .overlay { forma.strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo) }
                } else {
                    forma.fill(Tema.Apple.Colore.accento)
                }
            }
            .opacity(configuration.isPressed ? P.opacitaPremuto : 1)
            .contentShape(forma)
    }
}

// MARK: - La linea dei passi

/// I passi della pratica in fila: pallino 14 e etichetta su due righe, il filo fra i centri. Clic su un passo: il
/// pannellino per segnarlo o toglierlo a mano.
struct LineaPassi: View {
    let stato: StatoShell
    let pratica: StatoPratica
    /// L'indice del primo passo nella pagina (la cascata dei passi corre su tutta la scheda).
    let primoIndice: Int

    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        let passi = pratica.passi
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(passi.enumerated()), id: \.element.id) { i, p in
                PassoLinea(stato: stato, pratica: pratica, passo: p,
                           filoVerde: i > 0 ? p.stato != .futuro : nil)
                    .frame(maxWidth: .infinity)
                    .entrataStile(P.Moto.entrataPasso, ritardo: P.Moto.ritardoPasso(primoIndice + i))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Un passo sulla linea. Il filo verso il passo prima sta dietro (zIndex), dal centro al centro.
private struct PassoLinea: View {
    let stato: StatoShell
    let pratica: StatoPratica
    let passo: PassoCalcolato
    /// nil per il primo passo (nessun filo); vero se il filo verso di lui è verde.
    let filoVerde: Bool?

    @State private var aperto = false
    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        Button { aperto = true } label: {
            VStack(spacing: P.distanzaEtichetta) {
                PallinoPasso(stato: passo.stato)
                Text(passo.etichetta)
                    .carattereApple(carattere)
                    .foregroundColor(coloreEtichetta)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(alignment: .top) { filo }
        .popover(isPresented: $aperto, arrowEdge: .bottom) {
            ControlliPasso(stato: stato, pratica: pratica, passo: passo, compatto: false)
                .padding(Tema.Apple.Misura.Padding.tile)
        }
        .help(TestiPratiche.dettaglio(passo))
        .accessibilityLabel("\(passo.etichetta): \(TestiPratiche.dettaglio(passo))")
    }

    /// Dal centro del passo prima al centro di questo (la colonna prima è larga come questa).
    @ViewBuilder private var filo: some View {
        if let verde = filoVerde {
            GeometryReader { g in
                Rectangle()
                    .fill(verde ? P.coloreFatto : P.coloreBinario)
                    .frame(width: g.size.width, height: P.filo)
                    .offset(x: -g.size.width / 2, y: (P.pallino - P.filo) / 2)
            }
            .allowsHitTesting(false)
        }
    }

    private var carattere: Tema.Apple.Carattere {
        switch passo.stato {
        case .adesso: return P.etichettaAdesso
        case .bloccato: return P.etichettaBloccato
        case .fatto, .futuro: return P.etichetta
        }
    }

    private var coloreEtichetta: Color {
        switch passo.stato {
        case .fatto: return P.etichettaFatta
        case .adesso: return P.coloreAdesso
        case .bloccato: return P.coloreBloccato
        case .futuro: return P.etichettaFutura
        }
    }
}

/// Il pallino di un passo: verde pieno (fatto), bordo blu con alone (adesso), rosso pieno con alone (bloccato),
/// grigio (futuro).
struct PallinoPasso: View {
    let stato: StatoPasso
    private typealias P = Tema.Apple.PraticheDopo

    var body: some View {
        let lato = P.pallino
        ZStack {
            switch stato {
            case .fatto:
                Circle().fill(P.coloreFatto)
            case .adesso:
                Circle().fill(P.aloneAdesso).frame(width: lato + 2 * P.spessoreAlone, height: lato + 2 * P.spessoreAlone)
                Circle().fill(P.colorePallinoVuoto)
                Circle().strokeBorder(P.coloreAdesso, lineWidth: P.bordoPallino)
            case .bloccato:
                Circle().fill(P.aloneBloccato).frame(width: lato + 2 * P.spessoreAlone, height: lato + 2 * P.spessoreAlone)
                Circle().fill(P.coloreBloccato)
            case .futuro:
                Circle().fill(P.colorePallinoVuoto)
                Circle().strokeBorder(P.coloreBinario, lineWidth: P.bordoPallino)
            }
        }
        .frame(width: lato, height: lato)
    }
}

// MARK: - Segnare un passo a mano

/// Cosa dice il passo e come cambiarlo: la data (oggi di base) e «Segna fatto», «Togli» o «Torna ai dati».
struct ControlliPasso: View {
    let stato: StatoShell
    let pratica: StatoPratica
    let passo: PassoCalcolato
    /// Nel dettaglio: in riga, senza il titolo.
    let compatto: Bool

    @State private var data = Posizione.oggiArrotondato
    private typealias D = Tema.Apple.PraticheDopo.Dettaglio

    var body: some View {
        let segnato = pratica.pratica.segno(passo.passo) != nil
        let contenuto = Group {
            // La data serve solo per segnare il passo fatto (togliere vale da oggi)
            if !passo.fatto {
                DatePicker("Il", selection: $data, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(width: D.selettoreData)
            }
            if passo.fatto {
                Button("Togli") { stato.segnaPasso(pratica.id, passo.passo, fatto: false) }
                    .buttonStyle(.apple)
            } else {
                Button("Segna fatto") { stato.segnaPasso(pratica.id, passo.passo, fatto: true, il: data) }
                    .buttonStyle(.applePrimario)
            }
            if segnato {
                Button("Torna ai dati") { stato.togliSegnoPasso(pratica.id, passo.passo) }
                    .buttonStyle(.appleSobrio)
                    .help("Toglie il segno a mano: vale di nuovo ciò che Prisma riconosce dai dati")
            }
        }
        .disabled(stato.solaLettura)
        if compatto {
            HStack(spacing: D.spazioControlli) { contenuto }.fixedSize()
        } else {
            VStack(alignment: .leading, spacing: D.spazioPopover) {
                Text(passo.etichetta)
                    .carattereApple(Tema.Apple.Carattere.titoloRiga)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text(TestiPratiche.dettaglio(passo))
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: D.spazioControlli) { contenuto }.fixedSize()
            }
            .frame(minWidth: D.larghezzaPopover, alignment: .leading)
        }
    }
}

// MARK: - Il dettaglio di una pratica

struct DettaglioPratica: View {
    let stato: StatoShell
    let pratica: StatoPratica
    let apriPosizioni: () -> Void

    @State private var notaNuova = ""
    private typealias P = Tema.Apple.PraticheDopo
    private typealias D = Tema.Apple.PraticheDopo.Dettaglio

    var body: some View {
        let s = pratica
        let cliente = stato.cliente(s.clienteId)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: D.spazioIntestazione) {
                AvatarCliente(iniziali: cliente?.iniziali ?? "", tinta: (cliente?.tinta ?? .blu).colori, lato: D.avatar)
                VStack(alignment: .leading, spacing: D.spazioRighePasso * 2) {
                    HStack(spacing: D.spazioControlli) {
                        Text("Pratica dopo la firma")
                            .carattereApple(D.occhiello)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        EtichettaCanaleApple(canale: s.canale, compatta: true)
                    }
                    Text(cliente?.nome ?? "Cliente non trovato")
                        .carattereApple(D.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(1)
                    Text(s.posizione.nome + " · aperta il " + Formati.giornoMese.string(from: s.pratica.apertaIl))
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(1)
                }
                Spacer(minLength: D.spazioIntestazione)
                VStack(alignment: .trailing, spacing: D.spazioRighePasso) {
                    Text(s.testoStato)
                        .carattereApple(Tema.Apple.Carattere.valore)
                        .foregroundColor(s.conclusa ? Tema.Apple.Colore.verde : (s.ferma ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro))
                    Text(s.nota)
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(1)
                }
                .padding(.trailing, D.margineChiudi - Tema.Apple.Misura.Padding.dettaglio.trailing)
            }
            HStack(alignment: .top, spacing: D.spazioColonne) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: D.spazioPassi) {
                        ForEach(s.passi) { p in rigaPasso(p) }
                        if !(s.pratica.nonPertinenti ?? []).isEmpty {
                            Text("Passi che per questa pratica non servono: "
                                 + (s.pratica.nonPertinenti ?? []).compactMap { PassoPratica(rawValue: $0)?.etichetta(s.canale) }
                                    .joined(separator: ", "))
                                .carattereApple(Tema.Apple.Carattere.secondario)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                    }
                }
                .frame(width: D.colonnaSinistra)
                ScrollView(.vertical, showsIndicators: false) {
                    colonnaDestra(s)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, D.sopraPassi)
            Spacer(minLength: D.spazioIntestazione)
            HStack(spacing: D.spazioPallino) {
                Button("Apri in Posizioni", action: apriPosizioni)
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                if !s.conclusa {
                    Button(stato.sollecitoPronto(s.pratica) ? "✓ Sollecito pronto"
                           : (s.sollecitoCompagnia ? "Sollecita la compagnia" : "Sollecita")) {
                        stato.sollecitaPratica(s.id)
                    }
                    .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func rigaPasso(_ p: PassoCalcolato) -> some View {
        VStack(alignment: .leading, spacing: D.spazioPassi) {
            HStack(alignment: .firstTextBaseline, spacing: D.spazioPallino) {
                PallinoPasso(stato: p.stato)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + D.allineaPallino }
                VStack(alignment: .leading, spacing: D.spazioRighePasso) {
                    Text(p.etichetta)
                        .carattereApple(D.titoloPasso)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(TestiPratiche.dettaglio(p))
                        .carattereApple(D.righePasso)
                        .foregroundColor(p.stato == .bloccato ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let n = p.nota, !n.isEmpty {
                        Text(n)
                            .carattereApple(D.righePasso)
                            .foregroundColor(Tema.Apple.Colore.inchiostro3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            ControlliPasso(stato: stato, pratica: pratica, passo: p, compatto: true)
                .padding(.leading, P.pallino + D.spazioPallino)
        }
        .padding(D.paddingPasso)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: D.raggioPasso, style: .continuous).fill(D.fondoPasso)
        }
    }

    private func colonnaDestra(_ s: StatoPratica) -> some View {
        let documenti = stato.dati.documenti.filter { $0.posizioneId == s.posizione.id }
            .sorted { $0.importatoIl > $1.importatoIl }
        let note = (s.pratica.note ?? []).sorted { $0.data > $1.data }
        return VStack(alignment: .leading, spacing: D.spazioSezione) {
            Text("Documenti collegati")
                .carattereApple(D.titoloSezione)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            if documenti.isEmpty {
                Text("Nessun documento collegato a questa posizione.")
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            ForEach(documenti) { d in
                HStack(spacing: D.spazioControlli) {
                    Text(d.tipo.breve)
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro3)
                    Text(d.titolo)
                        .carattereApple(Tema.Apple.Carattere.corpo)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(1)
                }
            }
            Text("Note")
                .carattereApple(D.titoloSezione)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .padding(.top, D.sopraSezione)
            HStack(spacing: D.spazioControlli) {
                TextField("Una nota di lavoro", text: $notaNuova)
                    .campoTesto()
                    .onSubmit(aggiungi)
                Button("Aggiungi", action: aggiungi)
                    .buttonStyle(.apple)
                    .disabled(notaNuova.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .disabled(stato.solaLettura)
            ForEach(Array(note.enumerated()), id: \.offset) { _, n in
                VStack(alignment: .leading, spacing: D.spazioRighePasso) {
                    Text(Formati.giornoMese.string(from: n.data))
                        .carattereApple(D.notaData)
                        .foregroundColor(Tema.Apple.Colore.inchiostro3)
                    Text(n.testo)
                        .carattereApple(D.notaTesto)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func aggiungi() {
        stato.aggiungiNotaPratica(pratica.id, notaNuova)
        notaNuova = ""
    }
}
