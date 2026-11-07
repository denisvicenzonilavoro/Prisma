#if os(iOS)
import SwiftUI

/// Il guscio dell'iPhone: la scrivania del tema a una colonna (`@media (max-width: 760px)` di
/// Design/tema-liquid-glass.html) con la barra in alto e il dock in basso; un'app alla volta in una finestra di
/// vetro fra la barra e il dock (deskRect del tema), che entra ed esce con il movimento del Mac. Sotto tutto l'acqua
/// animata di RadiceMobile. Si torna alla scrivania con l'icona Scrivania del dock, con il marchio o con la ✕.
struct GuscioiPhone: View {
    @EnvironmentObject var mobile: StatoMobile
    @EnvironmentObject var stato: StatoShell
    /// Sotto una finestra, a movimento d'apertura finito, la scrivania esce dalla gerarchia (memoria, vetri).
    @State private var scrivaniaTolta = false
    @State private var giroMovimento = 0

    private typealias D = Tema.Misura.Mobile.Dock

    var body: some View {
        // La safe area si legge da fuori: dentro una vista che la ignora i margini valgono zero
        GeometryReader { esterno in
        let sicuro = esterno.safeAreaInsets
        GeometryReader { geo in
            let misura = geo.size
            let sottoBarra = sicuro.top + Tema.Misura.Mobile.Barra.altezza
            let voci = DisposizioneDockMobile.app(.telefono, consentita: { stato.appConsentita($0) }).count + 2
            let lato = DisposizioneDockMobile.lato(elementi: voci, larghezza: misura.width, massimo: D.massimoTelefono)
            let sopraDock = D.dalBassoTelefono + DisposizioneDockMobile.altezza(lato: lato, stile: .telefono)
            ZStack(alignment: .topLeading) {
                // Sotto una finestra, a movimento finito, la scrivania esce dalla gerarchia: niente vetri da ricampionare.
                // Nelle istantanee (niente movimento) non c'è già più
                if mobile.appAperta == nil || (mobile.persistente && !scrivaniaTolta) {
                    ScrivaniaTelefono(alto: sottoBarra, basso: sopraDock + Tema.Misura.Mobile.Scrivania.sopraDock,
                                      inFondo: mobile.scrivaniaInFondo)
                        .frame(width: misura.width, height: misura.height)
                        .allowsHitTesting(mobile.appAperta == nil)
                        .accessibilityHidden(mobile.appAperta != nil)
                }

                if let app = mobile.appAperta {
                    FinestraMobile(app: app,
                                   cornice: Self.cornice(misura: misura, sottoBarra: sottoBarra, sopraDock: sopraDock),
                                   spazio: misura, raggio: Tema.Raggio.Mobile.finestraTelefono,
                                   origine: mobile.origineApertura, animata: mobile.persistente) {
                        AppTelefono(app: app)
                    }
                    .id(app)
                }

                BarraMobile(compatta: true, alto: sicuro.top)

                DockMobile(stile: .telefono, larghezza: misura.width)
                    .padding(.bottom, D.dalBassoTelefono)
                    .frame(width: misura.width, height: misura.height, alignment: .bottom)

                PannelliMobile(sistema: stato.sistema, sottoBarra: sottoBarra, misura: misura)
            }
            .frame(width: misura.width, height: misura.height, alignment: .topLeading)
            // Una volta, qui, sulla vista che ignora la safe area: le origini dei widget e del dock sono nel suo spazio
            .coordinateSpace(name: ShellView.spazioShell)
        }
        .ignoresSafeArea(.container)
        }
        .onChange(of: mobile.appAperta) { nuova in aggiornaScrivania(nuova) }
        .modifier(SceltaFileiPad())
        .modifier(EsportaBackupiPad())
    }

    /// La finestra fra la barra e il dock (deskRect del tema: x 8, y barra + 6, larghezza w − 16).
    static func cornice(misura: CGSize, sottoBarra: CGFloat, sopraDock: CGFloat) -> CGRect {
        let y = sottoBarra + Tema.Misura.Mobile.Finestra.sopra
        let basso = misura.height - sopraDock - Tema.Misura.Mobile.Finestra.sopraDock
        return CGRect(x: Tema.Misura.Mobile.Finestra.margine, y: y,
                      width: max(0, misura.width - 2 * Tema.Misura.Mobile.Finestra.margine),
                      height: max(0, basso - y))
    }

    /// La scrivania resta sotto la finestra che entra per la durata del movimento, poi si toglie; torna subito con
    /// la scrivania (la finestra esce sopra di lei). Passando da un'app all'altra resta tolta.
    private func aggiornaScrivania(_ app: AppPrisma?) {
        giroMovimento &+= 1
        guard app != nil else {
            scrivaniaTolta = false
            return
        }
        guard !scrivaniaTolta else { return }
        let giro = giroMovimento
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.Finestre.durataApertura) {
            if giroMovimento == giro && mobile.appAperta != nil { scrivaniaTolta = true }
        }
    }
}

/// L'app dell'iPhone dentro la finestra: la sua NavigationStack (Clienti, Posizioni e Agenda con i percorsi del giro 1;
/// Attività, Note, Documenti e Impostazioni in sola lettura), le altre col segnaposto. Sulla radice la ✕ della
/// finestra a sinistra, come i semafori del tema; il titolo piccolo (la finestra è bassa).
struct AppTelefono: View {
    @EnvironmentObject var mobile: StatoMobile
    let app: AppPrisma

    var body: some View {
        // Le etichette del canale, i pannelli e gli indicatori nello stile del tema Apple, in tutte le app
        pila.superficiApple()
    }

    @ViewBuilder private var pila: some View {
        switch app {
        case .clienti:
            NavigationStack(path: $mobile.percorsoClienti) {
                ClientiTelefono().radiceFinestra(app).destinazioniTelefono()
            }
            .fondoNavigazioneTrasparente()
        case .posizioni:
            NavigationStack(path: $mobile.percorsoPosizioni) {
                PosizioniTelefono().radiceFinestra(app).destinazioniTelefono()
            }
            .fondoNavigazioneTrasparente()
        case .agenda:
            NavigationStack(path: $mobile.percorsoAgenda) {
                AgendaTelefono().radiceFinestra(app).destinazioniTelefono()
            }
            .fondoNavigazioneTrasparente()
        default:
            NavigationStack {
                contenuto.radiceFinestra(app)
            }
            .fondoNavigazioneTrasparente()
        }
    }

    @ViewBuilder private var contenuto: some View {
        switch app {
        case .attivita: AttivitaTelefono()
        case .note: NoteTelefono()
        case .documenti: DocumentiTelefono()
        case .impostazioni: ImpostazioniTelefono()
        case .vera: VeraTelefono().navigationTitle(app.titolo)
        // Messaggi (giro 3 di «Orizzonte»): il messaggio in alto, le altre occasioni a un tocco (MessaggiTelefono.swift)
        case .messaggi: MessaggiTelefono()
        // Mercato (giro 7 di «Orizzonte»): la prima tessera grande, le altre e chi è toccato, gli avvisi a un tocco; in
        // sola lettura, i dati arrivano dal Mac (MercatoTelefono.swift)
        case .mercato: MercatoTelefono()
        default:
            InArrivoMobile(app: app, titolo: "\(app.titolo) è sul Mac", testo: StatoShell.soloSulMacPerOra)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(app.titolo)
        }
    }
}

extension View {
    /// La radice di un'app nella finestra dell'iPhone: la ✕ a sinistra, il titolo piccolo, la barra senza fondo.
    func radiceFinestra(_ app: AppPrisma) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                PulsanteChiudiFinestra(app: app)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// La NavigationStack dentro la finestra di vetro: senza fondo proprio (si vede il vetro della finestra).
    func fondoNavigazioneTrasparente() -> some View {
        modifier(FondoNavigazioneTrasparente())
    }
}

private struct FondoNavigazioneTrasparente: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.containerBackground(Color.clear, for: .navigation)
        } else {
            content
        }
    }
}

// MARK: - Mattoni comuni

private typealias E = Tema.Apple.Telefono.Elenco

extension View {
    /// Le destinazioni dei tocchi negli elenchi dell'iPhone.
    func destinazioniTelefono() -> some View {
        navigationDestination(for: DestinazioneTelefono.self) { destinazione in
            switch destinazione {
            case .cliente(let id): SchedaClienteTelefono(clienteId: id)
            case .posizione(let id): DettaglioPosizioneTelefono(posizioneId: id)
            case .appuntamento(let id): DettaglioAppuntamentoTelefono(appuntamentoId: id)
            case .area(let a, let filtro):
                ElencoAreaTelefono(area: AreaPosizione(rawValue: a) ?? .investimento, filtro: FiltroPosizioniTelefono(chiave: filtro))
            }
        }
    }

    /// Una riga o una scheda del tema Apple dentro la finestra di vetro: tile col filo (raggio 18, padding 14×16),
    /// alta almeno 56. `premibile`: la scheda apre qualcosa e scende a 0,98 alla pressione (`.inclinazione`, iOS).
    func schedaTelefono(premibile: Bool = false) -> some View {
        padding(E.padding)
            .frame(maxWidth: .infinity, minHeight: E.rigaMinima, alignment: .leading)
            .superficieApple(E.superficie, raggio: E.raggio)
            .contentShape(RoundedRectangle(cornerRadius: E.raggio, style: .continuous))
            .inclinazione(massimo: Tema.Apple.Telefono.inclinazione, raggio: E.raggio, attiva: premibile)
    }

    /// Un pannello grande (il totale, il mese, la cifra principale): card piatta, raggio 22, padding 18.
    func pannelloTelefono() -> some View {
        padding(E.paddingPannello)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(E.superficiePannello, raggio: E.raggioPannello)
    }
}

/// Un elenco che scorre dentro la finestra di vetro (il vetro e l'acqua sotto li disegnano la finestra e RadiceMobile).
struct FondoTelefono<Contenuto: View>: View {
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: E.spazio) {
                contenuto()
            }
            .padding(E.margine)
        }
    }
}

/// Titolo di una sezione degli elenchi: `.lbl` maiuscolo `inchiostro2`, come le etichette del tema Apple.
struct SezioneTelefono: View {
    let titolo: String

    var body: some View {
        Text(titolo)
            .carattereApple(E.sezione)
            .foregroundColor(E.coloreSezione)
            .lineLimit(1)
            .padding(.top, E.sezioneSopra)
            .padding(.bottom, E.sezioneSotto)
            .padding(.horizontal, E.sezioneLato)
    }
}

/// Elenco vuoto: una frase, nient'altro.
struct VuotoTelefono: View {
    let testo: String

    var body: some View {
        Text(testo)
            .carattereApple(E.vuoto)
            .foregroundColor(E.coloreDettaglio)
            .fixedSize(horizontal: false, vertical: true)
            .schedaTelefono()
    }
}

/// «In essere» verde o «Proposta» viola, a capsula come le etichette del canale.
struct StatoPosizioneTelefono: View {
    let stato: StatoPosizione

    var body: some View {
        let s = Tema.Apple.Telefono.StatoPosizione.self
        let proposta = stato == .proposta
        Text(stato.nome)
            .carattereApple(s.carattere)
            .foregroundColor(proposta ? s.testoProposta : s.testoInEssere)
            .padding(s.padding)
            .background(Capsule(style: .continuous).fill(proposta ? s.fondoProposta : s.fondoInEssere))
            .fixedSize()
    }
}

/// Una riga etichetta–valore delle schede in sola lettura.
struct DatoTelefono: View {
    let etichetta: String
    let valore: String

    init(_ etichetta: String, _ valore: String) {
        self.etichetta = etichetta
        self.valore = valore
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: E.spazioRiga) {
            Text(etichetta)
                .carattereApple(E.etichettaDato)
                .foregroundColor(E.coloreDettaglio)
            Spacer(minLength: E.spazioRiga)
            Text(valore)
                .carattereApple(E.valoreDato)
                .foregroundColor(E.coloreNome)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Il blocco della data (come le scadenze della scrivania del Mac): «DIC» 10 bold rosso, «17» 21 semibold.
struct BloccoDataTelefono: View {
    let data: Date

    var body: some View {
        let s = Tema.Apple.Scrivania.Scadenze.self
        VStack(spacing: 0) {
            Text(Formati.meseBreve.string(from: data).uppercased())
                .carattereApple(s.mese)
                .foregroundColor(s.coloreMese)
            Text(Formati.giorno.string(from: data))
                .carattereApple(s.giorno)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
        }
        .frame(width: s.data)
        .accessibilityHidden(true)
    }
}

/// Il cerchietto di un'attività da fare (come «Da fare oggi» sul Mac): pieno di verde con la spunta se è fatta.
/// Sull'iPhone è fermo: le attività si spuntano sul Mac.
struct CerchioAttivitaTelefono: View {
    let fatta: Bool

    var body: some View {
        let f = Tema.Apple.Scrivania.DaFare.self
        ZStack {
            if fatta {
                Circle().fill(Tema.Apple.Colore.verde)
            } else {
                Circle().strokeBorder(Tema.Apple.Colore.inchiostro, lineWidth: f.trattoCerchio)
            }
        }
        .frame(width: f.cerchio, height: f.cerchio)
        .accessibilityHidden(true)
    }
}

/// Il chevron delle righe che aprono un dettaglio.
struct ChevronTelefono: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .carattereApple(E.chevron)
            .foregroundColor(E.coloreTerziario)
            .accessibilityHidden(true)
    }
}

/// Il segmentato a pillola del tema Apple: a tutta larghezza se ci sta, altrimenti scorre di lato (iPhone piccoli).
struct SegmentatoTelefono<Valore: Hashable>: View {
    @Binding var selezione: Valore
    let voci: [(Valore, String)]
    var icona: ((Valore) -> AnyView)? = nil

    var body: some View {
        ViewThatFits(in: .horizontal) {
            SegmentatoPillola(selezione: $selezione, voci: voci, larghezzaPiena: true, icona: icona)
            ScrollView(.horizontal, showsIndicators: false) {
                SegmentatoPillola(selezione: $selezione, voci: voci, icona: icona)
            }
        }
    }
}

// MARK: - Clienti

private struct ClientiTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @State private var cerca = ""

    var body: some View {
        let elenco = stato.clienti
            .filter { cerca.isEmpty || $0.nome.localizedCaseInsensitiveContains(cerca) }
            .sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }
        FondoTelefono {
            if elenco.isEmpty {
                VuotoTelefono(testo: cerca.isEmpty ? "Nessun cliente: apri il backup del Mac dal centro di controllo." : "Nessun cliente con «\(cerca)».")
            }
            ForEach(Array(elenco.enumerated()), id: \.element.id) { i, cliente in
                NavigationLink(value: DestinazioneTelefono.cliente(cliente.id)) {
                    RigaClienteTelefono(cliente: cliente)
                }
                .buttonStyle(.plain)
                .entrataCascata(min(i, Tema.Apple.Telefono.Cliente.righeInCascata))
            }
        }
        .navigationTitle("Clienti")
        .searchable(text: $cerca, prompt: "Cerca un cliente")
    }
}

private struct RigaClienteTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let cliente: Cliente

    var body: some View {
        let posizioni = stato.posizioni.filter { $0.clienteId == cliente.id && $0.stato != .chiusa }
        let canali = Canale.allCases.filter { c in posizioni.contains { $0.canale == c } }
        // Il nome ha tutta la riga: i canali stanno sotto, mai al posto del nome (sul telefono c'è poco spazio)
        HStack(spacing: E.spazioRiga) {
            AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: Tema.Apple.Misura.Avatar.medio)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(cliente.nome)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .lineLimit(1)
                Text(cliente.tema.isEmpty ? "\(posizioni.count) posizioni" : cliente.tema)
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(1)
                if !canali.isEmpty {
                    HStack(spacing: E.spazioEtichette) {
                        ForEach(canali) { canale in EtichettaCanaleApple(canale: canale, compatta: true) }
                    }
                    .padding(.top, E.spazioTesto)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ChevronTelefono()
        }
        .schedaTelefono(premibile: true)
    }
}

/// La scheda del cliente (Design/iphone.html, schermata 2): chi è in alto, il patrimonio netto grande che conta con la
/// barra dei canali, quattro cifre su due colonne, poi le schede a pillola Sintesi, Posizioni, Agenda e Documenti
/// (non una pagina infinita).
private struct SchedaClienteTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let clienteId: String
    @State private var scheda = Scheda.sintesi

    private typealias C = Tema.Apple.Telefono.Cliente

    private enum Scheda: String, CaseIterable, Identifiable {
        case sintesi = "Sintesi", posizioni = "Posizioni", agenda = "Agenda", documenti = "Documenti"
        var id: String { rawValue }
    }

    var body: some View {
        let cliente = stato.clienti.first { $0.id == clienteId }
        FondoTelefono {
            if let cliente {
                testata(cliente)
                    .entrataCascata(0)
                principale(cliente)
                    .entrataCascata(1)
                tessere(cliente)
                    .entrataCascata(2)
                SegmentatoTelefono(selezione: $scheda, voci: Scheda.allCases.map { ($0, $0.rawValue) })
                    .padding(.top, C.schedeSopra)
                    .padding(.bottom, C.schedeSotto)
                    .entrataCascata(3)
                switch scheda {
                case .sintesi: sintesi(cliente)
                case .posizioni: posizioni
                case .agenda: agenda
                case .documenti: documenti
                }
            } else {
                VuotoTelefono(testo: "Questo cliente non c'è più nell'archivio.")
            }
        }
        .navigationTitle(cliente?.nome ?? "Cliente")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Avatar 56, il nome 26 bold (mai tagliato: va a capo), età · professione · motto, i canali sotto.
    private func testata(_ c: Cliente) -> some View {
        let dettagli = [c.eta.map { "\($0) anni" }, c.professione.isEmpty ? nil : c.professione, c.tema.isEmpty ? nil : "«\(c.tema)»"]
            .compactMap { $0 }
        return HStack(alignment: .center, spacing: C.spazioAvatar) {
            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: C.avatar)
            VStack(alignment: .leading, spacing: C.spazioRighe) {
                Text(c.nome)
                    .carattereApple(C.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(2)
                    .minimumScaleFactor(C.riduzioneNome)
                if !dettagli.isEmpty {
                    Text(dettagli.joined(separator: " · "))
                        .carattereApple(C.dettaglio)
                        .foregroundColor(C.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !c.canali.isEmpty {
                    HStack(spacing: E.spazioEtichette) {
                        ForEach(c.canali) { EtichettaCanaleApple(canale: $0, compatta: true) }
                    }
                    .padding(.top, C.spazioRighe)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, E.spazioRiga / 2)
    }

    /// Il patrimonio netto grande che conta, con la barra dei canali e l'importo di ciascuno.
    private func principale(_ c: Cliente) -> some View {
        let r = stato.riepilogoPosizioniCliente(c.id)
        return TotaleTelefono(titolo: "Patrimonio netto", totale: r.patrimonioNetto,
                              perCanale: Canale.allCases.compactMap { ch in r.perCanale[ch].map { (ch, $0) } },
                              debiti: r.debiti)
    }

    /// Quattro cifre su due colonne: prossimo incontro, da fare, premi all'anno, proposte aperte (le cifre contano).
    private func tessere(_ c: Cliente) -> some View {
        let r = stato.riepilogoPosizioniCliente(c.id)
        let incontro = stato.prossimiAppuntamenti.first { $0.clienteId == c.id }
        let aperte = stato.attivitaAperte.filter { $0.clienteId == c.id }.count
        let colonne = [GridItem(.flexible(), spacing: C.spazioTessere), GridItem(.flexible())]
        return LazyVGrid(columns: colonne, spacing: C.spazioTessere) {
            tessera("Prossimo incontro", nota: incontro.map { Formati.giornoRelativo($0.inizio) }) {
                Text(incontro.map { Formati.ora.string(from: $0.inizio) } ?? "—")
            }
            tessera("Da fare", nota: aperte == 1 ? "attività" : "attività aperte") {
                NumeroCheConta(Double(aperte), formato: .intero, indice: 1)
            }
            tessera("Premi all'anno", nota: r.contrattiConPremi > 0 ? "\(r.contrattiConPremi) contratti" : nil) {
                NumeroCheConta(r.premiAnnui, indice: 2)
            }
            tessera("Proposte aperte", nota: r.proposteAperte > 0 ? FormatoCifra.euro.testo(r.valoreProposte) : "nessuna") {
                NumeroCheConta(Double(r.proposteAperte), formato: .intero, indice: 3)
            }
        }
    }

    private func tessera<V: View>(_ etichetta: String, nota: String?, @ViewBuilder valore: () -> V) -> some View {
        VStack(alignment: .leading, spacing: C.spazioTessera) {
            Text(etichetta)
                .carattereApple(C.voceTessera)
                .foregroundColor(E.coloreDettaglio)
                .lineLimit(1)
            valore()
                .carattereApple(C.valoreTessera)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(C.riduzioneNome)
            if let nota {
                Text(nota)
                    .carattereApple(C.notaTessera)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(1)
            }
        }
        .padding(C.paddingTessera)
        .frame(maxWidth: .infinity, minHeight: C.tesseraMinima, alignment: .topLeading)
        .superficieApple(E.superficie, raggio: E.raggio)
    }

    /// Sintesi: da fare (scadenze e attività aperte), obiettivi con la barra che si riempie, recapiti, nota.
    @ViewBuilder private func sintesi(_ c: Cliente) -> some View {
        let attivita = stato.attivitaAperte.filter { $0.clienteId == c.id }.sorted { $0.scadenza < $1.scadenza }
        let scadenze = stato.riepilogoPosizioniCliente(c.id).inScadenza
        if !attivita.isEmpty || !scadenze.isEmpty {
            SezioneTelefono(titolo: "Da fare")
            ForEach(scadenze) { p in
                NavigationLink(value: DestinazioneTelefono.posizione(p.id)) {
                    HStack(spacing: E.spazioRiga) {
                        BloccoDataTelefono(data: p.scadenza ?? Date())
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(p.nome)
                                .carattereApple(E.nome)
                                .foregroundColor(E.coloreNome)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(p.scaduta ? "Scaduta" : "Scade il \(Formati.dataBreve.string(from: p.scadenza ?? Date()))")
                                .carattereApple(E.dettaglio)
                                .foregroundColor(p.scaduta ? E.coloreScaduto : E.coloreVicino)
                            EtichettaCanaleApple(canale: p.canale, compatta: true)
                                .padding(.top, E.spazioTesto)
                        }
                        Spacer(minLength: 0)
                        ChevronTelefono()
                    }
                    .schedaTelefono(premibile: true)
                }
                .buttonStyle(.plain)
            }
            ForEach(attivita.prefix(5)) { a in
                let indietro = a.scadenza < Calendar.current.startOfDay(for: Date())
                HStack(spacing: E.spazioRiga) {
                    CerchioAttivitaTelefono(fatta: a.completata)
                    VStack(alignment: .leading, spacing: E.spazioTesto) {
                        Text(a.titolo)
                            .carattereApple(E.nome)
                            .foregroundColor(E.coloreNome)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(Formati.giornoRelativo(a.scadenza))
                            .carattereApple(E.dettaglio)
                            .foregroundColor(indietro ? E.coloreScaduto : E.coloreDettaglio)
                    }
                    Spacer(minLength: 0)
                }
                .schedaTelefono()
            }
        }
        let obiettivi = stato.obiettiviCliente(c.id)
        if !obiettivi.isEmpty {
            SezioneTelefono(titolo: "Obiettivi")
            ForEach(Array(obiettivi.enumerated()), id: \.element.id) { i, o in
                let quota = o.importo > 0 ? min(1, max(0, o.accantonato / o.importo)) : 0
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: E.spazioRiga) {
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(o.titolo)
                                .carattereApple(E.nome)
                                .foregroundColor(E.coloreNome)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(Formati.dataBreve.string(from: o.scadenza)) · \(FormatoCifra.euro.testo(o.importo))")
                                .carattereApple(E.dettaglio)
                                .foregroundColor(E.coloreDettaglio)
                        }
                        Spacer(minLength: E.spazioRiga)
                        if o.importo > 0 {
                            NumeroCheConta((quota * 100).rounded(), formato: .percentuale, indice: i)
                                .carattereApple(E.valore)
                                .foregroundColor(E.coloreNome)
                        }
                    }
                    if o.importo > 0 {
                        BarraPiena(frazione: quota, colore: Tema.Apple.Colore.anello2, indice: i)
                            .padding(.top, C.barraSopra)
                    }
                }
                .schedaTelefono()
            }
        }
        if !c.telefono.isEmpty || !c.email.isEmpty || !c.indirizzo.isEmpty {
            SezioneTelefono(titolo: "Recapiti")
            VStack(alignment: .leading, spacing: E.spazioRiga) {
                if !c.telefono.isEmpty { DatoTelefono("Telefono", c.telefono) }
                if !c.email.isEmpty { DatoTelefono("Email", c.email) }
                if !c.indirizzo.isEmpty { DatoTelefono("Indirizzo", c.indirizzo) }
            }
            .schedaTelefono()
        }
        if !c.nota.isEmpty {
            SezioneTelefono(titolo: "Nota")
            Text(c.nota)
                .carattereApple(E.corpo)
                .foregroundColor(E.coloreNome)
                .fixedSize(horizontal: false, vertical: true)
                .schedaTelefono()
        }
    }

    @ViewBuilder private var posizioni: some View {
        let elenco = stato.posizioni.filter { $0.clienteId == clienteId && $0.stato != .chiusa }.sorted { $0.valore > $1.valore }
        if elenco.isEmpty { VuotoTelefono(testo: "Nessuna posizione in essere o in proposta.") }
        ForEach(elenco) { p in
            NavigationLink(value: DestinazioneTelefono.posizione(p.id)) { RigaPosizioneTelefono(posizione: p, conCliente: false) }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var agenda: some View {
        let elenco = stato.appuntamenti.filter { $0.clienteId == clienteId && $0.fine > Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.inizio < $1.inizio }
        if elenco.isEmpty { VuotoTelefono(testo: "Nessun appuntamento in programma.") }
        ForEach(elenco) { a in
            NavigationLink(value: DestinazioneTelefono.appuntamento(a.id)) { RigaAppuntamentoTelefono(appuntamento: a, conGiorno: true) }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var documenti: some View {
        let elenco = stato.documentiCliente(clienteId)
        if elenco.isEmpty { VuotoTelefono(testo: "Nessun documento.") }
        ForEach(elenco) { RigaDocumentoTelefono(documento: $0) }
    }
}

// MARK: - Posizioni

/// Posizioni sull'iPhone (Design/iphone.html, schermata 3), il fulcro: il filtro dei canali a pillola, il totale
/// grande che conta con la barra dei canali, le aree con il loro peso, poi le posizioni più grandi.
private struct PosizioniTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @State private var filtro = FiltroPosizioniTelefono.tutte

    /// Le aree con le loro posizioni: le attività dalla più grande, i debiti in fondo.
    private static func aree(_ elenco: [Posizione]) -> [(AreaPosizione, [Posizione])] {
        let piene: [(area: AreaPosizione, posizioni: [Posizione], totale: Double)] = AreaPosizione.allCases.compactMap { a in
            let d = elenco.filter { $0.area == a }
            let totale: Double = d.reduce(0) { $0 + $1.valore }
            return d.isEmpty ? nil : (a, d, totale)
        }
        let attive = piene.filter { !$0.area.passivo }.sorted { $0.totale > $1.totale }
        let passive = piene.filter { $0.area.passivo }
        return (attive + passive).map { ($0.area, $0.posizioni) }
    }

    var body: some View {
        let scelte = filtro.applica(stato.posizioni)
        // Il totale e i canali sono le attività: i debiti stanno a parte, in fondo alle aree, in negativo
        let attive = scelte.filter { !$0.area.passivo }
        let totale = attive.reduce(0) { $0 + $1.valore }
        let proposte = stato.posizioni.filter { $0.stato == .proposta }.count
        FondoTelefono {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tema.Apple.Telefono.Posizioni.spazioFiltro) {
                    ForEach(FiltroPosizioniTelefono.tutti(proposte: proposte), id: \.0) { f, titolo in
                        Button { filtro = f } label: {
                            GettoneFiltroTelefono(titolo: titolo, canale: f.canale, scelto: filtro == f)
                        }
                        .buttonStyle(StileSemplice())
                    }
                }
                .padding(.vertical, Tema.Apple.Telefono.Posizioni.spazioFiltro / 2)
            }
            .entrataCascata(0)
            TotaleTelefono(titolo: filtro == .proposte ? "In proposta" : "In essere", totale: totale,
                           perCanale: filtro.canale == nil ? Self.perCanale(attive) : [])
                .entrataCascata(1)
            if scelte.isEmpty {
                VuotoTelefono(testo: filtro == .proposte ? "Nessuna proposta aperta." : "Nessuna posizione in essere.")
            } else {
                SezioneTelefono(titolo: "Per area")
                    .entrataCascata(2)
                elencoAree(scelte, totale: totale)
                    .entrataCascata(3)
                SezioneTelefono(titolo: "Le più grandi")
                    .entrataCascata(4)
                ForEach(attive.sorted { $0.valore > $1.valore }.prefix(5)) { posizione in
                    NavigationLink(value: DestinazioneTelefono.posizione(posizione.id)) {
                        RigaPosizioneTelefono(posizione: posizione, conCliente: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Posizioni")
        // Inquadra e capisci (giro 5, InquadraTelefono.swift): la fotocamera legge la polizza e manda il testo al Mac
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PulsanteInquadraTelefono()
            }
        }
        .inquadraTelefono(stato)
    }

    /// Le aree in una card sola, divise dal filo; ognuna apre le sue posizioni con lo stesso filtro.
    private func elencoAree(_ scelte: [Posizione], totale: Double) -> some View {
        let aree = Self.aree(scelte)
        return VStack(spacing: 0) {
            ForEach(Array(aree.enumerated()), id: \.element.0) { i, voce in
                NavigationLink(value: DestinazioneTelefono.area(voce.0.rawValue, filtro: filtro.chiave)) {
                    RigaAreaTelefono(area: voce.0, posizioni: voce.1, totale: totale, indice: i)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    if i > 0 {
                        Rectangle()
                            .fill(Tema.Apple.Colore.separatore)
                            .frame(height: Tema.Apple.Misura.bordo)
                    }
                }
            }
        }
        .superficieApple(E.superficiePannello, raggio: E.raggioPannello)
    }

    /// Quanto vale ciascun canale fra le posizioni date (Alleanza e indipendente sempre distinti).
    static func perCanale(_ elenco: [Posizione]) -> [(Canale, Double)] {
        Canale.allCases.map { c in (c, elenco.filter { $0.canale == c }.reduce(0) { $0 + $1.valore }) }
    }
}

/// Il filtro delle posizioni: tutte in essere, un canale, oppure le proposte.
enum FiltroPosizioniTelefono: Hashable {
    case tutte, canale(Canale), proposte

    var canale: Canale? { if case .canale(let c) = self { return c } else { return nil } }

    func applica(_ elenco: [Posizione]) -> [Posizione] {
        switch self {
        case .tutte: return elenco.filter { $0.stato == .inEssere }
        case .canale(let c): return elenco.filter { $0.stato == .inEssere && $0.canale == c }
        case .proposte: return elenco.filter { $0.stato == .proposta }
        }
    }

    /// Per la destinazione di un'area: «tutte», «proposte» o il canale.
    var chiave: String {
        switch self {
        case .tutte: return "tutte"
        case .proposte: return "proposte"
        case .canale(let c): return c.rawValue
        }
    }

    init(chiave: String) {
        switch chiave {
        case "proposte": self = .proposte
        default: self = Canale(rawValue: chiave).map { .canale($0) } ?? .tutte
        }
    }

    static func tutti(proposte: Int) -> [(FiltroPosizioniTelefono, String)] {
        [(.tutte, "Tutte")] + Canale.allCases.map { (.canale($0), $0.nomeBreve) } + [(.proposte, "Proposte · \(proposte)")]
    }
}

/// Un gettone del filtro, a capsula come il segmentato del tema: `chip`, scelto sulla pillola `cardPiena` con
/// l'ombra; il pallino del canale (blu Alleanza, cuoio indipendente) davanti al nome. Alto 36, area di tocco 44.
private struct GettoneFiltroTelefono: View {
    let titolo: String
    let canale: Canale?
    let scelto: Bool

    private typealias P = Tema.Apple.Telefono.Posizioni

    var body: some View {
        HStack(spacing: P.spazioPallino) {
            if let canale {
                Circle()
                    .fill(canale == .alleanza ? Tema.Apple.Colore.canaleAlleanza : Tema.Apple.Colore.canaleIndipendente)
                    .frame(width: P.pallino, height: P.pallino)
            }
            Text(titolo)
                .lineLimit(1)
        }
        .carattereApple(P.filtro)
        .foregroundColor(scelto ? Tema.Apple.Colore.inchiostro : Tema.Apple.Colore.inchiostro2)
        .padding(.horizontal, P.paddingFiltro)
        .frame(height: P.altezzaFiltro)
        .background {
            if scelto {
                Capsule(style: .continuous)
                    .fill(Tema.Apple.Colore.cardPiena)
                    .ombraApple(.pillola)
            } else {
                Capsule(style: .continuous)
                    .fill(Tema.Apple.Colore.chip)
            }
        }
        .frame(minHeight: Tema.Apple.Telefono.tocco)
        .contentShape(Rectangle())
        .accessibilityAddTraits(scelto ? .isSelected : [])
    }
}

/// Il numero principale: l'etichetta, il totale grande che conta, la barra dei canali e l'importo di ciascuno.
struct TotaleTelefono: View {
    let titolo: String
    let totale: Double
    /// Vuoto: niente barra (un solo canale scelto).
    let perCanale: [(Canale, Double)]
    /// I debiti sotto i canali: canali meno debiti tornano con il netto in grande (0: nessuna riga).
    var debiti: Double = 0

    private typealias P = Tema.Apple.Telefono.Posizioni

    var body: some View {
        let alleanza = perCanale.first { $0.0 == .alleanza }?.1 ?? 0
        let indipendente = perCanale.first { $0.0 == .indipendente }?.1 ?? 0
        VStack(alignment: .leading, spacing: 0) {
            Text(titolo)
                .carattereApple(Tema.Apple.Telefono.Cliente.etichetta)
                .foregroundColor(Tema.Apple.Telefono.Cliente.coloreEtichetta)
                .lineLimit(1)
            NumeroCheConta(totale, formato: .euro)
                .carattereApple(P.totale)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(P.riduzioneTotale)
            if !perCanale.isEmpty && (alleanza > 0 || indipendente > 0) {
                BarraPienaSegmenti.canali(alleanza: max(alleanza, 0), indipendente: max(indipendente, 0))
                    .padding(.top, P.barraSopra)
                    .padding(.bottom, P.barraSotto)
            }
            if !perCanale.isEmpty {
                VStack(alignment: .leading, spacing: P.spazioCanali) {
                    ForEach(perCanale, id: \.0) { c, v in
                        HStack(spacing: E.spazioRiga) {
                            EtichettaCanaleApple(canale: c, compatta: true)
                            Spacer(minLength: E.spazioRiga)
                            Text(FormatoCifra.euro.testo(v))
                                .carattereApple(E.valore)
                                .foregroundColor(E.coloreNome)
                                .lineLimit(1)
                        }
                    }
                    if debiti > 0 {
                        HStack(spacing: E.spazioRiga) {
                            Text("Debiti")
                                .carattereApple(E.valore)
                                .foregroundColor(E.coloreNome)
                            Spacer(minLength: E.spazioRiga)
                            Text(FormatoCifra.euro.testo(-debiti))
                                .carattereApple(E.valore)
                                .foregroundColor(E.coloreNome)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .pannelloTelefono()
    }
}

/// Un'area: la striscia del suo colore, il nome, quante posizioni, l'importo e il peso sul totale (la barra).
private struct RigaAreaTelefono: View {
    let area: AreaPosizione
    let posizioni: [Posizione]
    /// Il totale delle attività scelte: il peso dell'area (i debiti non hanno barra).
    let totale: Double
    let indice: Int

    private typealias P = Tema.Apple.Telefono.Posizioni

    var body: some View {
        let valore = posizioni.reduce(0) { $0 + $1.valore }
        HStack(spacing: E.spazioRiga) {
            Capsule()
                .fill(Colori.Analisi.area(area))
                .frame(width: P.striscia, height: P.altezzaStriscia)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(area.nome)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                Text("\(posizioni.count) \(posizioni.count == 1 ? "posizione" : "posizioni")")
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                if !area.passivo && totale > 0 {
                    BarraPiena(frazione: valore / totale, colore: Colori.Analisi.area(area), indice: indice)
                        .padding(.top, E.spazioTesto)
                }
            }
            Spacer(minLength: E.spazioRiga)
            // I debiti in negativo e in rosso, come in Posizioni sul Mac
            Text(FormatoCifra.euro.testo((area.passivo ? -1 : 1) * valore))
                .carattereApple(E.valore)
                .foregroundColor(area.passivo ? P.colorePassivo : E.coloreNome)
                .lineLimit(1)
                .fixedSize()
            ChevronTelefono()
        }
        .padding(E.paddingRigaInterna)
        .frame(minHeight: E.rigaMinima)
        .contentShape(Rectangle())
    }
}

/// Le posizioni di un'area (dal riquadro «Per area»), con lo stesso filtro.
struct ElencoAreaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let area: AreaPosizione
    let filtro: FiltroPosizioniTelefono

    var body: some View {
        let elenco = filtro.applica(stato.posizioni).filter { $0.area == area }.sorted { $0.valore > $1.valore }
        FondoTelefono {
            TotaleTelefono(titolo: area.nome, totale: elenco.reduce(0) { $0 + $1.valore },
                           perCanale: filtro.canale == nil ? PosizioniTelefono.perCanale(elenco) : [])
                .entrataCascata(0)
            ForEach(elenco) { posizione in
                NavigationLink(value: DestinazioneTelefono.posizione(posizione.id)) {
                    RigaPosizioneTelefono(posizione: posizione, conCliente: true)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(area.nome)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Una posizione: il nome (fino a due righe), cliente e area, il canale e lo stato sotto; l'importo a destra.
private struct RigaPosizioneTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let posizione: Posizione
    let conCliente: Bool

    var body: some View {
        HStack(spacing: E.spazioRiga) {
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(posizione.nome)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .lineLimit(2)
                Text(dettaglio)
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(1)
                HStack(spacing: E.spazioEtichette) {
                    EtichettaCanaleApple(canale: posizione.canale, compatta: true)
                    StatoPosizioneTelefono(stato: posizione.stato)
                }
                .padding(.top, E.spazioTesto)
            }
            Spacer(minLength: E.spazioRiga)
            Text(FormatoCifra.euro.testo(posizione.valore))
                .carattereApple(E.valore)
                .foregroundColor(E.coloreNome)
                .lineLimit(1)
                .fixedSize()
        }
        .schedaTelefono(premibile: true)
    }

    private var dettaglio: String {
        let cliente = conCliente ? stato.dati.clienti.first { $0.id == posizione.clienteId }?.nome : nil
        return [cliente, posizione.area.nome].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// Il dettaglio della posizione: canale (etichetta estesa), stato, valore che conta, poi prodotto, flussi, valori e
/// costi (le cifre di Prisma, in sola lettura).
private struct DettaglioPosizioneTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let posizioneId: String

    var body: some View {
        let posizione = stato.posizioni.first { $0.id == posizioneId }
        FondoTelefono {
            if let p = posizione {
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    EtichettaCanaleApple(canale: p.canale)
                    Text(p.nome)
                        .carattereApple(E.titolo)
                        .foregroundColor(E.coloreNome)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: E.spazioEtichette) {
                        StatoPosizioneTelefono(stato: p.stato)
                        Text(p.area.nome)
                            .carattereApple(E.dettaglio)
                            .foregroundColor(E.coloreDettaglio)
                    }
                    NumeroCheConta(p.valore, formato: .euro)
                        .carattereApple(E.cifra)
                        .foregroundColor(E.coloreNome)
                        .lineLimit(1)
                        .minimumScaleFactor(Tema.Apple.Telefono.Posizioni.riduzioneTotale)
                }
                .pannelloTelefono()
                .entrataCascata(0)

                SezioneTelefono(titolo: "Prodotto")
                    .entrataCascata(1)
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    if let cliente = stato.dati.clienti.first(where: { $0.id == p.clienteId }) {
                        DatoTelefono("Cliente", cliente.nome)
                    }
                    if !p.tipologia.isEmpty { DatoTelefono("Tipologia", p.tipologia) }
                    if !p.emittente.isEmpty { DatoTelefono("Emittente", p.emittente) }
                    if !p.numeroContratto.isEmpty { DatoTelefono("Contratto", p.numeroContratto) }
                    if let d = p.decorrenza { DatoTelefono("Decorrenza", Formati.dataBreve.string(from: d)) }
                    if let d = p.scadenza { DatoTelefono("Scadenza", Formati.dataBreve.string(from: d)) }
                }
                .schedaTelefono()
                .entrataCascata(2)

                SezioneTelefono(titolo: "Flussi e valori")
                    .entrataCascata(3)
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    if p.versamentoIniziale > 0 { DatoTelefono("Versamento iniziale", Formati.euro(p.versamentoIniziale)) }
                    if p.premio > 0 { DatoTelefono("Premio (\(p.frequenza.nome.lowercased()))", Formati.euro(p.premio)) }
                    if let v = p.totaleVersato { DatoTelefono("Totale versato", Formati.euro(v)) }
                    if let v = p.controvalore { DatoTelefono("Controvalore", Formati.euro(v)) }
                    if let d = p.dataValore { DatoTelefono("Valore al", Formati.dataBreve.string(from: d)) }
                    if let v = p.capitaleAssicurato { DatoTelefono("Capitale assicurato", Formati.euro(v)) }
                    DatoTelefono("Valore nei riepiloghi", Formati.euro(p.valore))
                }
                .schedaTelefono()
                .entrataCascata(4)

                if p.rendimentoAtteso != nil || p.costoIngresso != nil || p.costoAnnuo != nil || p.sri != nil {
                    SezioneTelefono(titolo: "Ipotesi e costi")
                    VStack(alignment: .leading, spacing: E.spazioRiga) {
                        if let v = p.rendimentoAtteso { DatoTelefono("Rendimento lordo atteso", Formati.percentuale(v)) }
                        if let v = p.costoIngresso { DatoTelefono("Costo d'ingresso", Formati.percentuale(v)) }
                        if let v = p.costoAnnuo { DatoTelefono("Costo annuo", Formati.percentuale(v)) }
                        if let v = p.sri { DatoTelefono("Rischio (SRI)", "\(v) su 7") }
                    }
                    .schedaTelefono()
                }
            } else {
                VuotoTelefono(testo: "Questa posizione non c'è più nell'archivio.")
            }
        }
        .navigationTitle(posizione?.nome ?? "Posizione")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Agenda

/// L'agenda dell'iPhone (Design/iphone.html, schermata 4): il mese intero con un puntino blu per gli appuntamenti
/// e uno arancio per le cose da fare; sotto, il giorno scelto con i suoi appuntamenti e le sue attività.
private struct AgendaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @State private var mese = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var giorno = Calendar.current.startOfDay(for: Date())

    var body: some View {
        let cal = Calendar.current
        let delGiorno = stato.appuntamenti.filter { cal.isDate($0.inizio, inSameDayAs: giorno) }.sorted { $0.inizio < $1.inizio }
        let daFare = stato.attivitaAperte.filter { cal.isDate($0.scadenza, inSameDayAs: giorno) }
        FondoTelefono {
            MeseTelefono(mese: $mese, giorno: $giorno,
                         conAppuntamenti: Set(stato.appuntamenti.map { cal.startOfDay(for: $0.inizio) }),
                         conAttivita: Set(stato.attivitaAperte.map { cal.startOfDay(for: $0.scadenza) }))
                .entrataCascata(0)
            SezioneTelefono(titolo: Formati.dataLunga.string(from: giorno) + " · appuntamenti")
                .entrataCascata(1)
            if delGiorno.isEmpty {
                VuotoTelefono(testo: "Nessun appuntamento.")
            }
            ForEach(Array(delGiorno.enumerated()), id: \.element.id) { i, appuntamento in
                NavigationLink(value: DestinazioneTelefono.appuntamento(appuntamento.id)) {
                    RigaAppuntamentoTelefono(appuntamento: appuntamento)
                }
                .buttonStyle(.plain)
                .entrataLaterale(i)
            }
            if !daFare.isEmpty {
                SezioneTelefono(titolo: "Da fare")
                ForEach(daFare) { a in
                    HStack(spacing: E.spazioRiga) {
                        CerchioAttivitaTelefono(fatta: a.completata)
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(a.titolo)
                                .carattereApple(E.nome)
                                .foregroundColor(E.coloreNome)
                                .fixedSize(horizontal: false, vertical: true)
                            if let c = stato.cliente(a.clienteId) {
                                Text(c.nome)
                                    .carattereApple(E.dettaglio)
                                    .foregroundColor(E.coloreDettaglio)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .schedaTelefono()
                }
            }
        }
        .navigationTitle("Agenda")
    }
}

/// Il mese: le frecce tonde, il mese 20 bold, i giorni della settimana, le caselle con i loro puntini. Oggi rosso
/// pieno con il numero bianco, il giorno scelto sull'accento al 14%. Un tocco sceglie il giorno.
private struct MeseTelefono: View {
    @Binding var mese: Date
    @Binding var giorno: Date
    let conAppuntamenti: Set<Date>
    let conAttivita: Set<Date>

    private typealias A = Tema.Apple.Telefono.Agenda

    var body: some View {
        let giorni = Self.griglia(mese)
        VStack(spacing: A.spazio) {
            HStack {
                freccia("chevron.left", aiuto: "Mese prima") { cambia(-1) }
                Spacer()
                Text(Formati.meseAnno.string(from: mese).prefix(1).uppercased() + Formati.meseAnno.string(from: mese).dropFirst())
                    .carattereApple(A.mese)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Spacer()
                freccia("chevron.right", aiuto: "Mese dopo") { cambia(1) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: A.spazioRighe) {
                ForEach(Array(Self.iniziali.enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .carattereApple(A.intestazione)
                        .foregroundColor(A.coloreIntestazione)
                }
                ForEach(giorni, id: \.self) { d in cella(d) }
            }
            HStack(spacing: A.spazio * 2) {
                HStack(spacing: A.spazioPuntini * 2) { punto(A.appuntamento); Text("Appuntamenti") }
                HStack(spacing: A.spazioPuntini * 2) { punto(A.attivita); Text("Da fare") }
            }
            .carattereApple(A.legenda)
            .foregroundColor(A.coloreLegenda)
        }
        .pannelloTelefono()
    }

    /// Una freccia tonda `chip` da 36, area di tocco 44.
    private func freccia(_ simbolo: String, aiuto: String, _ azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: simbolo)
                .carattereApple(A.simboloFreccia)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .frame(width: A.freccia, height: A.freccia)
                .background(Circle().fill(A.fondoFreccia))
                .frame(width: Tema.Apple.Telefono.tocco, height: Tema.Apple.Telefono.tocco)
                .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .accessibilityLabel(aiuto)
    }

    private func punto(_ c: Color) -> some View {
        Circle().fill(c).frame(width: A.puntino, height: A.puntino)
    }

    /// Un giorno: il numero (bianco su rosso oggi, accento se scelto, chiaro fuori dal mese) e i suoi puntini.
    private func cella(_ d: Date) -> some View {
        let cal = Calendar.current
        let fuori = !cal.isDate(d, equalTo: mese, toGranularity: .month)
        let scelto = cal.isDate(d, inSameDayAs: giorno)
        let oggi = cal.isDateInToday(d)
        let coloreNumero: Color = oggi ? A.testoOggi : scelto ? A.testoScelto : fuori ? A.coloreFuori : A.coloreNumero
        let fondo: Color? = oggi ? A.fondoOggi : scelto ? A.fondoScelto : nil
        return Button {
            giorno = d
            if fuori { mese = cal.dateInterval(of: .month, for: d)?.start ?? mese }
        } label: {
            VStack(spacing: A.spazioPuntini) {
                Text("\(cal.component(.day, from: d))")
                    .carattereApple(scelto || oggi ? A.numeroForte : A.numero)
                    .foregroundColor(coloreNumero)
                HStack(spacing: A.spazioPuntini) {
                    if conAppuntamenti.contains(d) { punto(oggi ? A.puntinoSuOggi : A.appuntamento) }
                    if conAttivita.contains(d) { punto(oggi ? A.puntinoSuOggi : A.attivita) }
                }
                .frame(height: A.puntino)
            }
            .frame(maxWidth: .infinity, minHeight: A.cella)
            .background {
                if let fondo {
                    RoundedRectangle(cornerRadius: A.raggio, style: .continuous).fill(fondo)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .accessibilityAddTraits(scelto ? .isSelected : [])
    }

    private func cambia(_ n: Int) {
        mese = Calendar.current.date(byAdding: .month, value: n, to: mese) ?? mese
    }

    /// L'iniziale dei giorni da lunedì.
    static let iniziali = ["L", "M", "M", "G", "V", "S", "D"]

    /// I giorni da mostrare: le settimane intere (da lunedì) che contengono il mese.
    static func griglia(_ mese: Date) -> [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let intervallo = cal.dateInterval(of: .month, for: mese) else { return [] }
        let primo = intervallo.start
        let spostamento = (cal.component(.weekday, from: primo) - cal.firstWeekday + 7) % 7
        let inizio = cal.date(byAdding: .day, value: -spostamento, to: primo) ?? primo
        let giorniMese = cal.range(of: .day, in: .month, for: mese)?.count ?? 30
        let celle = Int(ceil(Double(spostamento + giorniMese) / 7)) * 7
        return (0..<celle).compactMap { cal.date(byAdding: .day, value: $0, to: inizio) }.map { cal.startOfDay(for: $0) }
    }
}

/// Un appuntamento: la barra di 3 nel colore del cliente, l'ora e la durata, il titolo, cliente e luogo, il canale
/// sotto (titolo e cliente restano interi). `conGiorno`: il giorno sopra l'ora (elenchi di più giorni).
private struct RigaAppuntamentoTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let appuntamento: Appuntamento
    var conGiorno = false

    var body: some View {
        let cliente = stato.cliente(appuntamento.clienteId)
        HStack(spacing: E.spazioRiga) {
            RoundedRectangle(cornerRadius: E.barra / 2, style: .continuous)
                .fill(cliente?.tinta.colori.basso ?? Tema.Apple.Colore.accento)
                .frame(width: E.barra)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                if conGiorno {
                    Text(Formati.giornoRelativo(appuntamento.inizio))
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                        .lineLimit(1)
                }
                Text(Formati.ora.string(from: appuntamento.inizio))
                    .carattereApple(E.valore)
                    .foregroundColor(E.coloreNome)
                Text("\(appuntamento.durataMinuti) min")
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(appuntamento.titolo)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .lineLimit(2)
                Text(dettaglio(cliente))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(1)
                // Il canale sotto, non accanto: titolo e cliente restano interi
                if let canale = appuntamento.canale {
                    EtichettaCanaleApple(canale: canale, compatta: true)
                        .padding(.top, E.spazioTesto)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .schedaTelefono(premibile: true)
        .opacity(appuntamento.stato == .concluso ? E.opacitaConcluso : 1)
    }

    private func dettaglio(_ cliente: Cliente?) -> String {
        [cliente?.nome, appuntamento.luogo.isEmpty ? nil : appuntamento.luogo].compactMap { $0 }.joined(separator: " · ")
    }
}

/// Il dettaglio dell'appuntamento: il blocco della data, il titolo, giorno e ore, il canale; poi cliente, tipo,
/// luogo, stato, posizione collegata e note.
private struct DettaglioAppuntamentoTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let appuntamentoId: String

    var body: some View {
        let appuntamento = stato.appuntamenti.first { $0.id == appuntamentoId }
        FondoTelefono {
            if let a = appuntamento {
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    HStack(alignment: .top, spacing: E.spazioRiga) {
                        BloccoDataTelefono(data: a.inizio)
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(a.titolo)
                                .carattereApple(E.titolo)
                                .foregroundColor(E.coloreNome)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(Formati.dataLunga.string(from: a.inizio)) · \(Formati.ora.string(from: a.inizio))–\(Formati.ora.string(from: a.fine))")
                                .carattereApple(E.dettaglio)
                                .foregroundColor(E.coloreDettaglio)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let canale = a.canale { EtichettaCanaleApple(canale: canale) }
                }
                .pannelloTelefono()
                .entrataCascata(0)
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    if let cliente = stato.dati.clienti.first(where: { $0.id == a.clienteId }) {
                        DatoTelefono("Cliente", cliente.nome)
                    }
                    DatoTelefono("Tipo", a.tipo.nome)
                    if !a.luogo.isEmpty { DatoTelefono("Luogo", a.luogo) }
                    DatoTelefono("Stato", a.stato == .concluso ? "Concluso" : "Pianificato")
                    if let id = a.posizioneId, let p = stato.posizioni.first(where: { $0.id == id }) {
                        DatoTelefono("Posizione", p.nome)
                    }
                }
                .schedaTelefono()
                .entrataCascata(1)
                if !a.note.isEmpty {
                    SezioneTelefono(titolo: "Note")
                    Text(a.note)
                        .carattereApple(E.corpo)
                        .foregroundColor(E.coloreNome)
                        .fixedSize(horizontal: false, vertical: true)
                        .schedaTelefono()
                }
            } else {
                VuotoTelefono(testo: "Questo appuntamento non c'è più nell'archivio.")
            }
        }
        .navigationTitle("Appuntamento")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
