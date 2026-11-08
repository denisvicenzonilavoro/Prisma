import SwiftUI

// Le schede della fase 1 di Vera sotto la risposta (app Vera, Vera della scrivania, iPhone e iPad), come nel template
// Design/template-vera.html: la scheda di conferma di «Fallo tu» (righe con app, titolo e dettaglio; «Conferma» e
// «Modifica»; dopo l'esecuzione le spunte e «Annulla»), la tabella di «Chiedi alla tua clientela» (i filtri capiti,
// i clienti, il canale) e le fonti di «Mai a caso» (ogni cifra con la sua origine; «non trovato» in rosso).

/// La scheda di conferma: niente si esegue prima di «Conferma».
struct SchedaConfermaVeraVista: View {
    @Environment(StatoShell.self) var stato
    let scheda: SchedaConfermaVera
    /// Il messaggio di Vera che la contiene.
    let messaggio: String
    @State private var tutte = false
    @Environment(\.modoIstantanea) private var istantanea

    private typealias T = Tema.Apple.ConfermaVera

    var body: some View {
        let _ = ContaCorpi.segna()
        let visibili = scheda.azioni.filter { !$0.tolta }
        let mostrate = tutte || istantanea ? visibili : Array(visibili.prefix(T.righeVisibili))
        VStack(alignment: .leading, spacing: 0) {
            // «Crea N attività» della clientela: i clienti sono già nella tabella sopra, qui solo i pulsanti
            if scheda.origine != .clientela {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(mostrate.enumerated()), id: \.element.id) { i, a in
                    riga(a)
                        .overlay(alignment: .top) {
                            if i > 0 { Rectangle().fill(T.filetto).frame(height: Tema.Apple.Misura.bordo) }
                        }
                }
                if mostrate.count < visibili.count {
                    Button("e altre \(visibili.count - mostrate.count)") { tutte = true }
                        .buttonStyle(.appleSobrio)
                        .padding(T.paddingRiga)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: T.raggio, style: .continuous))
            .superficieApple(T.superficie, raggio: T.raggio)
            .opacity(scheda.stato == .annullata || scheda.stato == .sostituita || scheda.stato == .rinunciata ? T.opacitaAnnullata : 1)
            }
            pulsanti
                .padding(.top, T.sopraPulsanti)
        }
    }

    private func riga(_ a: AzioneConferma) -> some View {
        HStack(alignment: .top, spacing: T.spazioRiga) {
            IconaApp(app: a.app, lato: T.icona)
            VStack(alignment: .leading, spacing: 2) {
                Text(a.titolo)
                    .carattereApple(T.titolo)
                    .foregroundColor(T.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
                Text(a.dettaglio)
                    .carattereApple(T.dettaglio)
                    .foregroundColor(T.coloreDettaglio)
                    .lineLimit(T.lineeDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
                if let e = a.esito, !e.fatta {
                    Text(e.messaggio)
                        .carattereApple(T.avviso)
                        .foregroundColor(T.nonFatto)
                        .padding(.top, T.sopraAvviso)
                } else if let avviso = a.avviso, scheda.stato == .daConfermare {
                    Label(avviso, systemImage: "exclamationmark.triangle.fill")
                        .carattereApple(T.avviso)
                        .foregroundColor(T.coloreAvviso)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, T.sopraAvviso)
                }
            }
            Spacer(minLength: 0)
            segno(a)
        }
        .padding(T.paddingRiga)
    }

    @ViewBuilder
    private func segno(_ a: AzioneConferma) -> some View {
        switch scheda.stato {
        case .daConfermare:
            if scheda.attive.count > 1 {
                Button {
                    stato.togliAzioneVera(a.id, messaggio: messaggio)
                } label: {
                    Image(systemName: "xmark")
                        .carattereApple(T.segnoCarattere)
                        .foregroundColor(T.coloreDettaglio)
                        .frame(width: T.segno, height: T.segno)
                        .background(Circle().fill(T.fondoSegno))
                }
                .buttonStyle(.plain)
                .help("Togli questa azione dalla scheda")
            }
        case .eseguita, .annullata:
            if let e = a.esito {
                Image(systemName: e.annullata ? "arrow.uturn.backward.circle.fill" : (e.fatta ? "checkmark.circle.fill" : "xmark.circle.fill"))
                    .font(.system(size: T.segno))
                    .foregroundColor(e.annullata ? T.coloreTolta : (e.fatta ? T.fatto : T.nonFatto))
                    .transition(.scale.combined(with: .opacity))
            }
        case .sostituita, .rinunciata:
            EmptyView()
        }
    }

    private var titoloConferma: String {
        switch scheda.origine {
        case .clientela: return "Crea \(scheda.attive.count == 1 ? "1 attività" : "\(scheda.attive.count) attività")"
        case .memoria: return scheda.attive.count == 1 ? "Ricorda" : "Ricorda tutto"
        case .documento: return "Conferma e archivia"
        case .regole, .qwen: return "Conferma"
        }
    }

    @ViewBuilder
    private var pulsanti: some View {
        HStack(spacing: T.spazioPulsanti) {
            switch scheda.stato {
            case .daConfermare:
                if !scheda.attive.isEmpty {
                    Button(titoloConferma) {
                        withAnimation(T.spunta) { stato.confermaSchedaVera(messaggio: messaggio) }
                    }
                    .buttonStyle(.applePrimario)
                    if scheda.origine == .memoria || scheda.origine == .documento {
                        Button(scheda.origine == .memoria ? "No, grazie" : "Lascia stare") { stato.lasciaStareSchedaVera(messaggio: messaggio) }
                            .buttonStyle(.apple)
                    } else if scheda.origine != .clientela {
                        Button("Modifica") { stato.modificaSchedaVera(messaggio: messaggio) }
                            .buttonStyle(.apple)
                    }
                }
            case .eseguita:
                let riuscite = scheda.attive.filter { $0.esito?.fatta == true }.count
                let tutte = riuscite == scheda.attive.count
                Label(riuscite == 0 ? "Non fatto" : (tutte ? (scheda.origine == .clientela ? "Attività create" : "Fatto") : "Fatto in parte"),
                      systemImage: riuscite == 0 ? "xmark" : "checkmark")
                    .carattereApple(T.stato)
                    .foregroundColor(riuscite == 0 ? T.nonFatto : T.fatto)
                if scheda.attive.contains(where: { $0.esito?.fatta == true && RegistroStrumenti.strumento($0.strumento)?.annullabile != false }) {
                    Button("Annulla") { stato.annullaSchedaVera(messaggio: messaggio) }
                        .buttonStyle(.apple)
                }
            case .annullata, .sostituita, .rinunciata:
                Text(scheda.intestazione)
                    .carattereApple(T.stato)
                    .foregroundColor(T.coloreDettaglio)
            }
        }
    }
}

/// «Chiedi alla tua clientela»: i filtri capiti, la frase di Prisma e la tabella dei clienti.
struct TabellaClientelaVista: View {
    @Environment(StatoShell.self) var stato
    let risultato: RisultatoClientela
    @State private var tutte = false
    @Environment(\.modoIstantanea) private var istantanea

    private typealias T = Tema.Apple.ClientelaVera

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 0) {
            filtri
            if !risultato.righe.isEmpty {
                tabella
                    .padding(.top, T.sopraTabella)
            }
        }
        .padding(.top, T.sopraFiltri)
    }

    private var filtri: some View {
        FlussoEtichette(spazio: T.spazioFiltri) {
            ForEach(risultato.etichette, id: \.self) { e in
                Text(e)
                    .carattereApple(T.filtro)
                    .foregroundColor(T.testoFiltro)
                    .padding(T.paddingFiltro)
                    .background(Capsule().fill(T.fondoFiltro))
            }
            Text("Tutti i \(risultato.totale) clienti")
                .carattereApple(T.filtro)
                .foregroundColor(T.testoTutti)
                .padding(T.paddingFiltro)
                .background(Capsule().fill(T.fondoTutti))
        }
    }

    private var tabella: some View {
        let righe = tutte || istantanea ? risultato.righe : Array(risultato.righe.prefix(T.righeVisibili))
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(risultato.colonne.dropLast().enumerated()), id: \.offset) { _, c in
                    Text(c)
                        .carattereApple(T.intestazione)
                        .foregroundColor(T.coloreIntestazione)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(risultato.colonne.last ?? "")
                    .carattereApple(T.intestazione)
                    .foregroundColor(T.coloreIntestazione)
                    .lineLimit(1)
                    .frame(width: T.colonnaCanale, alignment: .leading)
            }
            .padding(T.cella)
            .background(T.fondoIntestazione)
            ForEach(righe) { r in
                HStack(spacing: 0) {
                    HStack(spacing: 8) {
                        if let c = stato.cliente(r.id) {
                            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: T.avatar)
                        }
                        Text(r.nome).carattereApple(T.nome).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(r.valori.enumerated()), id: \.offset) { _, v in
                        Text(v)
                            .carattereApple(T.voce)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(spacing: 4) {
                        ForEach(r.canali, id: \.self) { EtichettaCanaleApple(canale: $0, compatta: true) }
                    }
                    .frame(width: T.colonnaCanale, alignment: .leading)
                }
                .foregroundColor(T.coloreVoce)
                .padding(T.cella)
                .overlay(alignment: .top) { Rectangle().fill(T.filetto).frame(height: Tema.Apple.Misura.bordo) }
                .contentShape(Rectangle())
                .onTapGesture { stato.mostraClienteDaVera(r.id) }
            }
            if righe.count < risultato.righe.count {
                Button("e altri \(risultato.righe.count - righe.count) clienti") { tutte = true }
                    .buttonStyle(.appleSobrio)
                    .padding(T.cella)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: T.raggio, style: .continuous))
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: T.raggio)
    }
}

/// «Mai a caso»: «✓ 3 cifre controllate con Prisma», «1 cifra non trovata» e, aperte, le fonti numerate.
struct FontiVeraVista: View {
    let fonti: [FonteCifra]
    @State private var aperte = false
    @Environment(\.modoIstantanea) private var istantanea

    private typealias T = Tema.Apple.FontiVera

    var body: some View {
        let trovate = fonti.filter(\.trovata).count
        let mancanti = fonti.count - trovate
        VStack(alignment: .leading, spacing: T.spazio) {
            Button {
                withAnimation(Tema.Apple.ConfermaVera.spunta) { aperte.toggle() }
            } label: {
                HStack(spacing: T.spazio) {
                    if trovate > 0 {
                        pillola("✓ \(trovate == 1 ? "1 cifra controllata" : "\(trovate) cifre controllate") con Prisma", T.testoControllata, T.fondoControllata)
                    }
                    if mancanti > 0 {
                        pillola(mancanti == 1 ? "1 cifra non trovata" : "\(mancanti) cifre non trovate", T.testoNonTrovata, T.fondoNonTrovata)
                    }
                    // Con una cifra non trovata le fonti restano aperte: niente pulsante che non farebbe niente
                    if !mostraSempre {
                        pillola(aperte ? "Nascondi le fonti" : "Le fonti", T.testoPillola, T.fondoPillola)
                    }
                }
            }
            .buttonStyle(.plain)
            if aperte || mostraSempre {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(fonti.enumerated()), id: \.element.id) { i, f in
                        voce(f)
                            .overlay(alignment: .top) {
                                if i > 0 { Rectangle().fill(T.filetto).frame(height: Tema.Apple.Misura.bordo) }
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: T.raggio, style: .continuous))
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: T.raggio)
            }
        }
        .padding(.top, T.sopra)
    }

    /// Una cifra non trovata si vede sempre (e nelle istantanee tutto aperto).
    private var mostraSempre: Bool { istantanea || fonti.contains { !$0.trovata } }

    private func pillola(_ testo: String, _ colore: Color, _ fondo: Color) -> some View {
        Text(testo)
            .carattereApple(T.pillola)
            .foregroundColor(colore)
            .padding(T.paddingPillola)
            .background(Capsule().fill(fondo))
    }

    private func voce(_ f: FonteCifra) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(f.id))
                .carattereApple(T.numero)
                .foregroundColor(T.coloreDettaglio)
                .frame(width: T.latoNumero, height: T.latoNumero)
                .background(Circle().fill(T.fondoNumero))
            if let app = f.app { IconaApp(app: app, lato: T.icona) }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(f.testo)
                        .carattereApple(T.cifra)
                        .foregroundColor(f.trovata ? T.coloreOrigine : T.testoNonTrovata)
                    Text(f.origine)
                        .carattereApple(T.origine)
                        .foregroundColor(f.trovata ? T.coloreOrigine : T.testoNonTrovata)
                        .lineLimit(1)
                }
                Text(f.dettaglio)
                    .carattereApple(T.dettaglio)
                    .foregroundColor(T.coloreDettaglio)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(T.paddingVoce)
    }
}

/// Le etichette che vanno a capo quando la riga è piena (i filtri capiti da Vera).
struct FlussoEtichette: Layout {
    var spazio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezza = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, riga: CGFloat = 0, massimo: CGFloat = 0
        for s in subviews {
            let d = s.sizeThatFits(.unspecified)
            if x > 0, x + d.width > larghezza { x = 0; y += riga + spazio; riga = 0 }
            x += d.width + spazio
            riga = max(riga, d.height)
            massimo = max(massimo, x - spazio)
        }
        return CGSize(width: min(massimo, larghezza), height: y + riga)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, riga: CGFloat = 0
        for s in subviews {
            let d = s.sizeThatFits(.unspecified)
            if x > bounds.minX, x + d.width > bounds.maxX { x = bounds.minX; y += riga + spazio; riga = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(d))
            x += d.width + spazio
            riga = max(riga, d.height)
        }
    }
}
