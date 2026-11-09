#if os(macOS)
import AppKit
#endif
import SwiftUI

// Sala › Il Prisma del cliente («Luce» giro 15, Design/template-luce-specifica.md §2.1). A sinistra il telefono
// appoggiato (scala 0,92, a 44/−8) con la mini-app del cliente, chiara e fissa anche in scuro: la disegna `MiniPrisma`
// dallo stesso `ContenutoPrismaCliente` del file, così anteprima e file non divergono (le voci spente spariscono dal
// telefono). A destra la preparazione: «COSA C'È DENTRO» con gli interruttori (voce non disponibile = spenta, con il
// motivo e il collegamento), la password (tre parole e un numero, «Un'altra», scritta a mano almeno 12 caratteri; mai
// conservata), la data fino a cui vale (un invito), «Prepara il file» (PDF protetto sempre; l'HTML solo con
// l'interruttore sperimentale), «Manda con Messaggi» (testo senza password) e «Condividi…» (foglio di sistema, WhatsApp
// solo con il consenso). Sulla sala opaca della presentazione solo il telefono, al centro.
// Movimento: nome che si scrive una lettera alla volta (vista `Animatable`, niente Timer), onde della testata
// `repeatForever`, tile «file pronto» con la molla. Calmo: nome intero, onde ferme a 0,35, dissolvenza 0,15. Istantanee:
// nome intero, onde ferme a metà, anelli pieni, linea tracciata (stato di prova in `sala.provaUscite`).

struct PalcoPrismaCliente: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Sulla sala opaca della presentazione: solo il telefono, centrato.
    var inSala = false

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    /// Le voci scelte dal consulente (nil = quelle iniziali: di base più le aggiunte dalla Sala).
    @State private var vociScelte: Set<VoceFilePrisma>?
    /// La password proposta (mai salvata): nuova a ogni apertura, a ogni «Un'altra» e dopo il blocco.
    @State private var password: String
    @State private var mostrata = false
    @State private var aMano = false
    @State private var scadenza: Date
    @State private var etaScelta: Int?
    @State private var fase: FaseFilePrisma = .iniziale
    @State private var compito: Task<Void, Never>?

    private typealias P = Tema.Apple.PrismaCliente

    init(cliente: Cliente, inSala: Bool = false) {
        self.cliente = cliente
        self.inSala = inSala
        _password = State(initialValue: GeneratorePassword.nuova(cliente: cliente))
        let unAnno = Calendar(identifier: .gregorian).date(byAdding: .year, value: 1, to: Date()) ?? Date()
        _scadenza = State(initialValue: unAnno)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let attuale = stato.cliente(cliente.id) ?? cliente
        let motivi = stato.disponibilitaPrismaCliente(attuale)
        let aggiunte = Set(VoceFilePrisma.da(attuale.prismaCliente?.aggiunteDopoUltimoFile ?? []))
        let iniziali = VoceFilePrisma.accesePredefinite.union(aggiunte)
        let voci = (vociScelte ?? iniziali).subtracting(motivi.keys)
        let contenuto = stato.contenutoPrismaCliente(attuale, voci: voci, validoFinoAl: scadenza)
        Group {
            if inSala {
                telefono(contenuto, voci: voci, scala: P.scalaTelefonoSala)
                    .frame(width: Tema.Apple.Apparecchio.larghezza, height: Tema.Apple.Apparecchio.altezza)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    telefono(contenuto, voci: voci, scala: P.scalaTelefono)
                        .offset(x: P.posizioneTelefono.x, y: P.posizioneTelefono.y)
                        .frame(width: P.larghezzaZonaTelefono, alignment: .topLeading)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    ScrollView(.vertical, showsIndicators: false) {
                        HStack(alignment: .top, spacing: P.spazioColonne) {
                            colonnaLarga(attuale, motivi: motivi, voci: voci)
                                .frame(maxWidth: P.larghezzaTesto, alignment: .topLeading)
                            colonnaStretta(attuale, contenuto: contenuto, voci: voci)
                                .frame(width: P.larghezzaColonna, alignment: .topLeading)
                        }
                        .padding(P.margine)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .onChange(of: stato.bloccato) { _, bloccato in
            if bloccato { azzera() }
        }
        .onDisappear { azzera() }
    }

    // MARK: Il telefono

    private func telefono(_ contenuto: ContenutoPrismaCliente, voci: Set<VoceFilePrisma>, scala: CGFloat) -> some View {
        let eta = Binding<Int>(
            get: { etaScelta ?? contenuto.lineaVita?.etaProposta ?? 67 },
            set: { etaScelta = $0 })
        return TelefonoDisegnato {
            MiniPrisma(contenuto: contenuto, voci: voci, eta: eta)
        }
        .scaleEffect(scala, anchor: .topLeading)
        .accessibilityLabel(Text("Anteprima del Prisma di \(contenuto.nomeBattesimo)"))
    }

    // MARK: La colonna larga

    @ViewBuilder
    private func colonnaLarga(_ c: Cliente, motivi: [VoceFilePrisma: String], voci: Set<VoceFilePrisma>) -> some View {
        let nome = TestiPrismaCliente.nomeBattesimo(c)
        let html = stato.dati.impostazioni.sala.fileHtmlAcceso
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiPrismaCliente.titolo)
                .carattereApple(P.titolo)
                .foregroundColor(P.coloreTitolo)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiPrismaCliente.introduzione(nome, html: html))
                .carattereApple(P.introduzione)
                .foregroundColor(P.coloreIntroduzione)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, P.sottoTitolo)
            Text(TestiPrismaCliente.etichettaContenuto)
                .carattereApple(P.etichetta)
                .foregroundColor(P.coloreEtichetta)
                .padding(.top, P.sopraEtichetta)
                .padding(.bottom, P.sottoEtichetta)
            ForEach(righe(motivi), id: \.self) { v in
                riga(v, cliente: c, motivo: motivi[v], accesa: voci.contains(v))
            }
            note(c, nome: nome, voci: voci, html: html)
                .padding(.top, P.sopraNote)
        }
    }

    /// Le righe: tutte le voci, tranne il sinistro se il cliente non ne ha con gli aggiornamenti accesi.
    private func righe(_ motivi: [VoceFilePrisma: String]) -> [VoceFilePrisma] {
        VoceFilePrisma.allCases.filter { $0 != .sinistro || motivi[.sinistro] == nil }
    }

    private func riga(_ v: VoceFilePrisma, cliente c: Cliente, motivo: String?, accesa: Bool) -> some View {
        let nuova = c.prismaCliente?.aggiunteDopoUltimoFile.contains(v.rawValue) == true
        let legame = Binding<Bool>(
            get: { accesa },
            set: { on in
                var s = vociScelte ?? stato.vociInizialiPrismaCliente(c)
                if on { s.insert(v) } else { s.remove(v) }
                vociScelte = s
            })
        return VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: legame) {
                HStack(spacing: P.spazioNote) {
                    Text(v.titolo)
                        .carattereApple(P.riga)
                        .foregroundColor(motivo == nil ? P.coloreRiga : P.coloreRigaSpenta)
                    if nuova && motivo == nil {
                        Text(TestiPrismaCliente.nuovaDallUltimo)
                            .carattereApple(P.nuova)
                            .foregroundColor(P.coloreNuova)
                            .padding(P.paddingNuova)
                            .background(Capsule().fill(P.fondoNuova))
                    }
                }
            }
            .toggleStyle(.apple)
            .disabled(motivo != nil || istantanea)
            if let motivo {
                HStack(spacing: P.spazioNote) {
                    Text(motivo)
                        .carattereApple(P.motivo)
                        .foregroundColor(P.coloreMotivo)
                        .fixedSize(horizontal: false, vertical: true)
                    if let titolo = TestiPrismaCliente.collegamento(v), !inSala {
                        Button(titolo) { apriCollegamento(v, cliente: c) }
                            .buttonStyle(.plain)
                            .carattereApple(P.motivo)
                            .foregroundColor(Tema.Apple.Colore.accento)
                    }
                }
                .padding(.top, P.sopraMotivo)
            }
        }
        .padding(.vertical, P.paddingRiga)
        .overlay(alignment: .bottom) { Rectangle().fill(P.filo).frame(height: P.spessoreFilo) }
    }

    private func apriCollegamento(_ v: VoceFilePrisma, cliente c: Cliente) {
        switch v {
        case .obiettivi:
            stato.clienteAttivoId = c.id
            stato.schedaCliente = .obiettivi
            stato.apri(.clienti)
        case .lineaVita: stato.apriCliente(c.id)
        case .lettera: stato.apriEsperienza(.lettera, cliente: c.id)
        case .film: stato.apriEsperienza(.film, cliente: c.id)
        case .luce: stato.apriEsperienza(.prismaLuce, cliente: c.id)
        case .giornata: stato.apriEsperienza(.giornataPensione, cliente: c.id)
        case .sinistro: stato.apriPratiche(.sinistri)
        case .posizioni: break
        }
    }

    @ViewBuilder
    private func note(_ c: Cliente, nome: String, voci: Set<VoceFilePrisma>, html: Bool) -> some View {
        VStack(alignment: .leading, spacing: P.spazioNote) {
            if voci.isEmpty {
                nota(TestiPrismaCliente.accendiUnaVoce, avviso: true)
            }
            if let dato = c.prismaCliente?.ultimoFile {
                nota(TestiPrismaCliente.giaDato(dato), avviso: false)
            }
            if stato.primaUscita(clienteId: c.id) {
                nota(TestiUscite.avvisoPrimaVolta(nome: nome, cosa: "Il file"), avviso: false)
            }
            if stato.avvertenzaPrismaSegnaposto {
                HStack(spacing: P.spazioNote) {
                    nota(TestiPrismaCliente.avvertenzeNonScelte, avviso: true)
                    if !inSala {
                        Button("Impostazioni ›") {
                            stato.schedaImpostazioni = .sala
                            stato.apri(.impostazioni)
                        }
                        .buttonStyle(.appleSobrio)
                    }
                }
            }
            if !stato.dati.impostazioni.backup.cifrato {
                nota(TestiUscite.promemoriaBackup, avviso: true)
            }
            if html {
                nota("Con il file per il browser (sperimentale: da provare prima su iPhone e Android veri).", avviso: false)
            }
            if StatoShell.clientiDiProva.contains(c.id) && stato.haDatiDiProva {
                nota("Dati di prova.", avviso: false)
            }
        }
    }

    private func nota(_ testo: String, avviso: Bool) -> some View {
        Text(testo)
            .carattereApple(P.nota)
            .foregroundColor(avviso ? P.coloreAvviso : P.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: La colonna stretta

    @ViewBuilder
    private func colonnaStretta(_ c: Cliente, contenuto: ContenutoPrismaCliente, voci: Set<VoceFilePrisma>) -> some View {
        let pw = passwordMostrata
        let motivoPassword = GeneratorePassword.motivoNonValida(pw, cliente: c)
        let inCorso: Bool = { if case .preparazione = fase { return true } else { return false } }()
        VStack(alignment: .leading, spacing: P.spazioColonna) {
            tilePassword(c, password: pw, motivo: motivoPassword)
            tileScadenza
            Button { prepara(c, voci: voci, poi: nil) } label: {
                Text(TestiPrismaCliente.prepara).frame(maxWidth: .infinity)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(voci.isEmpty || motivoPassword != nil || inCorso || istantanea)
            .help(voci.isEmpty ? TestiPrismaCliente.accendiUnaVoce : "PDF protetto con la password; la copia leggibile va nei Documenti")
            Button { manda(c, voci: voci) } label: {
                Text(TestiPrismaCliente.manda).frame(maxWidth: .infinity)
            }
            .buttonStyle(.appleGrande)
            .disabled(voci.isEmpty || motivoPassword != nil || inCorso || istantanea)
            .help("Messaggi con il file allegato, senza la password nel testo: lo spedisci tu")
            PulsanteCondividi(titolo: TestiPrismaCliente.condividi, consensoWhatsApp: c.consensi.whatsapp == true,
                              prepara: { await filePerCondividere(c, voci: voci) },
                              esito: { e in dopoCondivisione(e, cliente: c, voci: voci) })
                .disabled(voci.isEmpty || motivoPassword != nil || inCorso || istantanea)
            zonaStato(contenuto)
            Text(TestiPrismaCliente.notaFondo)
                .carattereApple(P.nota)
                .foregroundColor(P.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, P.spazioColonna)
        }
    }

    /// La password da mostrare (nelle istantanee quella di prova dichiarata).
    private var passwordMostrata: String {
        if istantanea, let prova = stato.sala.provaUscite.passwordDiProva { return prova }
        return password
    }

    private var aperta: Bool { mostrata || (istantanea && stato.sala.provaUscite.prismaPasswordMostrata) }

    private func tilePassword(_ c: Cliente, password pw: String, motivo: String?) -> some View {
        VStack(alignment: .leading, spacing: P.spazioTile) {
            Text(TestiPrismaCliente.etichettaPassword)
                .carattereApple(P.titoloTile)
                .foregroundColor(P.coloreTitoloTile)
            if aMano {
                TextField("Almeno \(GeneratorePassword.lunghezzaMinimaAMano) caratteri", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .carattereApple(P.campoPassword)
                    .autocorrectionDisabled()
            } else {
                HStack {
                    Text(aperta ? pw : P.puntini)
                        .carattereApple(P.password)
                        .foregroundColor(P.colorePassword)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .textSelection(.enabled)
                    Spacer(minLength: P.spazioNote)
                    Button(aperta ? "Nascondi" : "Mostra") { mostrata.toggle() }
                        .buttonStyle(.apple)
                }
            }
            HStack(spacing: P.spazioNote) {
                Button(TestiPrismaCliente.unAltra) {
                    password = GeneratorePassword.nuova(cliente: c)
                    aMano = false
                    rinnova()
                }
                .buttonStyle(.appleSobrio)
                Button(aMano ? "Fatto" : "Scrivila tu") {
                    if !aMano { password = "" }
                    aMano.toggle()
                    rinnova()
                }
                .buttonStyle(.appleSobrio)
            }
            .disabled(istantanea)
            if let motivo {
                Text(motivo)
                    .carattereApple(P.motivo)
                    .foregroundColor(P.coloreErrore)
            } else {
                Text("Dilla a voce: Prisma non la conserva.")
                    .carattereApple(P.motivo)
                    .foregroundColor(P.coloreMotivo)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(P.paddingTile)
        .superficieApple(P.tile, raggio: P.raggioTile)
    }

    private var tileScadenza: some View {
        let domani = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return VStack(alignment: .leading, spacing: P.spazioTile) {
            Text(TestiPrismaCliente.etichettaScadenza)
                .carattereApple(P.titoloTile)
                .foregroundColor(P.coloreTitoloTile)
            HStack {
                Text(Formati.dataEstesa.string(from: scadenza))
                    .carattereApple(P.scadenza)
                    .foregroundColor(P.coloreScadenza)
                Spacer(minLength: P.spazioNote)
                DatePicker("", selection: $scadenza, in: domani..., displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .disabled(istantanea)
            }
            Text(TestiPrismaCliente.fraseScadenza)
                .carattereApple(P.motivo)
                .foregroundColor(P.coloreMotivo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(P.paddingTile)
        .superficieApple(P.tile, raggio: P.raggioTile)
        .onChange(of: scadenza) { _, _ in rinnova() }
    }

    // MARK: La zona di stato

    @ViewBuilder
    private func zonaStato(_ contenuto: ContenutoPrismaCliente) -> some View {
        let vista = faseMostrata(contenuto)
        switch vista {
        case .iniziale:
            EmptyView()
        case .preparazione(let frazione):
            VStack(alignment: .leading, spacing: P.spazioTile) {
                Text(TestiPrismaCliente.preparo)
                    .carattereApple(P.titoloTile)
                    .foregroundColor(P.coloreTitoloTile)
                BarraPiena(frazione: frazione, colore: P.barra, altezza: P.altezzaBarra, raggio: P.raggioBarra)
                    .animation(Tema.Apple.Moto.Curva.backup.animazione(Tema.Apple.Moto.PrismaCliente.barra), value: frazione)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(P.paddingTile)
            .superficieApple(P.tile, raggio: P.raggioTile)
        case .pronto(let pdf, let html, let dimensione, _):
            TileFilePronto(nomi: [pdf.lastPathComponent] + (html.map { [$0.lastPathComponent] } ?? []), dimensione: dimensione,
                           apri: { mostraNelFinder(pdf) })
        case .errore(let messaggio):
            Text(messaggio)
                .carattereApple(P.motivo)
                .foregroundColor(P.coloreErrore)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Nelle istantanee la tile «file pronto» di prova (dimensione dichiarata dalla scena).
    private func faseMostrata(_ contenuto: ContenutoPrismaCliente) -> FaseFilePrisma {
        if istantanea && stato.sala.provaUscite.prismaFilePronto {
            let url = CartellaUscite.cartella.appendingPathComponent(FilePrismaCliente.nomeFile(contenuto, estensione: "pdf"))
            return .pronto(pdf: url, html: nil, dimensione: TileFilePronto.dimensioneDiProva, documentoId: nil)
        }
        return fase
    }

    // MARK: Le azioni

    /// Cambiare password o scadenza rende vecchio il file pronto: va preparato di nuovo.
    private func rinnova() {
        if case .pronto(let pdf, let html, _, _) = fase {
            CartellaUscite.togli(pdf)
            if let html { CartellaUscite.togli(html) }
            fase = .iniziale
        } else if case .errore = fase {
            fase = .iniziale
        }
    }

    private func prepara(_ c: Cliente, voci: Set<VoceFilePrisma>, poi: (@MainActor (URL, URL?, String?) -> Void)?) {
        guard compito == nil else { return }
        let pw = password
        let fino = scadenza
        fase = .preparazione(0)
        compito = Task { @MainActor in
            let esito = await stato.preparaPrismaCliente(c, voci: voci, password: pw, validoFinoAl: fino) { frazione in
                fase = .preparazione(frazione)
            }
            compito = nil
            switch esito {
            case .pronto(let pdf, let html, let dimensione, let documentoId):
                withAnimation(calmo ? Tema.Moto.dissolvenzaCalma
                              : Tema.Apple.Moto.Curva.molla.animazione(Tema.Apple.Moto.PrismaCliente.FilePronto.durata)) {
                    fase = .pronto(pdf: pdf, html: html, dimensione: dimensione, documentoId: documentoId)
                }
                poi?(pdf, html, documentoId)
            case .nonRiuscito(let motivo):
                fase = .errore(motivo)
            }
        }
    }

    private func manda(_ c: Cliente, voci: Set<VoceFilePrisma>) {
        let invia: @MainActor (URL, URL?, String?) -> Void = { pdf, html, documentoId in
            let esito = stato.mandaPrismaConMessaggi(c, file: pdf)
            if esito.aperto {
                stato.registraUscitaPrismaCliente(c, voci: VoceFilePrisma.allCases.filter { voci.contains($0) }, via: "Messaggi",
                                                  html: html != nil, documentoId: documentoId)
            }
            stato.mostraAvviso(esito.messaggio)
        }
        if case .pronto(let pdf, let html, _, let documentoId) = fase, FileManager.default.fileExists(atPath: pdf.path) {
            invia(pdf, html, documentoId)
        } else {
            prepara(c, voci: voci, poi: invia)
        }
    }

    /// I file per il foglio di condivisione: quelli pronti, o li prepara adesso.
    private func filePerCondividere(_ c: Cliente, voci: Set<VoceFilePrisma>) async -> [URL]? {
        if case .pronto(let pdf, let html, _, _) = fase, FileManager.default.fileExists(atPath: pdf.path) {
            return [pdf] + (html.map { [$0] } ?? [])
        }
        guard compito == nil else { return nil }
        fase = .preparazione(0)
        let esito = await stato.preparaPrismaCliente(c, voci: voci, password: password, validoFinoAl: scadenza) { frazione in
            fase = .preparazione(frazione)
        }
        switch esito {
        case .pronto(let pdf, let html, let dimensione, let documentoId):
            fase = .pronto(pdf: pdf, html: html, dimensione: dimensione, documentoId: documentoId)
            return [pdf] + (html.map { [$0] } ?? [])
        case .nonRiuscito(let motivo):
            fase = .errore(motivo)
            return nil
        }
    }

    private func dopoCondivisione(_ e: EsitoCondivisione, cliente c: Cliente, voci: Set<VoceFilePrisma>) {
        guard case .pronto(let pdf, let html, _, let documentoId) = fase else { return }
        switch e {
        case .condiviso(let via):
            stato.registraUscitaPrismaCliente(c, voci: VoceFilePrisma.allCases.filter { voci.contains($0) }, via: via,
                                              html: html != nil, documentoId: documentoId)
            stato.mostraAvviso("Il file è uscito dal foglio di condivisione: lo hai mandato tu")
        case .annullato:
            break
        case .nonRiuscito(let motivo):
            stato.mostraAvviso(motivo)
        }
        // Il foglio toglie la copia temporanea dopo l'esito (sul Mac): allora il file va preparato di nuovo
        if !FileManager.default.fileExists(atPath: pdf.path) { fase = .iniziale }
    }

    private func mostraNelFinder(_ url: URL) {
        #if os(macOS)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
    }

    /// Al blocco e alla chiusura del palco: password nuova e nascosta, nessun file pronto (le copie temporanee si tolgono).
    private func azzera() {
        compito?.cancel()
        compito = nil
        rinnova()
        if case .preparazione = fase { fase = .iniziale }
        mostrata = false
        aMano = false
        password = GeneratorePassword.nuova(cliente: cliente)
    }
}

/// Le fasi della preparazione del file nel palco.
enum FaseFilePrisma: Equatable {
    case iniziale
    case preparazione(Double)
    case pronto(pdf: URL, html: URL?, dimensione: Int64, documentoId: String?)
    case errore(String)
}

/// «✓ Il-Prisma-di-Giulia.pdf · 1,4 MB · protetto con la password»: bordo verde, entra con la molla; un clic lo mostra
/// nel Finder.
struct TileFilePronto: View {
    let nomi: [String]
    let dimensione: Int64
    let apri: () -> Void

    /// Solo istantanee: la dimensione mostrata nella tile di prova (dato di prova dichiarato, non misurato).
    static let dimensioneDiProva: Int64 = 1_352_704

    @Environment(\.prismaStatoFinale) private var statoFinale
    @Environment(\.prismaCalmo) private var calmo
    @State private var comparsa = false

    private typealias P = Tema.Apple.PrismaCliente
    private typealias M = Tema.Apple.Moto.PrismaCliente.FilePronto

    var body: some View {
        let _ = ContaCorpi.segna()
        let visibile = statoFinale || comparsa
        Button(action: apri) {
            VStack(alignment: .leading, spacing: P.spazioTile) {
                Text(TestiPrismaCliente.pronto(nomeFile: nomi.joined(separator: " + "), byte: dimensione))
                    .carattereApple(P.testoPronto)
                    .foregroundColor(P.coloreTestoPronto)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Un clic lo mostra nel Finder. La password non è nel file né nel messaggio.")
                    .carattereApple(P.motivo)
                    .foregroundColor(P.coloreMotivo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(P.paddingTile)
            .superficieApple(P.tile, raggio: P.raggioTile)
            .overlay(RoundedRectangle(cornerRadius: P.raggioTile, style: .continuous)
                .strokeBorder(P.bordoPronto, lineWidth: P.spessoreBordoPronto))
        }
        .buttonStyle(.plain)
        .scaleEffect(visibile || calmo ? 1 : M.scala)
        .opacity(visibile ? 1 : 0)
        .onAppear {
            guard !statoFinale else { return }
            withAnimation(Tema.Apple.Moto.Curva.molla.animazione(M.durata)) { comparsa = true }
        }
    }
}

// MARK: - La mini-app del cliente

/// La mini-app dentro il telefono: gli stessi blocchi del file, chiari e fissi (`Tema.Apple.MiniCliente`).
struct MiniPrisma: View {
    let contenuto: ContenutoPrismaCliente
    let voci: Set<VoceFilePrisma>
    @Binding var eta: Int

    @Environment(\.prismaCalmo) private var calmo

    private typealias M = Tema.Apple.PrismaCliente.Mini
    private typealias C = Tema.Apple.MiniCliente

    var body: some View {
        let _ = ContaCorpi.segna()
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                TestataMini(nome: contenuto.nomeBattesimo)
                if contenuto.diProva {
                    Text(TestiPrismaCliente.datiDiProva)
                        .carattereApple(M.datiDiProva)
                        .foregroundColor(C.testo2)
                        .padding(.top, M.spazioCard)
                }
                VStack(spacing: M.spazioCards) {
                    if let o = contenuto.obiettivi, !o.isEmpty { cardObiettivi(o).transition(transizione) }
                    if let l = contenuto.lineaVita { CardPensioneMini(linea: l, eta: $eta).transition(transizione) }
                    if contenuto.lettera != nil { cardLettera.transition(transizione) }
                    if contenuto.conFilm { cardFilm.transition(transizione) }
                    if voci.contains(.luce) { cardImmagine("Il prisma di luce", png: contenuto.luce).transition(transizione) }
                    if voci.contains(.giornata) { cardImmagine("Una giornata della pensione", png: contenuto.giornata).transition(transizione) }
                    if let s = contenuto.sinistri { ForEach(Array(s.enumerated()), id: \.offset) { _, x in cardSinistro(x) } }
                    if let p = contenuto.posizioni, !p.isEmpty { cardPosizioni(p).transition(transizione) }
                }
                .padding(M.margineCards)
                .animation(calmo ? Tema.Moto.dissolvenzaCalma
                           : Tema.Apple.Moto.Curva.uscita.animazione(Tema.Apple.Moto.PrismaCliente.card), value: voci)
                piede
            }
        }
        .background(C.fondo)
        .environment(\.colorScheme, .light)
    }

    private var transizione: AnyTransition { .opacity.combined(with: .scale(scale: 0.96, anchor: .top)) }

    private func card<Contenuto: View>(scura: Bool = false, @ViewBuilder _ contenuto: () -> Contenuto) -> some View {
        VStack(alignment: .leading, spacing: M.spazioCard) { contenuto() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(M.paddingCard)
            .background(RoundedRectangle(cornerRadius: M.raggioCard, style: .continuous).fill(scura ? C.cardFilm : C.card))
            .shadow(color: M.ombraCard, radius: M.raggioOmbraCard, x: 0, y: M.yOmbraCard)
    }

    private func occhiello(_ t: String, scuro: Bool = false) -> some View {
        Text(t).carattereApple(M.occhiello).foregroundColor(scuro ? M.testoFilm : C.testo2)
    }

    private func cardObiettivi(_ o: [ObiettivoMini]) -> some View {
        card {
            occhiello("I tuoi obiettivi")
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(o.enumerated()), id: \.offset) { i, x in
                    VStack(spacing: M.spazioAnello) {
                        Anello(frazione: x.quota, colore: Color(hex: x.coloreHex), misura: M.anello, spessore: M.spessoreAnello,
                               ritardo: Tema.Apple.Moto.Anello.ritardoFinestra + Double(i) * 0.12) { EmptyView() }
                        Text(x.titolo)
                            .carattereApple(M.etichettaAnello)
                            .foregroundColor(C.testo2)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(width: M.larghezzaEtichettaAnello)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            if let primo = o.first {
                Text("\(TestiPrismaCliente.fraseObiettivo(primo.quota)) di «\(primo.titolo)»")
                    .carattereApple(M.fraseObiettivo)
                    .foregroundColor(C.testo)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var cardLettera: some View {
        card {
            HStack(spacing: M.spazioCard) {
                RoundedRectangle(cornerRadius: M.raggioQuadrato, style: .continuous)
                    .fill(C.lettera)
                    .frame(width: M.quadrato, height: M.quadrato)
                    .overlay(Image(systemName: "envelope.fill").font(M.glifo.font).foregroundColor(C.card))
                VStack(alignment: .leading, spacing: M.spazioStretto) {
                    Text("Una lettera da te").carattereApple(M.titoloCard).foregroundColor(C.testo)
                    Text(contenuto.lineaVita.map { "scritta a \($0.etaProposta) anni" } ?? "dal tuo futuro")
                        .carattereApple(M.sottoCard).foregroundColor(C.testo2)
                }
                Spacer(minLength: 0)
                Text("›").carattereApple(M.freccia).foregroundColor(C.freccia)
            }
        }
    }

    private var cardFilm: some View {
        card(scura: true) {
            HStack(spacing: M.spazioCard) {
                Circle().fill(M.cerchioFilm).frame(width: M.quadrato, height: M.quadrato)
                    .overlay(Text("▶︎").carattereApple(M.glifo).foregroundColor(M.testoFilm))
                VStack(alignment: .leading, spacing: M.spazioStretto) {
                    Text("Il film del tuo piano").carattereApple(M.titoloCard).foregroundColor(M.testoFilm)
                    Text("venti secondi").carattereApple(M.sottoCard).foregroundColor(M.testoFilm.opacity(M.opacitaSottoFilm))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func cardImmagine(_ titolo: String, png: Data?) -> some View {
        card {
            occhiello(titolo)
            Group {
                if let immagine = PaginePrismaCliente.immagine(png) {
                    immagine.resizable().aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: M.raggioImmagine, style: .continuous)
                        .fill(C.cardFilm)
                        .overlay(Text("un'immagine ferma, nel file").carattereApple(M.sottoCard)
                            .foregroundColor(M.testoFilm.opacity(M.opacitaSottoFilm)))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: M.altezzaImmagine)
            .clipShape(RoundedRectangle(cornerRadius: M.raggioImmagine, style: .continuous))
        }
    }

    private func cardSinistro(_ s: SinistroMini) -> some View {
        card {
            occhiello("Il tuo sinistro")
            Text(s.titolo).carattereApple(M.titoloCard).foregroundColor(C.testo)
            VStack(alignment: .leading, spacing: M.spazioTitolo) {
                ForEach(Array(s.fasi.enumerated()), id: \.offset) { _, f in
                    HStack(spacing: M.spazioFase) {
                        Circle().fill(coloreFase(f.stato)).frame(width: M.fase, height: M.fase)
                        Text(f.nome).carattereApple(M.etichettaFase)
                            .foregroundColor(f.stato == .futura ? C.futuro : C.testo)
                    }
                }
            }
            if let u = s.ultimoFatto { Text(u).carattereApple(M.sottoCard).foregroundColor(C.testo2) }
            Text("Aggiornato da \(s.consulente.components(separatedBy: " · ").first ?? s.consulente) · \(Formati.giornoMeseBreve.string(from: s.aggiornatoIl))")
                .carattereApple(M.sottoCard).foregroundColor(C.testo2)
        }
    }

    private func coloreFase(_ s: SinistroMini.StatoFase) -> Color {
        switch s {
        case .fatta: return C.fatta
        case .adesso: return C.adesso
        case .futura: return C.cerchioVuoto
        case .respinta: return C.nonBasta
        }
    }

    private func cardPosizioni(_ p: [PosizioneMini]) -> some View {
        card {
            occhiello("Le tue posizioni")
            ForEach(Array(p.enumerated()), id: \.offset) { _, x in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: M.spazioMinimo) {
                        Text(x.nome).carattereApple(M.titoloCard).foregroundColor(C.testo).lineLimit(2)
                        Text(x.canale).carattereApple(M.canale).foregroundColor(Color(hex: x.coloreCanaleHex))
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: M.spazioMinimo) {
                        Text(Formati.euro(x.valore)).carattereApple(M.valore).foregroundColor(C.testo)
                        Text(Formati.giornoMeseBreve.string(from: x.data)).carattereApple(M.sottoCard).foregroundColor(C.testo2)
                    }
                }
            }
        }
    }

    private var piede: some View {
        VStack(spacing: M.spazioStretto) {
            Text(contenuto.consulente)
            ForEach(Array(contenuto.avvertenze.enumerated()), id: \.offset) { _, a in Text(a) }
            Text("Valido fino al \(Formati.dataEstesa.string(from: contenuto.validoFinoAl))")
        }
        .carattereApple(M.piede)
        .foregroundColor(C.piede)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(M.marginePiede)
    }
}

/// La testata della mini-app: gradiente, tre onde, logo fisso, «IL PRISMA DI» e il nome che si scrive.
private struct TestataMini: View {
    let nome: String

    private typealias M = Tema.Apple.PrismaCliente.Mini
    private typealias C = Tema.Apple.MiniCliente

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [C.testataDa, C.testataA], startPoint: M.inizioTestata, endPoint: M.fineTestata)
            ForEach(Array(M.centriOnde.enumerated()), id: \.offset) { i, centro in
                OndaMini(indice: i)
                    .position(x: centro.x, y: centro.y)
            }
            LogoPrisma(colore: C.logo)
                .frame(width: M.logo * GeometriaLogo.proporzione, height: M.logo)
                .offset(x: M.posizioneLogo.x, y: M.posizioneLogo.y)
            VStack(alignment: .leading, spacing: M.spazioStretto) {
                Text("Il Prisma di")
                    .carattereApple(M.sopraNome)
                    .foregroundColor(C.testo.opacity(M.opacitaSopraNome))
                NomeCheSiScrive(nome: nome)
                    .carattereApple(M.nome)
                    .foregroundColor(C.testo)
            }
            .padding(.leading, M.margineNome)
            .padding(.bottom, M.fondoNome)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: M.altezzaTestata)
        .clipped()
    }
}

/// Un'onda della testata: si allarga e svanisce, sfasata di 1,1 s dalle altre. Ferma con il calmo e nelle istantanee.
private struct OndaMini: View {
    let indice: Int

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var giro = false

    private typealias M = Tema.Apple.PrismaCliente.Mini
    private typealias O = Tema.Apple.Moto.PrismaCliente.Onda

    var body: some View {
        let ferma = calmo || istantanea
        let scala: CGFloat = istantanea ? O.scalaFerma : (calmo ? 1 : (giro ? O.scalaA : O.scalaDa))
        let opacita: Double = calmo ? O.opacitaFerma : (istantanea ? O.opacitaDa / 2 : (giro ? 0 : O.opacitaDa))
        Circle()
            .strokeBorder(M.coloreOnda, lineWidth: M.bordoOnda)
            .frame(width: M.onda, height: M.onda)
            .scaleEffect(scala)
            .opacity(opacita)
            .onAppear {
                guard !ferma else { return }
                withAnimation(.easeOut(duration: O.durata).repeatForever(autoreverses: false).delay(Double(indice) * O.sfasamento)) {
                    giro = true
                }
            }
            .accessibilityHidden(true)
    }
}

/// Il nome che si scrive una lettera ogni 0,11 s: una vista `Animatable` con il numero di lettere come valore animato
/// (lineare, durata = lettere × 0,11). Niente Timer. Calmo e istantanee: il nome intero.
struct NomeCheSiScrive: View {
    let nome: String

    @Environment(\.prismaStatoFinale) private var statoFinale
    @State private var lettere: Double = 0

    var body: some View {
        LettereDelNome(nome: nome, lettere: statoFinale ? Double(nome.count) : lettere)
            .onAppear {
                guard !statoFinale else { return }
                lettere = 0
                withAnimation(.linear(duration: Double(nome.count) * Tema.Apple.Moto.PrismaCliente.lettera)) {
                    lettere = Double(nome.count)
                }
            }
            .accessibilityLabel(Text(nome))
    }
}

/// Le prime `lettere` lettere del nome (le altre trasparenti: la riga non cambia larghezza mentre si scrive).
private struct LettereDelNome: View, Animatable {
    let nome: String
    var lettere: Double

    var animatableData: Double {
        get { lettere }
        set { lettere = newValue }
    }

    var body: some View {
        let n = max(0, min(nome.count, Int(lettere.rounded(.down))))
        let scritte = String(nome.prefix(n))
        let resto = String(nome.dropFirst(n))
        return (Text(scritte) + Text(resto).foregroundColor(.clear))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// «E SE VADO IN PENSIONE A…»: l'età, il cursore 58-70, il grafico e la frase verde o rossa.
private struct CardPensioneMini: View {
    let linea: LineaVitaMini
    @Binding var eta: Int

    private typealias M = Tema.Apple.PrismaCliente.Mini
    private typealias C = Tema.Apple.MiniCliente

    var body: some View {
        let minimo = linea.serie.first?.etaPensione ?? CompositorePrismaCliente.etaCursore.lowerBound
        let massimo = linea.serie.last?.etaPensione ?? CompositorePrismaCliente.etaCursore.upperBound
        let scelta = min(max(eta, minimo), massimo)
        let serie = linea.serie(scelta)
        let valore = Binding<Double>(get: { Double(scelta) }, set: { eta = Int($0.rounded()) })
        VStack(alignment: .leading, spacing: M.spazioCard) {
            Text("E se vado in pensione a…").carattereApple(M.occhiello).foregroundColor(C.testo2)
            Text("\(scelta) anni").carattereApple(M.eta).foregroundColor(C.testo)
            if massimo > minimo {
                Slider(value: valore, in: Double(minimo)...Double(massimo), step: 1)
                    .tint(C.linea)
                    .controlSize(.small)
                    .accessibilityLabel(Text("Età della pensione"))
            }
            GraficoPensioneMini(linea: linea, serie: serie, eta: scelta)
                .frame(height: M.grafico.height)
            Text(TestiPrismaCliente.frasePensione(esaurimento: serie?.etaEsaurimento, etaFine: linea.etaFine))
                .carattereApple(M.frase)
                .foregroundColor(serie?.etaEsaurimento == nil ? C.basta : C.nonBasta)
            if linea.indicativa {
                Text(TestiPrismaCliente.lineaIndicativa)
                    .carattereApple(M.fraseIndicativa)
                    .foregroundColor(C.testo2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(M.paddingCard)
        .background(RoundedRectangle(cornerRadius: M.raggioCard, style: .continuous).fill(C.card))
        .shadow(color: M.ombraCard, radius: M.raggioOmbraCard, x: 0, y: M.yOmbraCard)
    }
}

/// Il grafico 232×60 del patrimonio da oggi a 90 anni: area viola a 0,15, linea 2,2, filo tratteggiato all'età. Si
/// ridisegna subito a ogni passo del cursore (nessuna animazione durante il trascinamento).
private struct GraficoPensioneMini: View {
    let linea: LineaVitaMini
    let serie: SerieLineaVita?
    let eta: Int

    private typealias M = Tema.Apple.PrismaCliente.Mini
    private typealias C = Tema.Apple.MiniCliente

    var body: some View {
        let massimo = max(1, linea.serie.flatMap(\.valori).max() ?? 1)
        let valori = serie?.valori ?? []
        let quota = valori.count > 1 ? CGFloat(eta - linea.etaOggi) / CGFloat(valori.count - 1) : 0
        ZStack {
            FormaPensioneMini(valori: valori, massimo: massimo, chiusa: true)
                .fill(C.linea.opacity(M.opacitaArea))
            FormaPensioneMini(valori: valori, massimo: massimo, chiusa: false)
                .stroke(C.linea, style: StrokeStyle(lineWidth: M.spessoreLinea, lineCap: .round, lineJoin: .round))
            FiloEtaMini(quota: min(max(quota, 0), 1))
                .stroke(C.linea, style: StrokeStyle(lineWidth: M.spessoreFiloEta, dash: M.tratteggio))
        }
        .accessibilityHidden(true)
    }
}

private struct FormaPensioneMini: Shape {
    let valori: [Double]
    let massimo: Double
    let chiusa: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard valori.count > 1, massimo > 0 else { return p }
        let n = CGFloat(valori.count - 1)
        func punto(_ i: Int) -> CGPoint {
            let v = max(0, valori[i]) / massimo
            return CGPoint(x: rect.minX + CGFloat(i) / n * rect.width, y: rect.maxY - CGFloat(v) * (rect.height - 2))
        }
        if chiusa {
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            for i in valori.indices { p.addLine(to: punto(i)) }
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
        } else {
            p.move(to: punto(0))
            for i in valori.indices.dropFirst() { p.addLine(to: punto(i)) }
        }
        return p
    }
}

private struct FiloEtaMini: Shape {
    let quota: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x = rect.minX + quota * rect.width
        p.move(to: CGPoint(x: x, y: rect.minY))
        p.addLine(to: CGPoint(x: x, y: rect.maxY))
        return p
    }
}
