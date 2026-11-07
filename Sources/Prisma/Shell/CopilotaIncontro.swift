#if os(iOS)
import UIKit
#endif
import SwiftUI

// Incontri › Il copilota dell'incontro (Orizzonte, giro 5; Design/template-novita-specifica.md §8), nel passo «Ascolto»:
//
//   ┌─ OGGI ─────────────────┐  ┌─ ◉ Il punto sul progetto casa · Ascolto · 00:09 · solo sul Mac ▮▮▮▯▮▮  [■ Termina] ┐
//   │ ◉ Giulia Rossi         │  └───────────────────────────────────────────────────────────────────────────────────┘
//   │   09:30 · Il punto…    │  ┌─ QUELLO CHE VI STATE DICENDO ────────┐  ┌─ OBIETTIVO RICONOSCIUTO ─────────────┐
//   │ ┌ ✓ Consenso ───────┐ │  │ Denis  Allora Giulia, partiamo…      │  │ Casa tra 3 anni · 40.000 €           │
//   │ └───────────────────┘ │  │ Giulia Vorremmo comprare [tra tre…]  │  │ → Aggiorna l’obiettivo [Conferma] …  │
//   │ ┌ Come funziona ────┐ │  │ …                                    │  └──────────────────────────────────────┘
//   └─┴───────────────────┴─┘  └──────────────────────────────────────┘
//
// - Senza consenso del cliente non parte niente: la scheda del consenso è arancio e chiede di registrarlo (data e modo).
// - Durante l'ascolto le frasi scorrono con le parole riconosciute illuminate; a destra le schede compaiono una alla
//   volta. «Conferma» porta la scheda nel dossier (con l'avviso), «Scarta» la toglie; niente entra da solo.
// - «■ Termina» apre il verbale dal pulsante (Shell/VerbaleCopilota.swift).
// - Sull'iPad il riconoscimento è dell'iPad e le schede vanno al Mac sul ponte cifrato; senza il Mac restano sull'iPad
//   in attesa, e lo si dice. La conferma nel dossier si dà sul Mac.
// - «Riduci movimento»: righe e schede compaiono già ferme; istantanee: tutto nello stato finale (onda fissa, contatore
//   dichiarato). Valori in DesignSystem/Apple/Tema.Apple+Copilota.swift.

/// Il passo «Ascolto» di Incontri: il copilota (sul Mac e sull'iPad) o le tre domande scritte con gli appunti.
@MainActor
struct SceltaAscoltoIncontri<Quaderno: View>: View {
    @ObservedObject var copilota: StatoCopilotaIncontro
    let ascolto: Bool
    let clienteId: String
    let incontro: Incontro?
    @ViewBuilder let quaderno: () -> Quaderno

    var body: some View {
        if ascolto && copilota.modo == .copilota && CopilotaIncontro.disponibile {
            CopilotaIncontro(copilota: copilota, clienteId: clienteId, incontro: incontro)
        } else {
            quaderno()
        }
    }
}

@MainActor
struct CopilotaIncontro: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let clienteId: String
    let incontro: Incontro?

    private typealias D = Tema.Apple.Copilota.Disposizione

    /// Sul Mac e sull'iPad; sull'iPhone resta il quaderno (la gerarchia del telefono arriverà a parte).
    static var disponibile: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return true
        #endif
    }

    static var suIPad: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        let cliente = stato.cliente(clienteId)
        let sessione = copilota.sessione(per: clienteId, in: stato)
        return GeometryReader { geo in
            let stretta = geo.size.width < D.sogliaStretta
            Group {
                if stretta {
                    VStack(alignment: .leading, spacing: D.spazio) {
                        SchedaConsensoCopilota(copilota: copilota, cliente: cliente, compatta: true)
                        principale(cliente: cliente, sessione: sessione, stretta: true, larghezza: geo.size.width)
                    }
                } else {
                    HStack(alignment: .top, spacing: D.gioco) {
                        ColonnaOggiCopilota(copilota: copilota, clienteId: clienteId, incontro: incontro, cliente: cliente)
                            .frame(width: D.larghezzaColonna)
                            .frame(maxHeight: .infinity, alignment: .top)
                        principale(cliente: cliente, sessione: sessione, stretta: false,
                                   larghezza: geo.size.width - D.larghezzaColonna - D.gioco)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .presentatoreDettaglio(copilota.dettaglio) { _ in
            VerbaleCopilotaVista(copilota: copilota, clienteId: clienteId, incontro: incontro)
        }
        // La schermata se ne va (cambio di app, finestra chiusa, cambio di passo): l'ascolto si ferma subito
        .onDisappear { copilota.interrompi() }
    }

    private func principale(cliente: Cliente?, sessione: SessioneCopilota?, stretta: Bool, larghezza: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: D.spazio) {
            // L'onda sta nella testata solo se c'è posto per titoli, onda e pulsante (sull'iPad in verticale no):
            // così la testata non allarga mai l'area principale oltre la finestra.
            TestataCopilota(copilota: copilota, cliente: cliente, incontro: incontro, sessione: sessione,
                            conOnda: larghezza >= Tema.Apple.Copilota.Testata.larghezzaMinimaConOnda)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            GeometryReader { g in
                let schede = ColonnaSchedeCopilota(copilota: copilota, sessione: sessione)
                let trascrizione = TrascrizioneCopilotaVista(copilota: copilota, sessione: sessione, cliente: cliente)
                if stretta {
                    let alta = max(0, (g.size.height - D.spazio) * D.quotaTrascrizioneStretta)
                    VStack(spacing: D.spazio) {
                        trascrizione.frame(width: g.size.width, height: alta)
                        schede.frame(width: g.size.width, height: max(0, g.size.height - D.spazio - alta))
                    }
                } else {
                    let totale = D.quotaTrascrizione + D.quotaSchede
                    let larga = max(0, (g.size.width - D.spazio) * D.quotaTrascrizione / totale)
                    HStack(alignment: .top, spacing: D.spazio) {
                        trascrizione.frame(width: larga, height: g.size.height)
                        schede.frame(width: max(0, g.size.width - D.spazio - larga), height: g.size.height)
                    }
                }
            }
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - La colonna «Oggi»

/// Gli incontri di oggi (dagli appuntamenti con un cliente), il consenso del cliente scelto, «Come funziona» e, in
/// fondo, il resto dell'incontro (le domande scritte, i prossimi passi). Durante l'ascolto le altre righe sono spente:
/// un solo ascolto alla volta.
@MainActor
struct ColonnaOggiCopilota: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let clienteId: String
    let incontro: Incontro?
    let cliente: Cliente?

    private typealias C = Tema.Apple.Copilota.Colonna

    private var oggi: [Appuntamento] {
        let cal = Calendar.current
        return stato.dati.appuntamenti
            .filter { cal.isDateInToday($0.inizio) && stato.cliente($0.clienteId) != nil }
            .sorted { $0.inizio < $1.inizio }
    }

    var body: some View {
        let elenco = oggi
        return VStack(alignment: .leading, spacing: 0) {
            Text("Oggi")
                .carattereApple(C.occhiello)
                .foregroundColor(C.coloreOcchiello)
                .padding(.bottom, C.sottoOcchiello)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if elenco.isEmpty {
                        VStack(alignment: .leading, spacing: C.spazioVuoto) {
                            Text(TestiCopilota.nessunIncontro)
                                .carattereApple(C.vuoto)
                                .foregroundColor(C.coloreVuoto)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(TestiCopilota.senzaAppuntamento) { senzaAppuntamento() }
                                .buttonStyle(.apple)
                                .disabled(copilota.ascolta || stato.cliente(clienteId) == nil)
                        }
                        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                    } else {
                        VStack(alignment: .leading, spacing: C.fraVoci) {
                            ForEach(Array(elenco.enumerated()), id: \.element.id) { n, a in
                                VoceOggiCopilota(appuntamento: a, cliente: stato.cliente(a.clienteId),
                                                 scelta: a.id == incontro?.appuntamentoId,
                                                 spenta: copilota.ascolta && a.id != incontro?.appuntamentoId) {
                                    scegli(a)
                                }
                                .entrataCascata(n, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                            }
                        }
                    }
                    SchedaConsensoCopilota(copilota: copilota, cliente: cliente, compatta: false)
                        .padding(.top, Tema.Apple.Copilota.Consenso.sopra)
                        .entrataCascata(min(elenco.count, 4) + 1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                    ComeFunzionaCopilota()
                        .padding(.top, Tema.Apple.Copilota.Consenso.sopraComeFunziona)
                        .entrataCascata(min(elenco.count, 4) + 2, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            CollegamentiCopilota(copilota: copilota)
                .padding(.top, C.sopraCollegamenti)
        }
        .padding(C.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(C.superficie, raggio: C.raggio)
    }

    /// Un incontro di oggi: si apre (o si crea) quello dell'appuntamento e si resta sul copilota.
    private func scegli(_ a: Appuntamento) {
        guard !copilota.ascolta, a.id != incontro?.appuntamentoId else { return }
        copilota.azzera()
        stato.clienteAttivoId = a.clienteId
        if let i = stato.dati.incontri.first(where: { $0.appuntamentoId == a.id }) {
            stato.incontroAperto = i.id
        } else {
            stato.nuovoIncontro(cliente: a.clienteId, appuntamento: a)
        }
        stato.schedaIncontro = .ascolto
    }

    /// Nessun appuntamento oggi: un incontro nuovo con il cliente scelto, subito nel copilota.
    private func senzaAppuntamento() {
        guard !copilota.ascolta, stato.cliente(clienteId) != nil else { return }
        copilota.azzera()
        stato.nuovoIncontro(cliente: clienteId)
        stato.schedaIncontro = .ascolto
    }
}

/// Una riga di «Oggi» (`.rub`): avatar 38, nome 14 bold, sotto «ora · titolo».
@MainActor
struct VoceOggiCopilota: View {
    let appuntamento: Appuntamento
    let cliente: Cliente?
    let scelta: Bool
    let spenta: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    private typealias C = Tema.Apple.Copilota.Colonna

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: C.raggioVoce, style: .continuous)
        return Button(action: azione) {
            HStack(spacing: C.spazioAvatar) {
                if let c = cliente {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: C.avatar)
                }
                VStack(alignment: .leading, spacing: C.spazioTitoli) {
                    Text(cliente?.nome ?? "Cliente")
                        .carattereApple(C.nome)
                        .foregroundColor(C.coloreNome)
                        .lineLimit(1)
                    Text("\(Formati.ora.string(from: appuntamento.inizio)) · \(appuntamento.titolo)")
                        .carattereApple(C.sottotitolo)
                        .foregroundColor(C.coloreSottotitolo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: C.larghezzaSottotitolo, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .padding(C.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if scelta {
                    forma.fill(C.fondoScelta)
                } else if sopra {
                    forma.fill(C.fondoSopra)
                }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .disabled(spenta)
        .opacity(spenta ? C.opacitaSpenta : 1)
        .onHover { dentro in sopra = dentro && !istantanea }
        .animation(Tema.Apple.Moto.animazione(C.animazioneFondo, calmo: calmo, istantanea: istantanea), value: scelta)
        .animation(Tema.Apple.Moto.animazione(C.animazioneFondo, calmo: calmo, istantanea: istantanea), value: sopra)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

/// In fondo alla colonna: le domande scritte e gli appunti, e i prossimi passi dell'incontro.
@MainActor
struct CollegamentiCopilota: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro

    var body: some View {
        // Affiancati se ci stanno interi, altrimenti uno sotto l'altro (la colonna è stretta): mai troncati
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Tema.Apple.Copilota.Colonna.spazioCollegamenti) { collegamenti }
            VStack(alignment: .leading, spacing: Tema.Apple.Copilota.Colonna.spazioCollegamenti) { collegamenti }
        }
        .disabled(copilota.ascolta)
        .help(copilota.ascolta ? "Termina l’ascolto per passare alle domande scritte o ai prossimi passi." : "")
    }

    @ViewBuilder private var collegamenti: some View {
        Button { copilota.modo = .appunti } label: { Label("Domande e appunti", systemImage: "square.and.pencil").fixedSize() }
            .buttonStyle(.appleSobrio)
        Button { stato.schedaIncontro = .passi } label: { Label("Prossimi passi", systemImage: "arrow.right").fixedSize() }
            .buttonStyle(.appleSobrio)
    }
}

// MARK: - Il consenso

/// La scheda del consenso all'ascolto: verde se il cliente l'ha dato (con data e modo, e «Revoca»), arancio se manca,
/// con il modulo per registrarlo. Senza consenso il copilota non parte.
@MainActor
struct SchedaConsensoCopilota: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let cliente: Cliente?
    /// Nella disposizione stretta (iPad in verticale): in riga, sopra la testata.
    let compatta: Bool

    @State private var modo = ConsensoCopilota.Modo.aVoce
    @State private var nota = ""
    @State private var data = Date()
    @State private var chiediRevoca = false

    private typealias K = Tema.Apple.Copilota.Consenso

    var body: some View {
        let consenso = cliente?.consensoCopilota
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Tema.Apple.Copilota.Testata.spazioIndicatore) {
                Image(systemName: consenso == nil ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(consenso == nil ? K.coloreSegnoMancante : K.coloreSegnoDato)
                Text("Consenso all’ascolto")
                    .carattereApple(K.titolo)
                    .foregroundColor(K.coloreTitolo)
                Spacer(minLength: 0)
                if consenso != nil {
                    Button("Revoca") { chiediRevoca = true }
                        .buttonStyle(.appleSobrio)
                        .help("Il consenso esce dal dossier; un ascolto in corso si ferma")
                }
            }
            Text(testo(consenso))
                .carattereApple(K.testo)
                .foregroundColor(K.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, K.sottoTitolo)
            if cliente?.canali.contains(.alleanza) == true {
                Text(TestiCopilota.alleanza)
                    .carattereApple(K.alleanza)
                    .foregroundColor(K.coloreAlleanza)
                    .padding(.top, K.sottoTitolo)
            }
            if consenso == nil, cliente != nil {
                modulo
                    .padding(.top, K.sopraModulo)
            }
        }
        .padding(K.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(consenso == nil ? K.superficieMancante : K.superficieData, raggio: K.raggio)
        .alert("Revocare il consenso all’ascolto?", isPresented: $chiediRevoca) {
            Button("Annulla", role: .cancel) {}
            Button("Revoca", role: .destructive) { revoca() }
        } message: {
            Text("Il copilota non ascolterà più gli incontri con questo cliente finché non registri di nuovo il consenso. Le schede già confermate restano nel dossier.")
        }
    }

    private func testo(_ c: ConsensoCopilota?) -> String {
        guard let cliente else { return GuardiaCopilota.senzaCliente }
        if let c { return TestiCopilota.consensoDato(cliente.nome, c) }
        return TestiCopilota.consensoMancante(cliente.nome)
    }

    /// Il testo da leggere al cliente (di prova), il modo, la data e una nota; poi «Registra il consenso».
    private var modulo: some View {
        VStack(alignment: .leading, spacing: K.spazioModulo) {
            Text(TestiCopilota.testoConsenso)
                .carattereApple(K.testo)
                .foregroundColor(K.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
                .padding(K.paddingNota)
                .background(RoundedRectangle(cornerRadius: K.raggioNota, style: .continuous).fill(K.fondoNota))
            SegmentatoPillola(selezione: $modo, valori: ConsensoCopilota.Modo.allCases, titolo: { $0.nome })
            DatePicker("Quando", selection: $data, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .carattereApple(K.nota)
            TextField("Nota (facoltativa)", text: $nota)
                .textFieldStyle(.roundedBorder)
                .carattereApple(K.nota)
            Button("Registra il consenso") { registra() }
                .buttonStyle(.applePrimario)
                .disabled(stato.solaLettura)
        }
    }

    private func registra() {
        guard let c = cliente else { return }
        // Mai nel futuro: la guardia non lo accetterebbe
        stato.registraConsensoCopilota(clienteId: c.id, modo: modo, nota: nota, data: min(data, Date()))
        nota = ""
        stato.mostraAvviso("Consenso di \(TestiCopilota.primoNome(c.nome)) all’ascolto registrato nel dossier.")
    }

    private func revoca() {
        guard let c = cliente else { return }
        copilota.interrompi()
        stato.revocaConsensoCopilota(clienteId: c.id)
        stato.mostraAvviso("Consenso all’ascolto di \(TestiCopilota.primoNome(c.nome)) revocato.")
    }
}

/// «Come funziona»: due righe, senza ombra.
struct ComeFunzionaCopilota: View {
    private typealias K = Tema.Apple.Copilota.Consenso

    var body: some View {
        VStack(alignment: .leading, spacing: K.sottoOcchielloComeFunziona) {
            Text("Come funziona")
                .carattereApple(Tema.Apple.Copilota.Colonna.occhiello)
                .foregroundColor(Tema.Apple.Copilota.Colonna.coloreOcchiello)
            Text(TestiCopilota.comeFunziona)
                .carattereApple(K.testoComeFunziona)
                .foregroundColor(K.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(K.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(K.superficieComeFunziona, raggio: K.raggio)
    }
}

// MARK: - La testata

/// Avatar 44, il titolo dell'incontro con lo stato sotto, l'onda della voce spinta a destra e il pulsante, da cui nasce
/// il verbale.
@MainActor
struct TestataCopilota: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let cliente: Cliente?
    let incontro: Incontro?
    let sessione: SessioneCopilota?
    var conOnda = true

    private typealias T = Tema.Apple.Copilota.Testata

    private var puoPartire: Bool { GuardiaCopilota.puoPartire(cliente) && !stato.solaLettura }

    var body: some View {
        HStack(alignment: .center, spacing: T.spazio) {
            if let c = cliente {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: T.avatar)
            }
            VStack(alignment: .leading, spacing: T.spazioTitoli) {
                Text(incontro?.titolo ?? "Incontro senza appuntamento")
                    .carattereApple(T.titolo)
                    .foregroundColor(T.coloreTitolo)
                    .lineLimit(1)
                statoAscolto
                Label(TestiCopilota.indicatore, systemImage: "lock.fill")
                    .carattereApple(T.indicatore)
                    .foregroundColor(T.coloreIndicatore)
                    .lineLimit(1)
            }
            .frame(minWidth: T.larghezzaMinimaTitoli, alignment: .leading)
            .layoutPriority(1)
            Spacer(minLength: 0)
            if conOnda {
                OndaNastroApple(livelli: copilota.livelli, ascolta: copilota.fase == .ascolto)
            }
            if !copilota.ascolta, let s = sessione, !(s.schede.isEmpty && s.trascrizione.isEmpty) {
                Button("Il verbale") { apriVerbale() }
                    .buttonStyle(.appleGrande)
                    .fixedSize()
            }
            pulsante
        }
        .padding(T.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(T.superficie, raggio: T.raggio)
    }

    /// Lo stato sotto il titolo: pronto, il contatore dell'ascolto (ogni secondo, solo durante l'ascolto), la durata
    /// dell'incontro concluso o interrotto, oppure in rosso il motivo per cui non si ascolta.
    @ViewBuilder private var statoAscolto: some View {
        if let p = copilota.problema {
            Text(p)
                .carattereApple(T.stato)
                .foregroundColor(T.coloreProblema)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else if copilota.fase == .ascolto, copilota.scena == nil {
            TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                riga(TestiCopilota.ascolto(copilota.secondi(ctx.date)))
            }
        } else {
            riga(testoStato)
        }
    }

    private func riga(_ t: String) -> some View {
        Text(t)
            .carattereApple(T.stato)
            .foregroundColor(T.coloreStato)
            .lineLimit(1)
    }

    private var testoStato: String {
        switch copilota.fase {
        case .prepara: return TestiCopilota.prepara
        case .ascolto: return TestiCopilota.ascolto(copilota.secondi())
        case .concluso: return TestiCopilota.concluso(copilota.secondi())
        case .interrotto: return TestiCopilota.interrotto(copilota.secondi())
        case .pronto:
            if let s = sessione, s.aperta, !s.schede.isEmpty { return TestiCopilota.daConfermare(s.schede.count) }
            return TestiCopilota.pronto
        }
    }

    /// «● Avvia il copilota» (rosso, spento senza consenso), «Annulla» mentre si prepara, «■ Termina» durante l'ascolto,
    /// «● Riprendi» dopo un'interruzione.
    private var pulsante: some View {
        let testo: String
        let fondo: Color
        switch copilota.fase {
        case .ascolto: testo = "■ Termina"; fondo = T.fondoTermina
        case .prepara: testo = "Annulla"; fondo = T.fondoTermina
        case .interrotto: testo = "● Riprendi"; fondo = T.fondoAvvia
        case .pronto, .concluso: testo = "● Avvia il copilota"; fondo = T.fondoAvvia
        }
        let attivo = copilota.ascolta || puoPartire
        return Button(action: premi) {
            Text(testo)
                .carattereApple(T.pulsante)
                .foregroundColor(T.testoPulsante)
                .lineLimit(1)
                .padding(T.paddingPulsante)
                .background(Capsule(style: .continuous).fill(fondo))
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(StilePremutoCopilota())
        .fixedSize()
        .disabled(!attivo)
        .opacity(attivo ? 1 : T.opacitaSpento)
        .origineDettaglio(id: StatoCopilotaIncontro.idVerbale)
        .help(attivo ? "" : (GuardiaCopilota.motivoBlocco(cliente) ?? "Archivio in sola lettura."))
    }

    private func premi() {
        switch copilota.fase {
        case .ascolto:
            copilota.termina()
            apriVerbale()
        case .prepara:
            copilota.annulla()
        case .pronto, .concluso, .interrotto:
            guard let c = cliente else { return }
            copilota.avvia(stato, clienteId: c.id, incontroId: incontro?.id)
        }
    }

    private func apriVerbale() {
        copilota.dettaglio.apri(StatoCopilotaIncontro.idVerbale, misura: Tema.Apple.Copilota.Verbale.misura)
    }
}

/// Il pulsante grande del copilota premuto: scala 0,95 con la molla di 0,25 s (con «Riduci movimento» niente scala).
struct StilePremutoCopilota: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CorpoPremutoCopilota(etichetta: configuration.label, premuto: configuration.isPressed)
    }
}

private struct CorpoPremutoCopilota: View {
    let etichetta: ButtonStyleConfiguration.Label
    let premuto: Bool
    @Environment(\.prismaStatoFinale) private var fermo

    var body: some View {
        let m = Tema.Apple.Moto.PulsantePremuto.self
        return etichetta
            .scaleEffect(premuto && !fermo ? m.scala : 1)
            .animation(fermo ? nil : m.animazione, value: premuto)
    }
}

// MARK: - La trascrizione

/// «Quello che vi state dicendo»: le ultime sette righe (la più vecchia sparisce in alto), con chi parla (un tocco lo
/// cambia: un solo microfono non distingue le voci) e le parole riconosciute illuminate; in fondo la riga in corso.
@MainActor
struct TrascrizioneCopilotaVista: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let sessione: SessioneCopilota?
    let cliente: Cliente?

    private typealias R = Tema.Apple.Copilota.Trascrizione

    private var inCorso: String? {
        let t = copilota.rigaInCorso.trimmingCharacters(in: .whitespacesAndNewlines)
        return copilota.fase == .ascolto && !t.isEmpty ? t : nil
    }

    var body: some View {
        let riga = inCorso
        let pezzi = Array((sessione?.trascrizione ?? []).suffix(R.righeVisibili - (riga == nil ? 0 : 1)))
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiCopilota.occhielloTrascrizione)
                .carattereApple(R.occhiello)
                .foregroundColor(R.coloreOcchiello)
                .accessibilityAddTraits(.isHeader)
            if !copilota.conservaTrascrizione {
                Text(TestiCopilota.notaTrascrizione)
                    .carattereApple(R.nota)
                    .foregroundColor(R.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Tema.Apple.Copilota.Scheda.sopraFrase)
            }
            if pezzi.isEmpty && riga == nil {
                Text(copilota.ascolta ? TestiCopilota.ascoltoSenzaParole : TestiCopilota.vuotoTrascrizione)
                    .carattereApple(R.vuoto)
                    .foregroundColor(R.coloreVuoto)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(pezzi) { p in
                                RigaTrascrizioneCopilota(chi: nome(p), coloreChi: colore(p), testo: p.testo, evidenze: p.evidenze,
                                                         inCorso: false, indicata: copilota.indicata == p.id) {
                                    if let s = sessione { stato.cambiaChiCopilota(p.id, sessione: s.id) }
                                }
                                .id(p.id)
                                .entrataStile(.rigaCopilota)
                            }
                            if let riga {
                                RigaTrascrizioneCopilota(chi: "…", coloreChi: R.coloreSconosciuto, testo: riga,
                                                         evidenze: [], inCorso: true, indicata: false, cambiaChi: nil)
                                    .id(Self.idInCorso)
                            }
                        }
                        .padding(.top, R.sopraRighe)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onAppear {
                        if let id = riga == nil ? pezzi.last?.id : Self.idInCorso { proxy.scrollTo(id, anchor: .bottom) }
                    }
                    .onChange(of: pezzi.last?.id) { id in
                        if let id { proxy.scrollTo(id, anchor: .bottom) }
                    }
                    .onChange(of: riga) { r in
                        if r != nil { proxy.scrollTo(Self.idInCorso, anchor: .bottom) }
                    }
                    .onChange(of: copilota.indicata) { id in
                        guard let id, pezzi.contains(where: { $0.id == id }) else { return }
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .padding(R.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: R.raggio, style: .continuous))
        .superficieApple(R.superficie, raggio: R.raggio)
    }

    private static let idInCorso = "copilota-riga-in-corso"

    private func nome(_ p: PezzoTrascrizione) -> String {
        TestiCopilota.chi(p, consulente: stato.nomeUtente, cliente: cliente?.nome ?? "Cliente")
    }

    private func colore(_ p: PezzoTrascrizione) -> Color {
        switch p.chi {
        case .consulente: return R.coloreConsulente
        case .cliente: return cliente.map { Tema.Apple.Posizioni.coloreCliente($0.tinta) } ?? R.coloreSconosciuto
        case .sconosciuto: return R.coloreSconosciuto
        }
    }
}

/// Una riga della trascrizione: chi parla (largo 56) e il testo, parola per parola, con le evidenze.
struct RigaTrascrizioneCopilota: View {
    let chi: String
    let coloreChi: Color
    let testo: String
    let evidenze: [IntervalloTesto]
    let inCorso: Bool
    let indicata: Bool
    let cambiaChi: (() -> Void)?

    @Environment(\.prismaStatoFinale) private var fermo

    private typealias R = Tema.Apple.Copilota.Trascrizione

    var body: some View {
        let parole = ParolaCopilota.parole(testo, evidenze: evidenze)
        return HStack(alignment: .top, spacing: R.spazio) {
            etichetta
                .frame(width: R.larghezzaChi, alignment: .leading)
                .padding(.top, R.sopraChi)
            ParoleCopilota(spazio: R.spazioParole, interlinea: R.interlinea) {
                ForEach(parole) { p in
                    parola(p)
                        .layoutValue(key: AttaccataCopilota.self, value: p.attaccata)
                        .transition(fermo ? .identity : .opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(testo))
        }
        .padding(.vertical, R.paddingRiga)
        .background {
            if indicata {
                RoundedRectangle(cornerRadius: R.raggioRigaIndicata, style: .continuous).fill(R.fondoRigaIndicata)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Tema.Apple.Colore.separatore)
                .frame(height: Tema.Apple.Misura.bordo)
        }
    }

    @ViewBuilder private var etichetta: some View {
        let t = Text(chi)
            .carattereApple(R.chi)
            .foregroundColor(coloreChi)
            .lineLimit(1)
            .minimumScaleFactor(R.scalaMinimaChi)
        if let cambiaChi {
            Button(action: cambiaChi) { t }
                .buttonStyle(StileSemplice())
                .help("Chi parla: tocca per cambiare (tu, il cliente, non indicato)")
        } else {
            t
        }
    }

    @ViewBuilder private func parola(_ p: ParolaCopilota) -> some View {
        if p.evidenza {
            Text(p.testo)
                .carattereApple(R.evidenza)
                .foregroundColor(R.testoEvidenza)
                .padding(R.paddingEvidenza)
                .background(RoundedRectangle(cornerRadius: R.raggioEvidenza, style: .continuous).fill(R.fondoEvidenza))
                .fixedSize()
        } else {
            Text(p.testo)
                .carattereApple(R.testo)
                .foregroundColor(inCorso ? R.coloreInCorso : R.coloreTesto)
                .fixedSize()
        }
    }
}

/// Un pezzo del testo della riga: una parola, o un'evidenza intera («tra tre anni»), e se attacca alla precedente
/// senza spazio (la virgola dopo un'evidenza).
struct ParolaCopilota: Identifiable, Equatable {
    let id: Int
    let testo: String
    let evidenza: Bool
    let attaccata: Bool

    /// Le parole del testo con le evidenze (intervalli in caratteri) intere.
    static func parole(_ testo: String, evidenze: [IntervalloTesto]) -> [ParolaCopilota] {
        let lettere = Array(testo)
        let n = lettere.count
        var segnate = Array(repeating: false, count: n)
        for e in evidenze where e.inizio < n {
            for i in e.inizio..<min(e.fine, n) { segnate[i] = true }
        }
        var esito: [ParolaCopilota] = []
        var i = 0
        var spazioPrima = false
        while i < n {
            if lettere[i].isWhitespace && !segnate[i] {
                spazioPrima = true
                i += 1
                continue
            }
            let evidenza = segnate[i]
            var j = i
            if evidenza {
                while j < n && segnate[j] { j += 1 }
            } else {
                while j < n && !segnate[j] && !lettere[j].isWhitespace { j += 1 }
            }
            let pezzo = String(lettere[i..<j]).trimmingCharacters(in: .whitespaces)
            if !pezzo.isEmpty {
                esito.append(ParolaCopilota(id: esito.count, testo: pezzo, evidenza: evidenza,
                                            attaccata: !esito.isEmpty && !spazioPrima))
            }
            spazioPrima = j > i && lettere[j - 1].isWhitespace
            i = j
        }
        return esito
    }
}

/// La parola attacca alla precedente (niente spazio prima).
struct AttaccataCopilota: LayoutValueKey {
    static let defaultValue = false
}

/// Le parole a capo come un testo: lo spazio fra le parole (non prima della punteggiatura attaccata) e l'interlinea.
struct ParoleCopilota: Layout {
    var spazio: CGFloat
    var interlinea: CGFloat

    private func posizioni(larghezza: CGFloat, _ subviews: Subviews) -> (punti: [CGPoint], misura: CGSize) {
        var punti: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, riga: CGFloat = 0, destra: CGFloat = 0
        for s in subviews {
            let d = s.sizeThatFits(.unspecified)
            let prima = (x > 0 && !s[AttaccataCopilota.self]) ? spazio : 0
            if x > 0 && x + prima + d.width > larghezza {
                y += riga + interlinea
                x = 0
                riga = 0
            } else {
                x += prima
            }
            punti.append(CGPoint(x: x, y: y))
            x += d.width
            destra = max(destra, x)
            riga = max(riga, d.height)
        }
        return (punti, CGSize(width: destra, height: y + riga))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let finita = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let m = posizioni(larghezza: finita ?? .greatestFiniteMagnitude, subviews).misura
        return CGSize(width: finita ?? m.width, height: m.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let punti = posizioni(larghezza: bounds.width, subviews).punti
        for (s, p) in zip(subviews, punti) {
            s.place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
}

// MARK: - Le schede

/// La colonna delle schede: una per ogni cosa capita, nell'ordine in cui nascono, ognuna con l'azione, «Conferma» e
/// «Scarta». Sopra, quando serve, la nota su Vera non pronta e (sull'iPad) le schede in attesa del Mac.
@MainActor
struct ColonnaSchedeCopilota: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var copilota: StatoCopilotaIncontro
    let sessione: SessioneCopilota?

    private typealias S = Tema.Apple.Copilota.Scheda

    var body: some View {
        let schede = sessione?.schede ?? []
        let attiva = copilota.ascolta || !schede.isEmpty
        return VStack(alignment: .leading, spacing: 0) {
            if attiva && !copilota.qwenPronto(stato) {
                nota(TestiCopilota.veraNonPronta, colore: S.coloreNota)
            }
            if CopilotaIncontro.suIPad && copilota.inAttesaPonte > 0 {
                HStack(alignment: .firstTextBaseline, spacing: S.spazioPulsanti) {
                    nota(TestiCopilota.inAttesa(copilota.inAttesaPonte, motivo: copilota.motivoPonte), colore: S.coloreAttesa)
                    Button("Manda al Mac") { copilota.mandaAlMac(stato) }
                        .buttonStyle(.appleSobrio)
                        .disabled(copilota.invioInCorso)
                }
            }
            if schede.isEmpty {
                Text(TestiCopilota.vuotoSchede)
                    .carattereApple(S.vuoto)
                    .foregroundColor(S.coloreVuoto)
                    .multilineTextAlignment(.center)
                    .padding(S.paddingVuoto)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: S.fraSchede) {
                            ForEach(schede) { x in
                                SchedaCopilotaVista(scheda: x, suIPad: CopilotaIncontro.suIPad,
                                                    conferma: { conferma(x) }, scarta: { scarta(x) },
                                                    indica: { copilota.indicata = x.pezzoId })
                                    .id(x.id)
                                    .entrataStile(.schedaCopilota)
                            }
                        }
                        // Lo spazio per l'ombra delle schede
                        .padding(.vertical, S.fraSchede)
                        .padding(.horizontal, S.filo)
                    }
                    .onChange(of: schede.last?.id) { id in
                        guard let id else { return }
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func nota(_ t: String, colore: Color) -> some View {
        Text(t)
            .carattereApple(S.nota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, S.sottoNota)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// La conferma porta subito la scheda nel dossier (con l'avviso); niente entra senza questo gesto o il verbale.
    private func conferma(_ x: SchedaCopilota) {
        guard let s = sessione else { return }
        stato.confermaSchedeCopilota([x.id], sessione: s.id)
    }

    private func scarta(_ x: SchedaCopilota) {
        guard let s = sessione else { return }
        stato.scartaSchedaCopilota(x.id, sessione: s.id)
        copilota.mandaAlMacSeServe(stato)
    }
}

/// Una scheda: filo colorato a sinistra, occhiello nel colore del tipo, la frase, l'azione e i pulsanti.
struct SchedaCopilotaVista: View {
    let scheda: SchedaCopilota
    let suIPad: Bool
    let conferma: () -> Void
    let scarta: () -> Void
    let indica: () -> Void

    private typealias S = Tema.Apple.Copilota.Scheda

    static func occhiello(_ t: SchedaCopilota.Tipo) -> String {
        switch t {
        case .obiettivo: return "Obiettivo riconosciuto"
        case .polizzaEsterna: return "Polizza di un’altra compagnia"
        case .profilo: return "Profilo per questo obiettivo"
        case .evento: return "Evento della vita"
        case .attivita: return "Da fare"
        }
    }

    private var provenienza: String? {
        var parti: [String] = []
        if scheda.origine == .qwen { parti.append("Qwen") }
        if !suIPad, let d = scheda.dispositivo { parti.append("dall’" + d) }
        return parti.isEmpty ? nil : parti.joined(separator: " · ")
    }

    var body: some View {
        let colore = Tema.Apple.Colore.Copilota.tipo(scheda.tipo)
        let forma = RoundedRectangle(cornerRadius: S.raggio, style: .continuous)
        return HStack(spacing: 0) {
            Rectangle()
                .fill(colore)
                .frame(width: S.filo)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: S.spazioPulsanti) {
                    Text(Self.occhiello(scheda.tipo))
                        .carattereApple(S.occhiello)
                        .foregroundColor(colore)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let p = provenienza {
                        Text(p)
                            .carattereApple(S.provenienza)
                            .foregroundColor(S.coloreProvenienza)
                            .lineLimit(1)
                    }
                }
                Text(scheda.titolo)
                    .carattereApple(S.frase)
                    .foregroundColor(S.coloreFrase)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, S.sopraFrase)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: indica)
                pulsanti
                    .padding(.top, S.sopraPulsanti)
            }
            .padding(S.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(forma)
        .superficieApple(S.superficie, raggio: S.raggio)
        .opacity(scheda.stato == .scartata ? S.opacitaScartata : 1)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var pulsanti: some View {
        switch scheda.stato {
        case .confermata:
            Text("✓ Fatto · " + scheda.azione.nome)
                .carattereApple(S.fatto)
                .foregroundColor(S.coloreFatto)
        case .scartata:
            Text("Scartata")
                .carattereApple(S.fatto)
                .foregroundColor(S.coloreScartata)
        case .proposta:
            HStack(spacing: S.spazioPulsanti) {
                if suIPad {
                    Text(TestiCopilota.sulMac + " · " + scheda.azione.nome)
                        .carattereApple(S.provenienza)
                        .foregroundColor(S.coloreProvenienza)
                        .lineLimit(1)
                } else {
                    Button(action: conferma) { Text("Conferma · " + scheda.azione.nome).lineLimit(1) }
                        .buttonStyle(.apple)
                        .help("Entra subito nel dossier: " + scheda.azione.nome.lowercased())
                }
                Button("Scarta", action: scarta)
                    .buttonStyle(.appleSobrio)
                    .fixedSize()
            }
        }
    }
}
