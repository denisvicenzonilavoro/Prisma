#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

/// App Impostazioni. Sul Mac nel tema Apple (§4.6, ImpostazioniAppleMac.swift): barra laterale 260 con le sezioni
/// (Panoramica, Aspetto, Archivio e backup, Vera, Profilo; poi Studio, Agenda e lavoro, Promemoria e occasioni, Conformità,
/// Proposte e PDF, Rendimenti di confronto, Scorciatoie; in fondo Strumenti) e a destra la pagina con il titolo
/// `.h2` e le righe come card senza ombra (titolo, spiegazione, controllo a destra). Lo stesso sull'iPad; l'iPhone ha
/// ImpostazioniTelefono. Le pagine stanno anche in ImpostazioniPagine.swift (lavoro, promemoria,
/// conformità, PDF, Vera, voce) e ImpostazioniArchivio.swift (archivio e backup).
struct AppImpostazioni: View {
    @EnvironmentObject var stato: StatoShell
    @State var daRipristinare: VoceBackup?
    @State var fileDaRipristinare: URL?
    @State var confermaDatiProva = false
    @State var confermaClientiCompleti = false
    @State var confermaTogliProva = false
    @State var modificaNome = false
    // Password dei backup
    @State var passwordRipristino = ""
    @State var nuovaPassword = ""
    @State var confermaPassword = ""
    @State var erroreNuovaPassword: String?
    @State var confermaTogliPassword = false
    /// Vera › Avanzate (fornitore e indirizzo) e Strumenti › Parlare con Vera: chiusi finché non servono.
    @State var mostraAvanzateVera = false
    @State var mostraVoce = false
    /// «Riduci movimento» del sistema (per dire che è già acceso anche se quello di Prisma è spento).
    @Environment(\.accessibilityReduceMotion) var calmoSistema

    typealias M = Tema.Misura.Impostazioni

    var body: some View {
        corpo
        .alert("Ripristinare questo backup?", isPresented: Binding(get: { daRipristinare != nil || fileDaRipristinare != nil },
                                                                   set: { if !$0 { daRipristinare = nil; fileDaRipristinare = nil } })) {
            Button("Annulla", role: .cancel) {}
            Button("Ripristina", role: .destructive) {
                if let url = daRipristinare?.url ?? fileDaRipristinare { stato.ripristina(url) }
            }
        } message: {
            Text("I dati attuali verranno sostituiti da quelli del backup \"\(daRipristinare?.nome ?? fileDaRipristinare?.lastPathComponent ?? "")\". Prima del ripristino Prisma salva una copia di sicurezza dello stato attuale.")
        }
        .alert("Togliere i clienti di prova?", isPresented: $confermaTogliProva) {
            Button("Annulla", role: .cancel) {}
            Button("Togli i clienti di prova", role: .destructive) { stato.togliDatiDiProva() }
        } message: {
            Text("I clienti di prova (Giulia, Marco, Laura, Andrea, Sofia e quelli inventati) vengono tolti con posizioni, agenda, documenti e conversazioni. I tuoi clienti restano. Prima Prisma salva un backup dello stato attuale.")
        }
        .alert("Caricare i 35 clienti di prova?", isPresented: $confermaClientiCompleti) {
            Button("Annulla", role: .cancel) {}
            Button("Carica i clienti di prova", role: .destructive) { stato.ripristinaDatiDiProva(completi: true) }
        } message: {
            Text("Clienti, posizioni, agenda e attività vengono sostituiti da 35 clienti inventati. Prima Prisma salva un backup dello stato attuale: i tuoi dati si recuperano da lì.")
        }
        .alert("Tornare ai dati di prova?", isPresented: $confermaDatiProva) {
            Button("Annulla", role: .cancel) {}
            Button("Ripristina i dati di prova", role: .destructive) { stato.ripristinaDatiDiProva() }
        } message: {
            Text("Clienti, agenda e attività tornano ai 5 clienti di prova. Prima Prisma salva un backup dello stato attuale.")
        }
        // Backup protetto da ripristinare: la richiesta si chiude solo dai pulsanti, che leggono il file prima di chiuderla
        .alert("Backup protetto da password", isPresented: Binding(get: { stato.ripristinoDaSbloccare != nil }, set: { _ in })) {
            SecureField("Password", text: $passwordRipristino)
            Button("Annulla", role: .cancel) {
                passwordRipristino = ""
                stato.ripristinoDaSbloccare = nil
            }
            Button("Ripristina") {
                let password = passwordRipristino
                let url = stato.ripristinoDaSbloccare?.url
                passwordRipristino = ""
                stato.ripristinoDaSbloccare = nil
                if let url, !password.isEmpty { stato.ripristina(url, password: password) }
            }
        } message: {
            Text(stato.ripristinoDaSbloccare?.messaggio ?? "")
        }
        .alert("Togliere la password dai backup?", isPresented: $confermaTogliPassword) {
            Button("Annulla", role: .cancel) {}
            Button("Togli la password", role: .destructive) { stato.togliPasswordBackup() }
        } message: {
            Text("I prossimi backup non saranno protetti. Quelli già protetti restano protetti e si aprono solo con la loro password.")
        }
    }

    // MARK: Barra laterale e pagina

    /// Il tema Apple sul Mac e sull'iPad (ImpostazioniAppleMac.swift; sull'iPhone c'è ImpostazioniTelefono).
    private var corpo: some View {
        corpoApple
    }

    /// Le pagine delle preferenze; Strumenti in fondo, sotto la sua etichetta.
    @ViewBuilder private var rail: some View {
        EtichettaRail(testo: "Impostazioni")
        VStack(spacing: 0) {
            ForEach(SchedaImpostazioni.preferenze) { p in
                VoceImpostazioni(pagina: p, attiva: stato.schedaImpostazioni == p) { stato.schedaImpostazioni = p }
            }
        }
        EtichettaRail(testo: "Per le prove")
        VoceImpostazioni(pagina: .strumenti, attiva: stato.schedaImpostazioni == .strumenti) {
            stato.schedaImpostazioni = .strumenti
        }
    }

    /// La pagina scelta: titolo grande (.set-h) e gruppi, dentro una colonna leggibile (la griglia dei
    /// rendimenti prende tutta la larghezza). Cambiando pagina si riparte dall'alto.
    private var pagina: some View {
        let scelta = stato.schedaImpostazioni
        return ScrollViewReader { lettore in
            ScrollView {
                VStack(alignment: .leading, spacing: M.spazioGruppi) {
                    TitoloPaginaImpostazioni(testo: scelta.titolo)
                    contenuto(scelta)
                }
                .frame(maxWidth: scelta == .rendimenti ? .infinity : M.larghezzaPagina, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(M.marginePagina)
            }
            // Senza barra di scorrimento: i gruppi restano larghi uguali in tutte le pagine
            .scrollIndicators(.hidden)
            .id(scelta)
            .onAppear { scorri(lettore) }
            .onChange(of: stato.ancoraImpostazioni) { _ in scorri(lettore) }
        }
    }

    @ViewBuilder func contenuto(_ pagina: SchedaImpostazioni) -> some View {
        switch pagina {
        case .panoramica: panoramica
        case .profilo: profilo
        case .aspetto: aspetto
        case .ovunque: PaginaImpostazioniOvunque()
        case .lavoro: lavoro
        case .promemoria: promemoriaEOccasioni
        case .conformita: conformita
        case .proposte:
            ImpostazioniProposte()
            gruppoPDF
                .id("impostazioni-pdf")
        case .rendimenti: ImpostazioniRiferimenti()
        case .vera: paginaVera
        case .archivio:
            #if os(macOS)
            archivio
            #elseif os(iOS)
            // Su iPhone e iPad: apertura di un altro backup e backup da rimandare al Mac
            ArchivioMobile()
            #endif
        case .scorciatoie: scorciatoie
        case .studio: PaginaImpostazioniStudio()
        case .mercato: PaginaImpostazioniMercato()
        case .strumenti: strumenti
        }
    }

    /// Un rimando a un punto delle Impostazioni (dalle istantanee, dall'Agenda): prima la pagina giusta, poi il
    /// gruppo in vista; poi l'ancora si dimentica. Come `ancoraPosizioni` in Posizioni.
    func scorri(_ lettore: ScrollViewProxy) {
        guard let ancora = stato.ancoraImpostazioni else { return }
        if let p = Self.paginaDellAncora(ancora), p != stato.schedaImpostazioni {
            // La pagina nuova si apre e ripassa da qui (onAppear)
            stato.schedaImpostazioni = p
            return
        }
        DispatchQueue.main.async {
            withAnimation(Animazioni.apertura) { lettore.scrollTo(ancora, anchor: .top) }
            stato.ancoraImpostazioni = nil
        }
    }

    /// La pagina di un'ancora (anche quelle di quando le impostazioni erano una pagina sola).
    static func paginaDellAncora(_ ancora: String) -> SchedaImpostazioni? {
        switch ancora {
        case "impostazioni-conformita": return .conformita
        case "impostazioni-occasioni": return .promemoria
        case "impostazioni-pdf": return .proposte
        case TestiParcelle.ancoraImpostazioni: return .studio
        case TestiFamiglie.ancoraImpostazioni: return .rendimenti
        default: return nil
        }
    }

    // MARK: Aiuti delle righe

    /// I pulsanti di vetro nelle righe (come «Verifica»).
    var margineVetro: EdgeInsets { EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10) }

    /// I segmenti delle righe: interi se c'è posto, altrimenti nella versione compatta (mai voci tagliate).
    /// Il segmentato a pillola del tema Apple (§2.8), sul Mac e sull'iPad.
    func segmenti<Valore: Hashable>(_ opzioni: [(Valore, String)], _ selezione: Binding<Valore>) -> some View {
        SegmentatoPillola(selezione: selezione, voci: opzioni)
            .fixedSize()
    }

    /// L'interruttore senza etichetta del tema Apple (§2.9), sul Mac e sull'iPad.
    func interruttore(_ acceso: Binding<Bool>) -> some View {
        Toggle(isOn: acceso) { EmptyView() }
            .toggleStyle(.appleSenzaEtichetta)
    }

    /// Una riga che apre o chiude il gruppo sotto di lei («Mostra» / «Nascondi»).
    func rigaApri(_ titolo: String, _ sottotitolo: String, aperta: Binding<Bool>, ultima: Bool) -> some View {
        RigaImpostazione(titolo: titolo, sottotitolo: sottotitolo, ultima: ultima) {
            ValoreRiga(testo: aperta.wrappedValue ? "Nascondi" : "Mostra") {
                withAnimation(Animazioni.apertura) { aperta.wrappedValue.toggle() }
            }
        }
    }

    static var versioneApp: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–" }

    static var notaArchivio: String {
        #if os(macOS)
        return "Archivio locale · solo su questo Mac"
        #else
        return "Archivio locale · dal backup del Mac"
        #endif
    }

    // MARK: Panoramica

    /// Le quattro cose da sapere a colpo d'occhio, ognuna con la sua pillola; toccate portano alla loro pagina.
    private var panoramica: some View {
        VStack(alignment: .leading, spacing: M.spazioGruppi) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: M.tesseraMinima), spacing: M.spazioTessere, alignment: .top)],
                      alignment: .leading, spacing: M.spazioTessere) {
                tesseraVera
                tesseraBackup
                tesseraPromemoria
                tesseraArchivio
            }
            if let a = avvisoPanoramica {
                GruppoImpostazioni {
                    RigaImpostazione(titolo: a.titolo, sottotitolo: a.testo, stato: Pillola(testo: "Da guardare", tono: .attenzione),
                                     ultima: true) {
                        ValoreRiga(testo: "Apri") { stato.schedaImpostazioni = a.pagina }
                    }
                }
            }
            HStack(alignment: .center, spacing: M.spazioNumeri) {
                LogoPrismaConNome(colore: Tema.Colore.logo, altezza: M.logo)
                Spacer(minLength: 0)
                Text("Il tuo spazio. Tutto a portata di mano.")
                    .font(Tema.Testo.Impostazioni.nota)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
            }
            .padding(.horizontal, M.rientroNota)
            .padding(.top, M.spazioGruppi)
        }
    }

    private var tesseraVera: some View {
        let pronta = stato.disponibilitaLocale.pronto
        #if os(macOS)
        let vera = stato.dati.impostazioni.vera
        return TesseraImpostazioni(pagina: .vera, etichetta: "Vera · \(stato.qwen.nome)", valore: vera.modello,
                                   nota: pronta ? "Sul Mac, senza internet" : "Qwen non risponde",
                                   stato: Pillola(testo: pronta ? "Pronta" : "Non pronta", tono: pronta ? .ok : .attenzione)) {
            stato.schedaImpostazioni = .vera
        }
        #else
        let abbinato = stato.dati.impostazioni.vera.ponte.abbinato
        return TesseraImpostazioni(pagina: .vera, etichetta: "Vera", valore: "Qwen sul Mac",
                                   nota: abbinato ? "Abbinata al Mac" : "Da abbinare al Mac",
                                   stato: Pillola(testo: pronta ? "Collegata" : "Non collegata", tono: pronta ? .ok : .attenzione)) {
            stato.schedaImpostazioni = .vera
        }
        #endif
    }

    private var tesseraBackup: some View {
        let b = stato.dati.impostazioni.backup
        let valore = b.ultimo.map { TestiConformita.maiuscola(Formati.giornoRelativo($0)) } ?? "Mai"
        let copie = stato.elencoBackup.count
        let nota = "\(copie == 1 ? "1 copia" : "\(copie) copie") · \(b.automatico ? "ogni settimana" : "a mano")"
        let pillola: Pillola
        if b.ultimoErrore != nil {
            pillola = Pillola(testo: "Non riuscito", tono: .errore)
        } else if b.inRitardo || b.ultimo == nil {
            pillola = Pillola(testo: "Da fare", tono: .attenzione)
        } else if stato.cartellaBackupPredefinita {
            pillola = Pillola(testo: "Sullo stesso Mac", tono: .attenzione)
        } else {
            pillola = Pillola(testo: "In regola", tono: .ok)
        }
        return TesseraImpostazioni(pagina: .archivio, etichetta: "Ultimo backup", valore: valore, nota: nota, stato: pillola) {
            stato.schedaImpostazioni = .archivio
        }
    }

    private var tesseraPromemoria: some View {
        let p = stato.dati.impostazioni.promemoria
        let tipi = [p.appuntamenti, p.attivita, p.scadenze, p.compleanni, p.occasioni]
        let accesi = tipi.filter { $0 }.count
        let pillola: Pillola
        if stato.permessoPromemoria == .negati {
            pillola = Pillola(testo: "Non consentiti", tono: .errore)
        } else if p.attivi {
            pillola = Pillola(testo: "Attivi", tono: .ok)
        } else {
            pillola = Pillola(testo: "Spenti", tono: .neutro)
        }
        return TesseraImpostazioni(pagina: .promemoria, etichetta: "Promemoria",
                                   valore: p.attivi ? "\(accesi) tipi su \(tipi.count)" : "Spenti",
                                   nota: "Centro notifiche del Mac", stato: pillola) {
            stato.schedaImpostazioni = .promemoria
        }
    }

    private var tesseraArchivio: some View {
        let pillola: Pillola
        if stato.solaLettura {
            pillola = Pillola(testo: "Sola lettura", tono: .errore)
        } else if stato.copieNonLeggibili > 0 {
            pillola = Pillola(testo: "Da controllare", tono: .attenzione)
        } else {
            pillola = Pillola(testo: "Locale", tono: .ok)
        }
        let clienti = stato.clienti.count
        return TesseraImpostazioni(pagina: .archivio, etichetta: "Archivio",
                                   valore: clienti == 1 ? "1 cliente" : "\(clienti) clienti",
                                   nota: "Versione \(DatiPrisma.versioneAttuale) dell'archivio", stato: pillola) {
            stato.schedaImpostazioni = .archivio
        }
    }

    /// Il problema più importante, se c'è: backup non riusciti, archivio in sola lettura, Qwen da preparare.
    private var avvisoPanoramica: (titolo: String, testo: String, pagina: SchedaImpostazioni)? {
        if stato.solaLettura {
            return ("Archivio in sola lettura", "Salvato da una versione più recente di Prisma", .archivio)
        }
        if stato.copieNonLeggibili > 0 {
            return ("Backup automatici fermi", "All'avvio l'archivio non era leggibile", .archivio)
        }
        if let e = avvertenzaBackup {
            return ("Backup", e, .archivio)
        }
        #if os(macOS)
        if !stato.disponibilitaLocale.pronto {
            return ("Vera non è pronta", stato.disponibilitaLocale.motivo ?? "Qwen non risponde", .vera)
        }
        #endif
        return nil
    }

    // MARK: Profilo

    /// Avatar e nome come nel tema e i due canali con le loro etichette (la dimensione del testo è in Aspetto).
    var profilo: some View {
        VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni {
                HStack(spacing: Tema.Misura.Componenti.spazioTessere) {
                    AvatarProfilo(iniziali: stato.inizialiUtente)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stato.nomeUtente)
                            .font(Tema.Testo.Impostazioni.nomeProfilo)
                            .foregroundColor(Tema.Colore.inchiostro)
                        Text("Consulente finanziario")
                            .font(Tema.Testo.secondario)
                            .foregroundColor(Tema.Colore.inchiostroSecondario)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Tema.Misura.Componenti.margineRiga)
                .overlay(alignment: .bottom) { Rectangle().fill(Tema.Colore.separatore).frame(height: Tema.Misura.filo) }
                RigaImpostazione(titolo: "Il tuo nome", sottotitolo: "Come ti accoglie la scrivania", ultima: true) {
                    ValoreRiga(testo: stato.nomeUtente) { modificaNome = true }
                        .popover(isPresented: $modificaNome, arrowEdge: .leading) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Il tuo nome").font(Tipo.rigaTitolo)
                                // Il nome entra nei documenti: passa all'archivio poco dopo l'ultimo tasto
                                TestoRinviato(testo: $stato.dati.impostazioni.nomeUtente, salvaOra: { stato.salvaOra() }) { bozza in
                                    TextField("Nome", text: bozza)
                                        .campoTesto()
                                        .frame(width: M.campoNome)
                                        .onSubmit { modificaNome = false }
                                }
                            }
                            .padding(M.margineCampoNome)
                        }
                }
            }
            GruppoImpostazioni(titolo: "Canali") {
                RigaImpostazione(titolo: "Alleanza Assicurazioni", sottotitolo: "Solo prodotti Alleanza") {
                    EtichettaCanale(canale: .alleanza)
                }
                RigaImpostazione(titolo: "Consulenza indipendente", sottotitolo: "Investimenti, risparmio, previdenza, protezione",
                                 ultima: true) {
                    EtichettaCanale(canale: .indipendente)
                }
            }
            NotaImpostazioni("Ogni posizione e ogni proposta porta l'etichetta del suo canale.")
        }
    }

    // MARK: Aspetto

    /// Come nel template (§4.6, PIE i01, i02, i09): Chiaro / Scuro / Automatico (Automatico segue il Mac, a caldo),
    /// lo sfondo d'acqua animato o fermo e quanta pioggia cade, «L'acqua della scrivania», «Riduci movimento» e la
    /// dimensione del testo. Si salvano con le altre impostazioni e valgono subito. Poi la finestra e l'aiuto.
    /// Sul Mac le righe entrano a cascata (base 0) ogni volta che si apre la sezione.
    var aspetto: some View {
        let animato = stato.dati.impostazioni.sfondoAnimato
        let aspetti: [AspettoInterfaccia] = [.chiaro, .scuro, .automatico]
        let pioggia = stato.dati.impostazioni.pioggia.nome.lowercased()
        let testoAcqua: String = animato ? "Pioggia \(pioggia), sempre attiva. Toccando l'acqua cade una goccia."
                                         : "Con lo sfondo fermo l'acqua non risponde."
        // Con «Riduci movimento» acceso nel sistema decide il sistema: l'interruttore mostra lo stato effettivo
        // (acceso, fermo) e la nota dice perché; da qui non si spegne
        #if os(macOS)
        let doveSistema = "nelle impostazioni del Mac"
        #else
        let doveSistema = "nelle impostazioni del dispositivo"
        #endif
        let testoCalmo: String = calmoSistema
            ? "Attivo perché è acceso \(doveSistema): animazioni brevi e acqua ferma."
            : "Animazioni brevi e acqua ferma."
        let calmoEffettivo = Binding<Bool>(get: { calmoSistema || stato.dati.impostazioni.riduciMovimento },
                                           set: { if !calmoSistema { stato.dati.impostazioni.riduciMovimento = $0 } })
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni {
                RigaImpostazione(titolo: "Aspetto", sottotitolo: "Chiaro, scuro o automatico come il Mac.") {
                    segmenti(aspetti.map { ($0, $0.nome) }, $stato.dati.impostazioni.aspetto)
                }
                .cascataImpostazioni(1)
                RigaImpostazione(titolo: "Sfondo", sottotitolo: "Acqua con le gocce al rallentatore.",
                                 aiuto: "L'acqua della scrivania con le gocce al rallentatore; si ferma da sola quando non si vede") {
                    segmenti([(true, "Animato"), (false, "Fermo")], $stato.dati.impostazioni.sfondoAnimato)
                }
                .cascataImpostazioni(2)
                RigaImpostazione(titolo: "Pioggia", sottotitolo: animato ? "Quante gocce cadono." : "Con lo sfondo fermo non piove.") {
                    segmenti(IntensitaPioggia.allCases.map { ($0, $0.nome) }, $stato.dati.impostazioni.pioggia)
                        .disabled(!animato)
                        .opacity(animato ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
                }
                .cascataImpostazioni(3)
                // «L'acqua risponde» (SfondoAcquaRisposta.swift): gocce al clic, alle notifiche e allo sblocco
                RigaImpostazione(titolo: "L'acqua della scrivania", sottotitolo: testoAcqua,
                                 aiuto: "Una goccia al clic sul fondo libero, alle notifiche nuove e allo sblocco; l'acqua vibra piano mentre Vera risponde") {
                    Toggle(isOn: $stato.dati.impostazioni.acquaDellaScrivania) { EmptyView() }
                        .toggleStyle(.appleSenzaEtichetta)
                        .accessibilityLabel("L'acqua della scrivania")
                        .disabled(!animato)
                        .opacity(animato ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
                }
                .cascataImpostazioni(4)
                // «Riduci movimento» di Prisma: si somma a quello del sistema (`\.prismaCalmo`, Movimenti.calmo)
                RigaImpostazione(titolo: "Riduci movimento", sottotitolo: testoCalmo,
                                 aiuto: "Tutto compare già al suo posto con una dissolvenza breve: niente cascate, inclinazioni né numeri che si contano. L'acqua della scrivania si ferma") {
                    Toggle(isOn: calmoEffettivo) { EmptyView() }
                        .toggleStyle(.appleSenzaEtichetta)
                        .accessibilityLabel("Riduci movimento")
                        .accessibilityHint(calmoSistema ? Text("Acceso \(doveSistema)") : Text(""))
                        .disabled(calmoSistema)
                        .opacity(calmoSistema ? Tema.Misura.Shell.opacitaDisabilitato : 1)
                }
                .cascataImpostazioni(5)
                rigaDimensioneTesto
                    .cascataImpostazioni(6)
            }
            GruppoImpostazioni(titolo: "Finestra") {
                RigaImpostazione(titolo: "Schermo intero", sottotitolo: "Tutto lo schermo a Prisma.", ultima: true) {
                    ValoreRiga(testo: stato.schermoIntero ? "Attivo" : "Attiva") { stato.alternaSchermoIntero() }
                }
                .cascataImpostazioni(7)
            }
            GruppoImpostazioni(titolo: "Aiuto") {
                RigaImpostazione(titolo: "Guida per cominciare", sottotitolo: "Sulla scrivania, finché non è finita.") {
                    interruttore(Binding(get: { !stato.dati.impostazioni.guidaNascosta },
                                         set: { stato.dati.impostazioni.guidaNascosta = !$0 }))
                }
                .cascataImpostazioni(8)
                RigaImpostazione(titolo: "Come funziona Prisma", sottotitolo: "L'introduzione e le parole della finanza.",
                                 ultima: true) {
                    ValoreRiga(testo: "Apri") { stato.apriGuida(.introduzione(0)) }
                }
                .cascataImpostazioni(9)
            }
        }
    }

    /// «Dimensione del testo»: Normale / Grande / Molto grande (1 / 1,12 / 1,25). I caratteri del tema Apple
    /// cambiano subito (`\.prismaScalaTesto`), quelli di sempre riaprendo Prisma (`Tipo.fattore`, fissato all'avvio).
    /// Prospetti, report e PDF restano come sulla carta.
    private var rigaDimensioneTesto: some View {
        let daRiaprire = stato.dati.impostazioni.dimensioneTesto.fattore != Tipo.fattore
        return RigaImpostazione(titolo: "Dimensione del testo", sottotitolo: "Normale, grande, molto grande.",
                                aiuto: "Prospetti, report e PDF restano come sulla carta",
                                avvertenza: daRiaprire ? "Le schermate nuove cambiano subito, le altre riaprendo Prisma." : nil,
                                ultima: true) {
            HStack(spacing: Tema.Apple.Impostazioni.Riga.spazioControlliAffiancati) {
                if daRiaprire {
                    Button { stato.riapri() } label: { Label("Riapri ora", systemImage: "arrow.clockwise") }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                        .fixedSize()
                }
                segmenti(DimensioneTesto.allCases.map { ($0, $0.nome) }, $stato.dati.impostazioni.dimensioneTesto)
            }
        }
    }

    // MARK: Scorciatoie

    private var scorciatoie: some View {
        let app = Array(AppPrisma.delDock.prefix(9))
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni {
                RigaImpostazione(titolo: "Cerca ovunque") { TastiScorciatoia(tasti: ["⌘", "K"]) }
                RigaImpostazione(titolo: "Torna alla scrivania", sottotitolo: "Riduce tutte le finestre") { TastiScorciatoia(tasti: ["⌥", "0"]) }
                RigaImpostazione(titolo: "Modalità cliente") { TastiScorciatoia(tasti: ["⌥", "⌘", "M"]) }
                RigaImpostazione(titolo: "Parla con Vera", sottotitolo: "Di nuovo per mandare la frase", ultima: true) {
                    TastiScorciatoia(tasti: ["⌥", "⌘", "E"])
                }
            }
            GruppoImpostazioni(titolo: "Le app del dock") {
                ForEach(Array(app.enumerated()), id: \.element) { i, a in
                    RigaImpostazione(titolo: a.titolo, sottotitolo: a.sottotitolo, icona: IconaVetroImpostazioni(.app(a)),
                                     ultima: i == app.count - 1) {
                        TastiScorciatoia(tasti: ["⌥", "\(i + 1)"])
                    }
                }
            }
        }
    }

    // MARK: Strumenti

    /// Strumenti di prova, separati dalle preferenze: dati di prova, confronto dei modelli, prova dei promemoria
    /// e, chiusa, la voce di Vera (per ora Vera non parla).
    private var strumenti: some View {
        let c = Tema.Colore.Impostazioni.self
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            #if os(macOS)
            GruppoImpostazioni(titolo: "Dati di prova") {
                if stato.haDatiDiProva {
                    RigaImpostazione(titolo: "Togli i clienti di prova", sottotitolo: "Restano solo i tuoi clienti",
                                     icona: IconaVetroImpostazioni(simbolo: "person.crop.circle.badge.minus", colori: c.dati),
                                     aiuto: "Per lavorare solo con i tuoi clienti: restano i clienti che hai inserito tu. Prima viene salvato un backup.") {
                        ValoreRiga(testo: "Togli") { confermaTogliProva = true }
                    }
                }
                RigaImpostazione(titolo: "I 5 clienti di prova", sottotitolo: "Per provare i motori di calcolo",
                                 icona: IconaVetroImpostazioni(simbolo: "person.2.fill", colori: c.dati),
                                 aiuto: "Utile per provare i motori di calcolo. Prima viene salvato un backup.") {
                    ValoreRiga(testo: "Ripristina") { confermaDatiProva = true }
                }
                RigaImpostazione(titolo: "35 clienti di prova completi", sottotitolo: "Prisma piena, per Vera e le prove",
                                 icona: IconaVetroImpostazioni(simbolo: "person.3.fill", colori: c.dati),
                                 aiuto: "I 5 del template più 30 clienti inventati, con polizze Alleanza, investimenti, famiglia, agenda e note: per vedere Prisma piena e fare domande a Vera. Prima viene salvato un backup.",
                                 ultima: true) {
                    ValoreRiga(testo: "Carica") { confermaClientiCompleti = true }
                }
            }
            NotaImpostazioni("Prima di ogni cambio Prisma salva un backup.")
            GruppoImpostazioni(titolo: "Vera") {
                rigaConfrontaModelli
            }
            #endif
            GruppoImpostazioni(titolo: "Promemoria") {
                RigaImpostazione(titolo: "Prova un promemoria", sottotitolo: "Arriva subito, per vedere com'è",
                                 icona: IconaVetroImpostazioni(.simbolo("bell.fill", c.promemoria)),
                                 avvertenza: stato.dati.impostazioni.promemoria.attivi ? nil : "Prima accendi i promemoria",
                                 ultima: true) {
                    Button { stato.provaPromemoria() } label: { Label("Prova", systemImage: "bell") }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                        .disabled(stato.permessoPromemoria == .negati || !stato.dati.impostazioni.promemoria.attivi)
                }
            }
            GruppoImpostazioni(titolo: "Parlare con Vera") {
                rigaApri("Voce e ascolto", "Per ora Vera non parla", aperta: $mostraVoce, ultima: !mostraVoce)
                if mostraVoce {
                    righeVoce
                }
            }
        }
    }
}

/// L'avatar del consulente nel profilo («DV» grande, .me.big): lo stesso cerchio della barra, più grande.
private struct AvatarProfilo: View {
    let iniziali: String

    var body: some View {
        let lato = Tema.Misura.Impostazioni.avatar
        Text(iniziali)
            .font(Tema.Testo.avatar(lato))
            .foregroundColor(Tema.Colore.Shell.avatarTesto)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: lato, height: lato)
            .background {
                Circle()
                    .fill(RadialGradient(colors: [Tema.Colore.Shell.avatarAlto, Tema.Colore.Shell.avatarBasso],
                                         center: UnitPoint(x: 0.3, y: 0.25), startRadius: 0, endRadius: lato))
                    .ombraTema(Tema.Ombra.avatar)
            }
            .accessibilityHidden(true)
    }
}

extension StatoShell {
    /// Salva e riapre Prisma (per la dimensione del testo, che si fissa all'avvio).
    @MainActor
    func riapri() {
        salvaOra()
        #if os(macOS)
        let configurazione = NSWorkspace.OpenConfiguration()
        configurazione.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configurazione) { _, errore in
            DispatchQueue.main.async {
                if errore == nil {
                    NSApp.terminate(nil)
                } else {
                    self.mostraAvviso("Non sono riuscito a riaprire Prisma: chiudilo e riaprilo tu.")
                }
            }
        }
        #elseif os(iOS)
        // Su iPhone e iPad un'app non si riapre da sé: la nuova misura del testo vale alla prossima apertura
        mostraAvviso("Dati salvati: chiudi Prisma dal selettore delle app e riaprila per applicare la modifica.")
        #endif
    }
}
