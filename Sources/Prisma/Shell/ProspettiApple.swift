#if os(macOS)
import AppKit
#endif
import SwiftUI

// Prospetti e report nel tema Apple, sul Mac e sull'iPad (Design/template-apple-specifica.md §4.5.1, riferimenti PIE p01-p08):
//
//   ┌─ ◉ Giulia Rossi ⌄ ───────────┐  Il check-up di Giulia Rossi        [Chiedi a Ruby] [▶︎ Presenta all'incontro]
//   │ PER L'INCONTRO               │  Report · Giulia Rossi · A4 …      [Stampa…] [Archivia nei Documenti] [Salva PDF…]
//   │ ▌Check-up         (scelto)   │  ┌──────────────────────────────────────────────┐
//   │   Prospetto | Report …       │  │              ┌────────────┐                   │
//   │  Valutazione                 │  │              │   carta    │  la pagina cambia │
//   │  …                           │  │              │  bianca    │  scorrendo        │
//   │ PROSPETTI DI DETTAGLIO · …   │  │              └────────────┘                   │
//   │ ┌ FASCICOLO DELL'INCONTRO ┐  │  │                ‹  2 di 5  ›                   │
//   │ └ [Componi il fascicolo]  ┘  │  └──────────────────────────────────────────────┘
//   └──────────────────────────────┘
//
// - La barra laterale (290) tiene il cliente scelto (avatar 30, si cambia dalla tendina), «Per l'incontro» con le
//   voci di sempre (titolo e sottotitolo come `.rub`) e la card «Fascicolo dell'incontro». Sotto la voce scelta si
//   aprono le scelte del documento di oggi (prospetto o report, posizioni, valutazioni, commento): restano tutte.
// - L'anteprima è la carta vera (le stesse pagine del PDF, sempre bianche) su fondo `chip` con raggio 20, una pagina
//   alla volta, grande quanto lo spazio permette. Cambia con `.cambioPagina` (§2.23): scegliendo un'altra voce (giù
//   = la pagina vecchia sale), con le frecce sotto la carta o scorrendo con la rotella o il trackpad sull'anteprima.
// - Le azioni di oggi restano tutte: Chiedi a Ruby, Presenta all'incontro (dalla pagina mostrata), Stampa, Archivia
//   nei Documenti, Salva PDF (il blu, l'azione principale).
// - «Riduci movimento»: dissolvenze di 0,15 s; istantanee: tutto fermo nello stato finale.
// - Sull'iPad la stessa app: niente passaggio del puntatore, la carta si sfoglia col dito (`SfogliaAnteprimaApple`).
// Valori in DesignSystem/Apple/Tema.Apple+Prospetti.swift. L'iPhone non ha Prospetti.

// MARK: - Stili delle scelte del documento (comuni)

/// I caratteri e i colori delle scelte del documento: quelli del tema Apple (le scelte stanno nella barra laterale),
/// sul Mac e sull'iPad.
enum StileScelteProspetto {
    private typealias S = Tema.Apple.Prospetti.Scelte
    static var nota: Font { S.nota.font }
    static var coloreNota: Color { S.coloreNota }
    static var testo: Font { S.testo.font }
    static var coloreTesto: Color { S.coloreTesto }
    static var etichetta: Font { S.etichetta.font }
    static var coloreEtichetta: Color { S.coloreEtichetta }
    static var forte: Font { S.forte.font }
    static var piccolo: Font { S.piccolo.font }
    static var punto: Color { S.punto }
    static var errore: Color { S.errore }
    static var titolo: Font { Tema.Apple.Prospetti.Anteprima.vuotoTitolo.font }
    static var coloreTitolo: Color { Tema.Apple.Colore.inchiostro }
    static var collegamento: Color { Tema.Apple.Colore.accento }
}

/// I pulsanti delle scelte del documento: i pulsanti a capsula del tema Apple (l'accento è il testo blu: il blu pieno
/// resta a «Salva PDF…»), sul Mac e sull'iPad. `taglia` resta per chi la passa.
struct StileAzioneSceltaProspetto: ButtonStyle {
    var taglia: TagliaPulsante = .normale
    var accento = false

    init(taglia: TagliaPulsante = .normale, accento: Bool = false) {
        self.taglia = taglia
        self.accento = accento
    }

    func makeBody(configuration: Configuration) -> some View {
        StilePulsanteApple(accento ? .sobria : .secondaria).makeBody(configuration: configuration)
    }
}

extension View {
    /// Una riga scelta negli elenchi delle scelte (obiettivi, valutazioni, posizioni): la selezione del tema Apple
    /// (`rgba(0,122,255,.13)`, raggio 14), sul Mac e sull'iPad.
    func voceSceltaProspetto(attiva: Bool) -> some View {
        let forma = RoundedRectangle(cornerRadius: Tema.Apple.Prospetti.Laterale.raggioVoce, style: .continuous)
        return self
            .background { forma.fill(attiva ? Tema.Apple.Prospetti.Laterale.fondoScelta : Color.clear) }
            .contentShape(forma)
    }
}

// MARK: - La pagina dell'anteprima

/// La pagina mostrata nell'anteprima: vale per la scelta e il cliente con cui è stata girata (con un'altra scelta
/// si riparte dalla prima pagina).
struct PaginaAnteprimaProspetto: Equatable {
    var scelta: SceltaProspetto?
    var cliente = ""
    var indice = 0
}

/// L'identità della pagina nell'anteprima: cambia con la scelta, il cliente e il numero di pagina (e così parte
/// `.cambioPagina`), non con una nuova impaginazione dello stesso documento.
struct IdAnteprimaProspetto: Hashable {
    let scelta: SceltaProspetto
    let cliente: String
    let indice: Int
}

// MARK: - L'app sul Mac e sull'iPad

extension AppProspetti {
    /// «Per l'incontro»: le voci di prospetto e report, nell'ordine di sempre.
    var tipiPerIncontro: [TipoProspetto] {
        [.annoInsieme, .checkUp, .valutazione, .resoconto, .patrimonio, .resistenza, .costi, .successione, .sostituzione,
         .previdenza, .protezione, .obiettivo, .liquidita]
    }

    /// I prospetti di dettaglio, per te.
    static let tipiDiDettaglio: [TipoProspetto] = [.riesame, .posizione, .confronto]

    /// L'ordine di tutte le voci, dall'alto in basso: dice da che parte gira la pagina.
    private var ordineVoci: [TipoProspetto] {
        tipiPerIncontro + Self.tipiDiDettaglio + [.portafoglio, .fascicolo]
    }

    var corpoProspettiApple: some View {
        // Impaginato una volta sola finché non cambia qualcosa che conta (DerivatiDati), non a ogni disegno
        let documento = stato.documentoProspettoInCache(scelta)
        // Il numero di questa impaginazione: preso subito, è quello del documento qui sopra
        let generazione = stato.generazioneDocumento
        let d = Tema.Apple.Prospetti.Disposizione.self
        return HStack(alignment: .top, spacing: d.spazioLaterale) {
            barraLateraleApple
                .frame(width: d.larghezzaLaterale)
                .frame(maxHeight: .infinity, alignment: .top)
            VStack(alignment: .leading, spacing: d.spazioBarra) {
                if let documento {
                    barraAzioniApple(documento)
                }
                anteprimaApple(documento, generazione: generazione)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Barra laterale

    private var barraLateraleApple: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        let forma = RoundedRectangle(cornerRadius: l.raggio, style: .continuous)
        let perIncontro = tipiPerIncontro
        return VStack(alignment: .leading, spacing: 0) {
            RigaClienteProspettiApple()
                .padding(.bottom, l.sottoCliente)
            ScrollViewReader { lettore in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        gruppoApple("Per l'incontro", tipi: perIncontro, primo: 0)
                        gruppoApple("Prospetti di dettaglio", tipi: Self.tipiDiDettaglio, primo: perIncontro.count + 1)
                        if !stato.inModoCliente {
                            gruppoApple("Per te", tipi: [.portafoglio], primo: perIncontro.count + Self.tipiDiDettaglio.count + 2)
                        }
                        cardFascicoloApple
                            .padding(.top, l.sopraFascicolo)
                            .id(TipoProspetto.fascicolo.id)
                            .entrataCascata(perIncontro.count + Self.tipiDiDettaglio.count + 4)
                        piedeLateraleApple
                            .padding(.top, l.sopraPiede)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // All'apertura la voce scelta si vede anche se è in fondo all'elenco
                .onAppear { if !modoIstantanea { lettore.scrollTo(scelta.tipo.id) } }
            }
        }
        .padding(l.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(forma)
        .superficieApple(l.superficie, raggio: l.raggio)
        // Le scelte del documento (segmentato, pannelli, etichette del canale) nello stile del tema Apple
        .strumentiApple()
    }

    private func gruppoApple(_ titolo: String, tipi: [TipoProspetto], primo: Int) -> some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        return VStack(alignment: .leading, spacing: l.fraVoci) {
            Text(titolo)
                .carattereApple(l.etichetta)
                .foregroundColor(l.coloreEtichetta)
                .lineLimit(1)
                .padding(.top, primo == 0 ? 0 : l.sopraGruppo)
                .padding(.bottom, max(0, l.sottoEtichetta - l.fraVoci))
                .entrataCascata(primo)
            ForEach(Array(tipi.enumerated()), id: \.element) { i, t in
                voceApple(t)
                    .entrataCascata(primo + i + 1, sfocatura: false)
            }
        }
    }

    private func voceApple(_ t: TipoProspetto) -> some View {
        let scelta = self.scelta.tipo == t
        return VStack(alignment: .leading, spacing: 0) {
            VoceProspettoApple(titolo: nomeBreve(t), sottotitolo: sottotitoloVoce(t), nuovo: voceNuova(t), scelta: scelta) {
                scegliApple(t)
            }
            if scelta {
                contenutoScelta
                    .padding(Tema.Apple.Prospetti.Laterale.paddingScelte)
                    .transition(.opacity)
            }
        }
        .id(t.id)
    }

    /// Il sottotitolo della voce (`.rub small`): che cosa si impagina.
    private func sottotitoloVoce(_ t: TipoProspetto) -> String {
        switch t {
        case .riesame: return "Prospetto per te, prima dell'incontro"
        case .posizione: return "Una posizione o una proposta"
        case .confronto: return "Due voci a fronte"
        case .portafoglio: return "Tutti i clienti, solo per te"
        case .fascicolo: return "I report scelti in un solo PDF"
        case .annoInsieme: return "Report per il cliente"
        default: return "Prospetto e report"
        }
    }

    /// «nuovo» accanto al sottotitolo (in accento): per i report appena arrivati in Prisma.
    private func voceNuova(_ t: TipoProspetto) -> Bool {
        t == .annoInsieme
    }

    /// Sceglie la voce: la pagina vecchia esce verso l'alto se si scende nell'elenco, verso il basso se si risale.
    func scegliApple(_ t: TipoProspetto) {
        guard t != scelta.tipo else { return }
        let da = ordineVoci.firstIndex(of: scelta.tipo) ?? 0
        let a = ordineVoci.firstIndex(of: t) ?? 0
        cambiaAnteprima(direzione: a >= da ? 1 : -1) { scegli(t) }
    }

    /// Il verso va deciso prima del cambio: la pagina che esce porta la transizione con cui è stata disegnata.
    private func cambiaAnteprima(direzione: Int, _ cambia: @escaping () -> Void) {
        let animazione = Tema.Apple.Moto.animazione(Tema.Apple.Moto.Pagina.entrata, calmo: calmo, istantanea: modoIstantanea)
        let esegui = {
            if let animazione {
                withAnimation(animazione) { cambia() }
            } else {
                cambia()
            }
        }
        if direzione == direzioneAnteprima {
            esegui()
        } else {
            direzioneAnteprima = direzione
            DispatchQueue.main.async { esegui() }
        }
    }

    private var cardFascicoloApple: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        let scelto = scelta.tipo == .fascicolo
        let forma = RoundedRectangle(cornerRadius: l.raggioFascicolo, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Text("Fascicolo dell'incontro")
                .carattereApple(l.etichetta)
                .foregroundColor(l.coloreEtichetta)
                .lineLimit(1)
            Text("I report scelti in un solo PDF, con la data dell'incontro.")
                .carattereApple(l.testoFascicolo)
                .foregroundColor(l.coloreTestoFascicolo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, l.sottoTitoloFascicolo)
            if scelto {
                // Le scelte hanno già il loro margine: qui si allineano al testo della card
                contenutoScelta
                    .padding(.horizontal, -l.rientroScelte)
                    .transition(.opacity)
            } else {
                Button("Componi il fascicolo") { scegliApple(.fascicolo) }
                    .buttonStyle(.apple)
                    .padding(.top, l.sopraPulsanteFascicolo)
                    .help("Il fascicolo dell'incontro: spunta i report da consegnare e salvali in un solo PDF")
            }
        }
        .padding(l.paddingFascicolo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(l.superficieFascicolo, raggio: l.raggioFascicolo)
        .overlay {
            if scelto {
                forma.strokeBorder(l.bordoFascicoloScelto, lineWidth: Tema.Apple.Misura.bordo)
            }
        }
    }

    /// In fondo: dove si impagina, e le app collegate.
    private var piedeLateraleApple: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        return VStack(alignment: .leading, spacing: l.spazioCollegati) {
            HStack(spacing: l.spazioCollegati) {
                collegamento("Posizioni") {
                    stato.portafoglio = false
                    stato.apri(.posizioni)
                }
                collegamento(AppPrisma.prodotti.titolo) { stato.apri(.prodotti) }
            }
            HStack(spacing: l.spazioCollegati) {
                collegamento(AppPrisma.documenti.titolo) { stato.apri(.documenti) }
                collegamento(StrumentoAnalisi.confronto.titolo) { stato.apriStrumentoAnalisi(.confronto) }
            }
            Text(Self.notaStato)
                .carattereApple(l.piede)
                .foregroundColor(l.colorePiede)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, l.spazioCollegati)
        }
    }

    private func collegamento(_ titolo: String, _ azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            HStack(spacing: Tema.Apple.Controlli.Pulsante.spazio) {
                Text(titolo)
                Image(systemName: "arrow.up.right")
            }
        }
        .buttonStyle(.appleSobrio)
    }

    // MARK: Barra delle azioni

    private func barraAzioniApple(_ d: DocumentoStampabile) -> some View {
        let b = Tema.Apple.Prospetti.Barra.self
        let n = d.pagine.count
        let formato = d.formato.width > d.formato.height ? "A4 orizzontale" : "A4 verticale"
        return HStack(spacing: b.spazioAzioni) {
            VStack(alignment: .leading, spacing: b.spazioTitoli) {
                // Nelle finestre strette il titolo si accorcia nel mezzo: restano l'inizio e la fine («… 2030»)
                Text(d.titolo)
                    .carattereApple(b.titolo)
                    .foregroundColor(b.coloreTitolo)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(d.titolo)
                Text("\(d.genere) · \(d.cliente) · \(formato) · \(n) \(n == 1 ? "pagina" : "pagine")")
                    .carattereApple(b.sottotitolo)
                    .foregroundColor(b.coloreSottotitolo)
                    .lineLimit(1)
            }
            // Il titolo tiene sempre un minimo: se non basta, le azioni passano alle sole icone
            .frame(minWidth: b.larghezzaMinimaTitolo, alignment: .leading)
            Spacer(minLength: b.spazioAzioni)
            // Con le etichette se c'è posto, altrimenti le sole icone (con il suggerimento): il blu tiene la scritta
            ViewThatFits(in: .horizontal) {
                azioniApple(d, soloIcona: false)
                azioniApple(d, soloIcona: true)
            }
            .layoutPriority(1)
        }
        .padding(b.padding)
    }

    private func azioniApple(_ d: DocumentoStampabile, soloIcona: Bool) -> some View {
        let b = Tema.Apple.Prospetti.Barra.self
        return HStack(spacing: b.spazioAzioni) {
            if let id = archiviato {
                Button {
                    stato.documentoSelezionato = id
                    stato.apri(.documenti)
                } label: {
                    HStack(spacing: Tema.Apple.Controlli.Pulsante.spazio) {
                        Text("Archiviato in Documenti")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(.appleSobrio)
                .fixedSize()
            }
            if scelta.spuntoRuby != nil {
                Button { stato.chiediRubyDelDocumento(scelta) } label: {
                    etichettaAzione("Chiedi a Ruby", simbolo: "sparkles", soloIcona: soloIcona)
                }
                .buttonStyle(.apple)
                .fixedSize()
                .disabled(stato.rubyInCorso)
                .help("Chiedi a Ruby: spiega le cifre di questo documento, per te")
            }
            #if os(macOS)
            // Il tavolo con l'iPad (Shell/AlTavolo.swift): mai il portafoglio, che parla di tutti i clienti
            if scelta.tipo != .portafoglio {
                PulsanteAlTavolo(tavolo: stato.tavolo,
                                 contesto: ContestoTavolo(documento: d, pagina: indiceAnteprima(d), clienteId: stato.clienteAttivoId),
                                 soloIcona: soloIcona)
            }
            #endif
            // Il portafoglio parla di tutti i clienti: non si mostra a un cliente
            if scelta.tipo != .portafoglio {
                Button { presentaApple(d) } label: {
                    etichettaAzione("Presenta all'incontro", simbolo: "play.fill", soloIcona: soloIcona)
                }
                .buttonStyle(.apple)
                .fixedSize()
                .help("Presenta all'incontro: il documento a tutto schermo dalla pagina mostrata (← → per sfogliare, esc per uscire), in modalità cliente")
            }
            Button { if let dati = pdf(d) { StampaCarta.stampa(dati, formato: d.formato) } } label: {
                etichettaAzione("Stampa…", simbolo: "printer", soloIcona: soloIcona)
            }
            .buttonStyle(.apple)
            .fixedSize()
            .help("Stampa…")
            // Il portafoglio riguarda tutti i clienti: non va nei documenti di uno di loro
            if scelta.tipo != .portafoglio {
                Button {
                    if let dati = pdf(d) { archiviato = stato.archiviaProspetto(dati, documento: d) }
                } label: {
                    etichettaAzione("Archivia nei Documenti", simbolo: "archivebox", soloIcona: soloIcona)
                }
                .buttonStyle(.apple)
                .fixedSize()
                .help("Archivia nei Documenti del cliente")
            }
            // Il blu: l'azione principale, tiene sempre la scritta
            Button {
                // Il portafoglio è per te: il foglio della password resta, senza proposta dai dati di un cliente
                if let dati = pdf(d) {
                    daSalvare = PDFDaSalvare(dati: dati, nome: StampaCarta.nomeFile(d), cliente: scelta.tipo == .portafoglio ? nil : stato.clienteAttivo)
                }
            } label: {
                Label("Salva PDF…", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.applePrimario)
            .fixedSize()
        }
    }

    @ViewBuilder private func etichettaAzione(_ testo: String, simbolo: String, soloIcona: Bool) -> some View {
        if soloIcona {
            Image(systemName: simbolo)
                .accessibilityLabel(Text(testo))
        } else {
            Label(testo, systemImage: simbolo)
        }
    }

    /// La presentazione parte dalla pagina mostrata nell'anteprima.
    private func presentaApple(_ d: DocumentoStampabile) {
        // Presentare il prospetto del riesame salva la fotografia di oggi (memoria del riesame)
        if case .riesame = scelta { stato.fotografaRiesame(stato.clienteAttivoId, origine: .prospetto) }
        stato.presenta(d, daPagina: indiceAnteprima(d))
    }

    // MARK: Anteprima

    /// La pagina mostrata: quella girata per questa scelta e questo cliente, altrimenti la prima.
    func indiceAnteprima(_ d: DocumentoStampabile) -> Int {
        let n = d.pagine.count
        guard n > 0 else { return 0 }
        let p = paginaAnteprima
        let i = (p.scelta == scelta && p.cliente == cliente) ? p.indice : 0
        return min(max(i, 0), n - 1)
    }

    /// Va alla pagina data (se c'è), con la pagina che cambia nel verso giusto.
    func vaiAPagina(_ nuova: Int, di d: DocumentoStampabile) {
        let attuale = indiceAnteprima(d)
        guard nuova >= 0, nuova < d.pagine.count, nuova != attuale else { return }
        let pagina = PaginaAnteprimaProspetto(scelta: scelta, cliente: cliente, indice: nuova)
        cambiaAnteprima(direzione: nuova > attuale ? 1 : -1) { paginaAnteprima = pagina }
    }

    private func anteprimaApple(_ documento: DocumentoStampabile?, generazione: Int) -> some View {
        let a = Tema.Apple.Prospetti.Anteprima.self
        let forma = RoundedRectangle(cornerRadius: a.raggio, style: .continuous)
        return GeometryReader { geo in
            ZStack(alignment: .top) {
                if let documento, !documento.pagine.isEmpty {
                    paginaAnteprimaApple(documento, generazione: generazione, misura: geo.size)
                } else {
                    vuoto
                        .frame(maxWidth: a.vuotoLarghezza)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background { forma.fill(a.fondo) }
        // La pagina che entra o esce non va fuori dal fondo
        .clipShape(forma)
    }

    private func paginaAnteprimaApple(_ d: DocumentoStampabile, generazione: Int, misura: CGSize) -> some View {
        let a = Tema.Apple.Prospetti.Anteprima.self
        let indice = indiceAnteprima(d)
        let largo = max(1, misura.width - a.margineLati * 2)
        let alto = max(1, misura.height - a.margineAlto - a.margineBasso)
        let adatta = min(largo / d.formato.width, alto / d.formato.height)
        let scala = min(a.scalaMassima, max(a.scalaMinima, adatta))
        let id = IdAnteprimaProspetto(scelta: scelta, cliente: cliente, indice: indice)
        return ZStack(alignment: .top) {
            #if os(macOS)
            // Lo scorrimento (rotella o trackpad) sull'anteprima gira la pagina; non riceve clic
            if !modoIstantanea {
                AreaScorrimentoAnteprima(
                    attiva: { [stato] in stato.appAttiva == .presentazioni && stato.presentazione == nil && !stato.bloccato },
                    scorri: { passo in vaiAPagina(indice + passo, di: d) }
                )
            }
            #endif
            FoglioAnteprimaApple(documento: d, indice: indice, scala: scala, generazione: generazione)
                .equatable()
                .padding(.top, a.margineAlto)
                .modifier(SfogliaAnteprimaApple { passo in vaiAPagina(indice + passo, di: d) })
                .id(id)
                .transition(AnyTransition.cambioPagina(direzione: direzioneAnteprima, calmo: calmo))
            comandiPagineApple(indice, documento: d)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, a.comandiFondo)
        }
        .frame(width: misura.width, height: misura.height, alignment: .top)
    }

    /// Sotto la carta: le frecce da 32 e «2 di 5».
    private func comandiPagineApple(_ indice: Int, documento d: DocumentoStampabile) -> some View {
        let a = Tema.Apple.Prospetti.Anteprima.self
        let n = d.pagine.count
        return HStack(spacing: a.spazioComandi) {
            if n > 1 {
                FrecciaAnteprimaApple(simbolo: "chevron.left", aiuto: "Pagina precedente") { vaiAPagina(indice - 1, di: d) }
                    .disabled(indice == 0)
            }
            Text(n == 1 ? "1 pagina" : "\(indice + 1) di \(n)")
                .carattereApple(a.contatore)
                .foregroundColor(a.coloreContatore)
                .frame(minWidth: a.larghezzaContatore)
            if n > 1 {
                FrecciaAnteprimaApple(simbolo: "chevron.right", aiuto: "Pagina seguente") { vaiAPagina(indice + 1, di: d) }
                    .disabled(indice >= n - 1)
            }
        }
    }
}

// MARK: - Componenti

/// Il cliente dei prospetti: avatar 30, nome 14 bold e la tendina con tutti i clienti.
private struct RigaClienteProspettiApple: View {
    @EnvironmentObject var stato: StatoShell
    @State private var aperto = false

    var body: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        let cliente = stato.clienteAttivo
        return Button { aperto = true } label: {
            HStack(spacing: l.spazioCliente) {
                if let c = cliente {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: l.avatar)
                }
                Text(cliente?.nome ?? "Nessun cliente")
                    .carattereApple(l.nomeCliente)
                    .foregroundColor(l.coloreNome)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .carattereApple(l.frecciaCliente)
                    .foregroundColor(l.coloreFreccia)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .popover(isPresented: $aperto, arrowEdge: .trailing) { ElencoClienti(aperto: $aperto) }
        .help("Scegli il cliente: prospetti e report valgono per lui")
    }
}

/// Una voce della barra laterale (`.rub`): titolo 14 bold e sottotitolo 12 `inchiostro2` («· nuovo» in accento);
/// sotto il puntatore `chip`, scelta `rgba(0,122,255,.13)`, il fondo cambia in 0,25 s.
private struct VoceProspettoApple: View {
    let titolo: String
    let sottotitolo: String
    let nuovo: Bool
    let scelta: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    var body: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        let forma = RoundedRectangle(cornerRadius: l.raggioVoce, style: .continuous)
        return Button(action: azione) {
            VStack(alignment: .leading, spacing: l.spazioTitoli) {
                Text(titolo)
                    .carattereApple(l.titoloVoce)
                    .foregroundColor(l.coloreTitoloVoce)
                testoSotto
                    .carattereApple(l.sottotitoloVoce)
            }
            .lineLimit(1)
            .padding(l.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { fondo }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        #if os(macOS)
        .onHover { dentro in sopra = dentro && !istantanea }
        #endif
        .animation(animazione, value: scelta)
        .animation(animazione, value: sopra)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    private var testoSotto: Text {
        let l = Tema.Apple.Prospetti.Laterale.self
        let base = Text(sottotitolo).foregroundColor(l.coloreSottotitoloVoce)
        guard nuovo else { return base }
        return base + Text(" · ").foregroundColor(l.coloreSottotitoloVoce) + Text("nuovo").foregroundColor(l.coloreNuovo)
    }

    @ViewBuilder private var fondo: some View {
        let l = Tema.Apple.Prospetti.Laterale.self
        let forma = RoundedRectangle(cornerRadius: l.raggioVoce, style: .continuous)
        if scelta {
            forma.fill(l.fondoScelta)
        } else if sopra {
            forma.fill(l.fondoSopra)
        }
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Prospetti.Laterale.animazioneFondo, calmo: calmo, istantanea: istantanea)
    }
}

/// La pagina dell'anteprima, sempre su carta bianca con l'ombra della carta (§1.2): solo quella mostrata, non tutto
/// il documento. Le pagine sono `AnyView`, che SwiftUI non sa confrontare: si rifà solo con un'impaginazione nuova,
/// un'altra pagina o un'altra scala, non a ogni cambiamento dello stato.
private struct FoglioAnteprimaApple: View, Equatable {
    let documento: DocumentoStampabile
    let indice: Int
    let scala: CGFloat
    /// Il numero dell'impaginazione (StatoShell.generazioneDocumento): lo stesso numero è lo stesso documento.
    let generazione: Int

    nonisolated static func == (a: FoglioAnteprimaApple, b: FoglioAnteprimaApple) -> Bool {
        a.generazione == b.generazione && a.indice == b.indice && a.scala == b.scala
    }

    var body: some View {
        let w = documento.formato.width
        let h = documento.formato.height
        documento.pagine[min(max(indice, 0), documento.pagine.count - 1)]
            // La carta resta come sulla carta: «Dimensione del testo» non la ingrandisce
            .prismaScalaTesto(1)
            .frame(width: w, height: h)
            .scaleEffect(scala, anchor: .top)
            .frame(width: w * scala, height: h * scala, alignment: .top)
            .superficieApple(Tema.Apple.Prospetti.Anteprima.carta)
    }
}

/// La freccia tonda sotto la carta (`.arr`: `cardPiena` con il filo `separatore`).
private struct FrecciaAnteprimaApple: View {
    let simbolo: String
    let aiuto: String
    let azione: () -> Void
    @Environment(\.isEnabled) private var abilitata

    var body: some View {
        let a = Tema.Apple.Prospetti.Anteprima.self
        Button(action: azione) {
            Image(systemName: simbolo)
                .carattereApple(a.carattereFreccia)
                .foregroundColor(a.coloreFreccia)
                .frame(width: a.freccia, height: a.freccia)
                .background { Circle().fill(a.fondoFreccia) }
                .overlay { Circle().strokeBorder(a.bordoFreccia, lineWidth: Tema.Apple.Misura.bordo) }
                .contentShape(Circle())
        }
        .buttonStyle(StileSemplice())
        .opacity(abilitata ? 1 : a.opacitaFrecciaSpenta)
        .help(aiuto)
        .accessibilityLabel(Text(aiuto))
    }
}

// MARK: - Sfogliare sull'iPad

/// Sull'iPad la carta si sfoglia col dito: un colpo verso sinistra (o verso l'alto) porta alla pagina seguente,
/// verso destra (o verso il basso) alla precedente. Sul Mac non fa niente: lì gira la pagina lo scorrimento.
private struct SfogliaAnteprimaApple: ViewModifier {
    let scorri: (Int) -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content.gesture(
            DragGesture(minimumDistance: Tema.Apple.Prospetti.Anteprima.distanzaSfoglia)
                .onEnded { g in
                    let dx = g.translation.width
                    let dy = g.translation.height
                    let soglia = Tema.Apple.Prospetti.Anteprima.sogliaSfoglia
                    let lungo = abs(dx) >= abs(dy) ? dx : dy
                    guard abs(lungo) >= soglia else { return }
                    scorri(lungo < 0 ? 1 : -1)
                }
        )
        #else
        content
        #endif
    }
}

#if os(macOS)

// MARK: - Scorrimento sull'anteprima

/// Lo scorrimento con la rotella o con il trackpad sopra l'anteprima gira la pagina (giù = la seguente).
/// Un `DragGesture` non risponde allo scorrimento a due dita: serve un monitor locale degli eventi `.scrollWheel`,
/// che prende solo quelli dentro l'anteprima, nella finestra di Prisma, con Prospetti in primo piano. La vista non
/// riceve clic (`hitTest` nil): pulsanti e carta sotto restano come sono.
private struct AreaScorrimentoAnteprima: NSViewRepresentable {
    let attiva: () -> Bool
    let scorri: (Int) -> Void

    func makeNSView(context: Context) -> VistaScorrimentoAnteprima {
        let vista = VistaScorrimentoAnteprima()
        vista.attiva = attiva
        vista.scorri = scorri
        return vista
    }

    func updateNSView(_ vista: VistaScorrimentoAnteprima, context: Context) {
        vista.attiva = attiva
        vista.scorri = scorri
    }

    static func dismantleNSView(_ vista: VistaScorrimentoAnteprima, coordinator: ()) {
        vista.fermaMonitor()
    }
}

private final class VistaScorrimentoAnteprima: NSView {
    var attiva: () -> Bool = { false }
    var scorri: (Int) -> Void = { _ in }
    private var monitor: Any?
    /// Gli spostamenti del gesto del trackpad in corso (negativo = verso la pagina seguente).
    private var accumulo: CGFloat = 0
    /// Un gesto gira una pagina sola: il resto del gesto e la sua inerzia passano a vuoto.
    private var giratoNelGesto = false
    /// L'ultimo giro con la rotella del mouse (o con un trackpad senza fasi).
    private var ultimoGiro: TimeInterval = 0

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { fermaMonitor() } else { avviaMonitor() }
    }

    deinit {
        if let m = monitor { NSEvent.removeMonitor(m) }
    }

    func fermaMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }

    private func avviaMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] e in
            guard let self else { return e }
            return self.gestisci(e) ? nil : e
        }
    }

    /// true se l'evento è dell'anteprima (e allora non va oltre).
    private func gestisci(_ e: NSEvent) -> Bool {
        guard let finestra = window, e.window === finestra, !isHiddenOrHasHiddenAncestor, attiva() else { return false }
        let punto = convert(e.locationInWindow, from: nil)
        guard bounds.contains(punto) else { return false }
        let a = Tema.Apple.Prospetti.Anteprima.self
        // L'inerzia dopo il rilascio non gira altre pagine
        if !e.momentumPhase.isEmpty { return true }
        let dy = e.scrollingDeltaY
        if e.hasPreciseScrollingDeltas && !e.phase.isEmpty {
            if e.phase.contains(.began) {
                accumulo = 0
                giratoNelGesto = false
            }
            if !giratoNelGesto {
                accumulo += dy
                if abs(accumulo) >= a.sogliaScorrimento {
                    giratoNelGesto = true
                    scorri(accumulo < 0 ? 1 : -1)
                }
            }
            if e.phase.contains(.ended) || e.phase.contains(.cancelled) {
                accumulo = 0
                giratoNelGesto = false
            }
            return true
        }
        // Rotella del mouse: un giro per pagina, poi una breve pausa
        guard dy != 0 else { return false }
        if e.hasPreciseScrollingDeltas {
            accumulo += dy
            guard abs(accumulo) >= a.sogliaScorrimento else { return true }
        }
        let passo = (e.hasPreciseScrollingDeltas ? accumulo : dy) < 0 ? 1 : -1
        accumulo = 0
        guard e.timestamp - ultimoGiro >= a.pausaRotella else { return true }
        ultimoGiro = e.timestamp
        scorri(passo)
        return true
    }
}

#endif
