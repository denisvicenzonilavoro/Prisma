import SwiftUI

// L'app Messaggi, «Prisma scrive per te» (versione «Orizzonte», giro 3, Design/template-novita-specifica.md §5):
//
//   ┌─ DA MANDARE OGGI ─────────────┐  ┌──────────────── il messaggio (PannelloMessaggio) ────────────────┐
//   │ ◉ Giulia Rossi       Alleanza │  │ ◉ A: Giulia Rossi · giulia.rossi@example.com   [Perché adesso: …] │
//   │   Il riepilogo dell'incontro… │  │   Il riepilogo dell'incontro di ieri                              │
//   │   Incontro di ieri alle 17:30 │  │ [Cordiale·Formale·Breve] [Mail·Messaggi]      ◎ Vera scrive con …  │
//   │ QUESTA SETTIMANA              │  │ Oggetto: …                                                        │
//   │ ◉ Sofia Romano                │  │ Ciao Giulia, …                                                    │
//   │ ┌───────────────────────────┐ │  │ [cifre] · Le cifre vengono da Prisma                              │
//   │ │ Vera scrive, tu spedisci…  │ │  │ [Apri in Mail] [Salva nel dossier] [↻ Riscrivi]  Lo spedisci tu  │
//   └─┴───────────────────────────┴─┘  └───────────────────────────────────────────────────────────────────┘
//
// - Le occasioni vengono da MotoreOccasioniMessaggi (in cache nello stato), con in testa quelle chieste dalle altre app
//   (CollegamentiMessaggi.swift: `occasioniMessaggiConRichieste`, `prendiRichiestaMessaggi`).
// - Tono e canale valgono per tutte le occasioni; i testi già scritti restano finché la finestra è aperta
//   (SessioneMessaggi).
// - Cambio di occasione: il pannello esce in 0,13 s spostandosi di 10 a destra, poi rientra a cascata da 0; la voce
//   scelta cambia fondo in 0,25 s. Le voci non si inclinano.
// - Stato vuoto onesto: nessuna occasione oggi né in settimana, nessun messaggio inventato.
// - «Riduci movimento»: niente cascata né uscita laterale, una dissolvenza di 0,15 s; istantanee: stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Messaggi.swift.

// MARK: - Istantanee

/// Che cosa una scena delle istantanee chiede a Messaggi (Prisma --istantanee e le istantanee di iPhone e iPad):
/// l'occasione (tipo e cliente), il tono, il canale e chi ha scritto il testo. Il testo è quello del modello fisso di
/// Prisma con le cifre dei motori: con `vera` si mostra come scritto da Vera (lo stato finale di Vera, senza Qwen), senza
/// `vera` con l'avviso «Vera non è pronta». Vale solo per lo stato della scena (riferimento debole).
final class RichiestaIstantaneaMessaggi {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaMessaggi?

    private weak var stato: StatoShell?
    let tipo: TipoOccasioneMessaggio?
    let clienteId: String?
    let tono: TonoMessaggio
    let canale: CanaleMessaggio
    let vera: Bool
    let motivoNonPronta: String?

    private init(stato: StatoShell, tipo: TipoOccasioneMessaggio?, clienteId: String?, tono: TonoMessaggio,
                 canale: CanaleMessaggio, vera: Bool, motivoNonPronta: String?) {
        self.stato = stato
        self.tipo = tipo
        self.clienteId = clienteId
        self.tono = tono
        self.canale = canale
        self.vera = vera
        self.motivoNonPronta = motivoNonPronta
    }

    static func chiedi(_ s: StatoShell, tipo: TipoOccasioneMessaggio? = nil, cliente: String? = nil, tono: TonoMessaggio = .cordiale,
                       canale: CanaleMessaggio = .mail, vera: Bool = true, motivoNonPronta: String? = nil) {
        attuale = RichiestaIstantaneaMessaggi(stato: s, tipo: tipo, clienteId: cliente, tono: tono, canale: canale, vera: vera,
                                              motivoNonPronta: motivoNonPronta)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaMessaggi? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }

    /// L'occasione chiesta (la prima con quel tipo e quel cliente), o la prima dell'elenco.
    func occasione(in elenco: OccasioniMessaggi) -> OccasioneMessaggio? {
        elenco.tutte.first { o in (tipo == nil || o.tipo == tipo) && (clienteId == nil || o.clienteId == clienteId) }
            ?? elenco.tutte.first
    }

    /// Il testo della scena: il modello fisso compilato con le cifre dell'occasione.
    func scritto(_ o: OccasioneMessaggio, cliente: Cliente, stato s: StatoShell) -> TestoScrittoMessaggio {
        Self.testo(o, cliente: cliente, stato: s, tono: tono, canale: canale, vera: vera, motivo: motivoNonPronta)
    }

    /// Il modello fisso di Prisma per un'istantanea: come scritto da Vera (`vera`) o con l'avviso «Vera non è pronta».
    /// Vale anche per le scene che aprono Messaggi senza chiedere niente (Vera non è pronta, come nelle istantanee).
    static func testo(_ o: OccasioneMessaggio, cliente: Cliente, stato s: StatoShell, tono: TonoMessaggio, canale: CanaleMessaggio,
                      vera: Bool, motivo: String?) -> TestoScrittoMessaggio {
        let bozza = ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: cliente, firma: s.firmaMessaggio(o.canale, tono: tono))
        if vera {
            return TestoScrittoMessaggio(oggetto: bozza.oggetto, testo: bozza.completo, autore: .vera,
                                         modello: MotoreLocale.modelloPredefinito, avviso: nil)
        }
        return MessaggiVera.fisso(bozza, avviso: MessaggiVera.avvisoNonPronta(motivo))
    }
}

// MARK: - L'app

@MainActor
struct AppMessaggi: View {
    @Environment(StatoShell.self) var stato
    /// La sessione tenuta senza osservarla tutta: la osserva il pannello del messaggio (PannelloMessaggio), così un pezzo
    /// del testo che arriva da Vera o un tasto nel messaggio rifanno il pannello, non l'elenco delle occasioni. L'app legge
    /// solo l'occasione scelta e il messaggio riaperto dal dossier, che cambiano solo da qui (`giroScelta`).
    @State private var sessione = SessioneMessaggi()
    /// Cresce a ogni cambio dell'occasione scelta (o del messaggio riaperto dal dossier) fatto da questa vista: il body
    /// rilegge la sessione.
    @State private var giroScelta = 0

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto
    /// La voce appena toccata: si accende subito, il pannello cambia dopo l'uscita.
    @State private var toccata: String?
    @State private var esce = false
    /// Dopo il primo cambio di occasione la cascata del pannello parte da 0.
    @State private var cambiato = false

    private typealias D = Tema.Apple.Messaggi.Disposizione
    private typealias M = Tema.Apple.Messaggi.Moto

    var body: some View {
        let _ = ContaCorpi.segna()
        // «Luce» giro 12: Messaggi · Campagne (il segmentato nella testata, MessaggiCampagne.swift)
        Group {
            if stato.vistaMessaggi == .campagne {
                VistaCampagne()
            } else {
                elencoEPannello
            }
        }
        .onAppear {
            // Gli obiettivi raggiunti prendono la loro data: i traguardi entrano in «Da festeggiare» (StatoTraguardi.swift)
            stato.segnaObiettiviRaggiunti()
            prendiRichiesta()
        }
        .onChange(of: stato.richiestaMessaggi) { r in
            if r != nil { prendiRichiesta() }
        }
        .onDisappear { sessione.ferma() }
    }

    /// L'elenco delle occasioni e il pannello del messaggio scelto.
    private var elencoEPannello: some View {
        // Iscrive il body ai cambi di scelta (la sessione non è osservata qui)
        _ = giroScelta
        let richiesta = scatto ? RichiestaIstantaneaMessaggi.per(stato) : nil
        let elenco = sessione.elenco(stato.occasioniMessaggiConRichieste())
        let scelta = richiesta?.occasione(in: elenco) ?? sessione.occasione(in: elenco)
        return GeometryReader { geo in
            let colonna = min(D.larghezzaColonna, max(D.larghezzaColonnaMinima, geo.size.width * D.quotaColonna))
            let resto = max(0, geo.size.width - colonna - D.gioco)
            HStack(alignment: .top, spacing: D.gioco) {
                ColonnaOccasioniMessaggi(elenco: elenco, scelta: toccata ?? scelta?.id, base: M.baseApertura) { id in
                    scegli(id, attuale: scelta?.id)
                }
                .frame(width: colonna)
                .frame(maxHeight: .infinity, alignment: .top)
                pannello(scelta, richiesta: richiesta, compatto: resto < D.pannelloCompatto,
                         voci: min(elenco.tutte.count, M.voceMassima))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    @ViewBuilder private func pannello(_ o: OccasioneMessaggio?, richiesta: RichiestaIstantaneaMessaggi?, compatto: Bool,
                                       voci: Int) -> some View {
        if let o, o.tipo == .traguardo, let c = stato.cliente(o.clienteId) {
            // Un traguardo da festeggiare: il biglietto e «Il momento, già pronto» (Luce giro 5, PannelloTraguardo.swift)
            PannelloTraguardo(occasione: o, cliente: c, base: cambiato ? M.baseCambio : M.baseApertura,
                              primoIndice: cambiato ? 0 : voci)
                .id(o.id)
                .opacity(esce ? 0 : 1)
                .offset(x: esce ? M.spostamentoCambio : 0)
        } else if let o, let c = stato.cliente(o.clienteId) {
            // Tono e canale vanno e vengono dalla sessione: il pannello, che la osserva, si ridisegna da sé
            let tono: Binding<TonoMessaggio> = richiesta.map { r in Binding.constant(r.tono) }
                ?? Binding(get: { sessione.tono }, set: { sessione.tono = $0 })
            let canale: Binding<CanaleMessaggio> = richiesta.map { r in Binding.constant(r.canale) }
                ?? Binding(get: { sessione.canale }, set: { sessione.canale = $0 })
            PannelloMessaggio(sessione: sessione, occasione: o, cliente: c, tono: tono, canale: canale,
                              compatto: compatto, incorniciato: true,
                              base: cambiato ? M.baseCambio : M.baseApertura,
                              primoIndice: cambiato ? 0 : voci,
                              scrittoIstantanea: scatto ? (richiesta?.scritto(o, cliente: c, stato: stato)
                                  ?? RichiestaIstantaneaMessaggi.testo(o, cliente: c, stato: stato, tono: sessione.tono,
                                                                       canale: sessione.canale, vera: false,
                                                                       motivo: stato.disponibilitaLocale.motivo)) : nil)
                .id(o.id)
                .opacity(esce ? 0 : 1)
                .offset(x: esce ? M.spostamentoCambio : 0)
        } else {
            VuotoMessaggi()
                .entrataCascata(1, base: M.baseApertura)
        }
    }

    // MARK: Fare

    private func prendiRichiesta() {
        guard !scatto, let r = stato.prendiRichiestaMessaggi() else { return }
        sessione.applica(r, elenco: stato.occasioniMessaggiConRichieste(), stato: stato)
        giroScelta &+= 1
        toccata = nil
        esce = false
    }

    /// Sceglie un'occasione: la voce si accende subito, il pannello esce in 0,13 s e rientra a cascata.
    private func scegli(_ id: String, attuale: String?) {
        guard id != (toccata ?? attuale) else { return }
        if scatto {
            sessione.scelta = id
            giroScelta &+= 1
            return
        }
        if calmo {
            withAnimation(Tema.Moto.dissolvenzaCalma) {
                cambiato = true
                sessione.scelta = id
                giroScelta &+= 1
            }
            return
        }
        toccata = id
        withAnimation(M.uscitaCambio) { esce = true }
        Movimenti.dopo(Tema.Apple.Moto.tempo(M.durataCambio)) {
            // Un'altra voce toccata nel frattempo: entra quella, al suo giro
            guard toccata == id else { return }
            cambiato = true
            sessione.scelta = id
            giroScelta &+= 1
            toccata = nil
            esce = false
        }
    }
}

// MARK: - La colonna delle occasioni

/// La colonna `.side`: «Da mandare oggi» (in testa le occasioni chieste dalle altre app e un messaggio riaperto dal
/// dossier) e «Questa settimana», le voci con cliente, canale, titolo e perché; in fondo la scheda «Vera scrive, tu
/// spedisci».
@MainActor
struct ColonnaOccasioniMessaggi: View {
    @Environment(StatoShell.self) var stato
    let elenco: OccasioniMessaggi
    let scelta: String?
    let base: Double
    let tocca: (String) -> Void

    private typealias C = Tema.Apple.Messaggi.Colonna
    private typealias M = Tema.Apple.Messaggi.Moto

    var body: some View {
        let _ = ContaCorpi.segna()
        let forma = RoundedRectangle(cornerRadius: C.raggio, style: .continuous)
        // «Da festeggiare» in cima (i traguardi, Luce giro 5), poi «Da mandare oggi» e «Questa settimana»
        let gruppi: [(String, [OccasioneMessaggio])] = GruppoMessaggio.allCases.map { g in (g.titolo, elenco.voci(g)) }
        // La posizione di ogni voce per la cascata, in un passaggio (non una ricerca nell'elenco per ogni voce)
        let tutte = elenco.tutte
        let indici = Dictionary(tutte.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        // I traguardi del menu «Da festeggiare» dalla cache, non il motore dei traguardi per ogni voce a ogni passaggio
        // (il menu contestuale si costruisce insieme al body)
        let traguardi = tutte.contains { $0.tipo == .traguardo } ? traguardiDelMenu() : [:]
        return VStack(alignment: .leading, spacing: 0) {
            if elenco.nessuna {
                occhiello(GruppoMessaggio.oggi.titolo, primo: true)
                Text(TestiMessaggi.nienteOggi)
                    .carattereApple(C.vuoto)
                    .foregroundColor(C.coloreVuoto)
                    .padding(.horizontal, C.rientroVuoto)
                    .entrataCascata(0, base: base)
                Spacer(minLength: 0)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Tema.Apple.Messaggi.Voce.fraVoci) {
                        let visibili = gruppi.filter { !$0.1.isEmpty }
                        ForEach(Array(visibili.enumerated()), id: \.offset) { g, gruppo in
                            occhiello(gruppo.0, primo: g == 0)
                            ForEach(gruppo.1) { o in
                                let i = indici[o.id] ?? 0
                                VoceOccasioneMessaggio(occasione: o, cliente: stato.cliente(o.clienteId), scelta: o.id == scelta) {
                                    tocca(o.id)
                                }
                                .contextMenu { menuTraguardo(o, traguardi: traguardi) }
                                .entrataCascata(min(i, M.voceMassima), base: base, sfocatura: false)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            Text(TestiMessaggi.notaColonna)
                .carattereApple(C.testoNota)
                .foregroundColor(C.coloreTestoNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(C.paddingNota)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(C.superficieNota, raggio: C.raggioNota)
                .padding(.top, C.sopraNota)
        }
        .padding(C.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(forma)
        .superficieApple(C.superficie, raggio: C.raggio)
    }

    /// Il menu di una voce «Da festeggiare»: «Segna come festeggiato» e «Non è un traguardo» (Luce giro 5). Il traguardo
    /// vero si cerca solo quando si sceglie la voce.
    @ViewBuilder private func menuTraguardo(_ o: OccasioneMessaggio, traguardi: [String: Bool]) -> some View {
        if o.tipo == .traguardo, let festeggiato = traguardi[o.origine.riferimento] {
            if !festeggiato {
                Button("Segna come festeggiato") {
                    if let t = stato.traguardo(o.origine.riferimento) { stato.segnaFesteggiato(t) }
                }
            }
            Button("Non è un traguardo") {
                if let t = stato.traguardo(o.origine.riferimento) { stato.scartaTraguardo(t) }
            }
        }
    }

    /// I traguardi di adesso per il menu (id → già festeggiato), una volta per dati dei calcoli e giorno, come le
    /// occasioni. Quali traguardi ci sono e se sono festeggiati dipende solo dai dati dei calcoli (le regole dei traguardi
    /// stanno nelle impostazioni dei calcoli): note e capsule cambiano solo l'idea per il regalo e la capsula. Con due
    /// traguardi con lo stesso id vale il primo, come in `StatoShell.traguardo(_:)`.
    private func traguardiDelMenu() -> [String: Bool] {
        stato.ricavato("messaggi-menu-traguardi") { () -> [String: Bool] in
            var stati: [String: Bool] = [:]
            for t in MotoreTraguardi.calcola(dati: stato.datiDeiCalcoli(), oggi: Date()) where stati[t.id] == nil {
                stati[t.id] = t.festeggiatoIl != nil
            }
            return stati
        }
    }

    private func occhiello(_ titolo: String, primo: Bool) -> some View {
        Text(titolo)
            .carattereApple(C.occhiello)
            .foregroundColor(C.coloreOcchiello)
            .lineLimit(1)
            .padding(primo ? C.occhielloPrimo : C.occhielloAltri)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Una voce dell'elenco (`.rub`): avatar 38, nome 14 bold con il canale, il titolo dell'occasione su una riga e il
/// perché adesso (o «✓ Preparato alle …»). Sotto il puntatore `chip`, scelta `selezioneVoce`, il fondo cambia in 0,25 s.
@MainActor
struct VoceOccasioneMessaggio: View {
    let occasione: OccasioneMessaggio
    let cliente: Cliente?
    let scelta: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    private typealias V = Tema.Apple.Messaggi.Voce

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: V.raggio, style: .continuous)
        return Button(action: azione) {
            HStack(spacing: V.spazioAvatar) {
                avatar
                VStack(alignment: .leading, spacing: V.spazioTitoli) {
                    HStack(spacing: V.spazioNome) {
                        Text(cliente?.nome ?? "Cliente non trovato")
                            .carattereApple(V.nome)
                            .foregroundColor(V.coloreNome)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if let c = occasione.canale {
                            EtichettaCanaleApple(canale: c, compatta: true)
                        }
                    }
                    Text(occasione.titolo)
                        .carattereApple(V.titolo)
                        .foregroundColor(V.coloreTitolo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: V.larghezzaTitolo, alignment: .leading)
                    if let p = occasione.preparatoIl {
                        // Un traguardo festeggiato oggi (telefonata messa o segnato a mano) resta con la spunta fino a domani
                        Text(occasione.tipo == .traguardo ? TestiTraguardi.festeggiato : TestiMessaggi.preparato(p))
                            .carattereApple(V.preparato)
                            .foregroundColor(V.colorePreparato)
                            .lineLimit(1)
                    } else {
                        Text(occasione.perche)
                            .carattereApple(V.perche)
                            .foregroundColor(V.colorePerche)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(V.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { fondo }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { dentro in sopra = dentro && !istantanea }
        .animation(animazione, value: scelta)
        .animation(animazione, value: sopra)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
        .help(occasione.titolo + " · " + occasione.perche)
    }

    @ViewBuilder private var avatar: some View {
        if let c = cliente {
            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: V.avatar)
        } else {
            Circle()
                .fill(Tema.Apple.Colore.chip)
                .frame(width: V.avatar, height: V.avatar)
        }
    }

    @ViewBuilder private var fondo: some View {
        let forma = RoundedRectangle(cornerRadius: V.raggio, style: .continuous)
        if scelta {
            forma.fill(V.fondoScelta)
        } else if sopra {
            forma.fill(V.fondoSopra)
        }
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(V.animazioneFondo, calmo: calmo, istantanea: istantanea)
    }
}

// MARK: - Stato vuoto

/// Nessuna occasione oggi né in settimana: il simbolo e la frase, nessun messaggio di prova.
struct VuotoMessaggi: View {
    var body: some View {
        let v = Tema.Apple.Messaggi.Vuoto.self
        let p = Tema.Apple.Messaggi.Pannello.self
        VStack(spacing: v.spazio) {
            Image(systemName: v.simbolo)
                .carattereApple(v.carattereSimbolo)
                .foregroundColor(v.coloreSimbolo)
                .accessibilityHidden(true)
            Text(TestiMessaggi.vuoto)
                .carattereApple(v.testo)
                .foregroundColor(v.coloreTesto)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: v.larghezza)
        }
        .padding(p.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .superficieApple(p.superficie, raggio: p.raggio)
    }
}
