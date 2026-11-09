import SwiftUI

// Sala › La capsula del tempo (Design/template-luce-specifica.md §3.4, «Luce» giro 15): il cliente scrive un messaggio a
// sé stesso per il giorno in cui avrà raggiunto un obiettivo; Prisma lo sigilla e lo cifra (`SigilloCapsule`, chiave nel
// Portachiavi del Mac) e lo tiene chiuso fino al giorno giusto, poi il consulente lo apre e lo consegna.
//
//   Scrivi alla te stessa del giorno in cui…        LE CAPSULE SIGILLATE
//   Prisma la sigilla e la cifra: …                  ┌ Sofia Romano · Rendita integrativa ──────────┐
//   ┌──────────────────────────────────────┐         │ Obiettivo raggiunto ieri: …  [Apri e consegna]│
//   │ Perché lo stai facendo? (serif 17)   │         └──────────────────────────────────────────────┘
//   └──────────────────────────────────────┘         (GR) Giulia Rossi · Anticipo per la casa      🔒
//   SI APRE QUANDO  (Anticipo casa) (In una data…)        si apre quando «…» è raggiunto · sigillata a …
//   [ ✉︎ Sigilla la capsula ]
//
// - Riservatezza (§3.4.1, decisione 43): nella Sala solo le capsule del cliente scelto; «Apri e consegna» solo per le
//   sue capsule pronte. Il testo si decifra al momento dell'apertura, vive in `@State` e si azzera alla chiusura, a Esc e
//   al blocco di Prisma: mai salvato, mai a Vera.
// - Sigillare: conferma, poi il testo vola nella busta, il lembo si chiude, il sigillo si imprime, la busta vola
//   nell'elenco e la riga nuova compare con un lampo viola (`Moto.Capsula`); il sigillo vero si scrive subito, la riga si
//   mostra a fine volo. Aprire: velo, sigillo che si rompe, lembo, lettera che sale, testo due parole alla volta.
// - Riduci movimento: il campo si svuota e la riga compare con la dissolvenza di 0,15 s; il foglio compare già aperto
//   con il testo intero. Istantanee: tutto fermo, capsula aperta con il foglio fuori e il testo intero, niente pulsazione.
// - Il PDF su carta bianca («Stampala su carta per …») e «Condividi…» solo come PDF protetto con una password nuova,
//   detta a voce (mai conservata); la traccia nel dossier (`UscitaCliente(.capsula)`).
// - «Scrivi sull'iPad» (giro 16, D-C4, decisione 48): solo sul Mac e solo con l'iPad del tavolo collegato. Il cliente
//   scrive sull'iPad; il testo torna in rete locale cifrata (`TavoloMac.chiediTestoCapsula`) ed entra nel campo come
//   bozza, con una nota: si sigilla solo con «✉︎ Sigilla la capsula» e la sua conferma, mai da solo. Durante l'attesa
//   «Annulla» riporta l'iPad alla schermata neutra; chiudere la vista o bloccare Prisma fa lo stesso.

/// Il contenuto del palco per la capsula del tempo.
struct CapsulaDelTempo: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Falso sulla sala opaca della presentazione (niente menu, niente eliminazioni).
    var modificabile = true

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    @State private var testo = ""
    @State private var scelta: SceltaAperturaCapsula?
    @State private var dataScelta = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var conferma = false
    /// Il sigillo animato in corso.
    @State private var sigillo = PassiSigillo()
    /// La riga appena sigillata: nascosta finché la busta vola, poi con il lampo.
    @State private var nascosta: String?
    @State private var lampo: String?
    /// La capsula aperta: id, testo (solo in memoria) e la password del PDF condiviso.
    @State private var aperta: CapsulaAperta?
    @State private var daEliminare: CapsulaTempo?
    @State private var daCambiare: CapsulaTempo?
    /// Il testo nel campo è arrivato dall'iPad del tavolo: bozza da sigillare (la nota sotto il campo).
    @State private var bozzaDalTavolo = false
    /// L'iPad sta scrivendo il testo («Scrivi sull'iPad»): «Sigilla» aspetta.
    @State private var attesaTavolo = false

    private typealias K = Tema.Apple.SalaRacconti.Capsula
    private typealias M = Tema.Apple.Moto.Capsula

    var body: some View {
        let _ = ContaCorpi.segna()
        let nome = StatoShell.nomeBreve(cliente)
        let obiettivi = stato.obiettiviCliente(cliente.id)
        let capsule = stato.capsuleCliente(cliente.id)
        let mostrata = aperta ?? apertaIstantanea
        ZStack(alignment: .topLeading) {
            Group {
                colonnaSinistra(nome: nome, obiettivi: obiettivi)
                    .frame(width: K.larghezzaSinistra, alignment: .topLeading)
                    .padding(.leading, K.sinistra)
                    .padding(.top, K.alto)
                    .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                colonnaDestra(nome: nome, capsule: capsule)
                    .padding(.leading, K.inizioDestra)
                    .padding(.trailing, K.margineDestro)
                    .padding(.top, K.alto)
                    .padding(.bottom, K.basso)
                    .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                if sigillo.bustaVisibile {
                    BustaCapsula(lemboChiuso: sigillo.lemboChiuso, sigilloImpresso: sigillo.sigilloImpresso, pronta: false)
                        .scaleEffect(sigillo.bustaVola ? K.scalaVoloBusta : (sigillo.bustaEntrata ? 1 : K.scalaEntrataBusta),
                                     anchor: .center)
                        .offset(x: sigillo.bustaVola ? K.voloBusta.width : 0, y: sigillo.bustaVola ? K.voloBusta.height : 0)
                        .opacity(sigillo.bustaVola ? 0 : (sigillo.bustaEntrata ? 1 : 0))
                        .padding(.leading, K.sinistra + K.bustaSinistra)
                        .padding(.top, K.alto + K.bustaAlto)
                        .allowsHitTesting(false)
                }
            }
            .blur(radius: mostrata == nil ? 0 : K.sfocaturaVelo)
            .allowsHitTesting(mostrata == nil)
            if let a = mostrata, let c = stato.dati.capsule.first(where: { $0.id == a.id }) {
                AperturaCapsula(capsula: c, testo: a.testo, password: a.password, cliente: cliente, modificabile: modificabile,
                                chiudi: chiudiApertura)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { avvia(obiettivi: obiettivi) }
        .onDisappear {
            aperta = nil
            stato.sala.dettaglioValoreAperto = false
            #if os(macOS)
            if attesaTavolo { stato.tavolo.annullaTestoCapsula() }
            #endif
        }
        // Al blocco di Prisma il foglio aperto si chiude e il testo si azzera (e l'iPad non aspetta più la capsula)
        .onChange(of: stato.bloccato) { _, bloccato in
            guard bloccato else { return }
            chiudiApertura()
            #if os(macOS)
            if attesaTavolo { stato.tavolo.annullaTestoCapsula() }
            #endif
        }
        .onChange(of: testo) { _, t in
            if t.isEmpty { bozzaDalTavolo = false }
        }
        .confirmationDialog(TestiCapsule.conferma, isPresented: $conferma, titleVisibility: .visible) {
            Button("Sigilla") { sigilla(obiettivi: obiettivi) }
            Button("Annulla", role: .cancel) {}
        }
        .confirmationDialog(TestiCapsule.elimina, isPresented: Binding(get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } }),
                            titleVisibility: .visible, presenting: daEliminare) { c in
            Button("Elimina", role: .destructive) { stato.eliminaCapsula(c.id) }
            Button("Annulla", role: .cancel) {}
        } message: { _ in
            Text(TestiCapsule.confermaElimina)
        }
        .sheet(item: $daCambiare) { c in
            ModuloAperturaCapsula(capsula: c, obiettivi: obiettivi) { nuova in stato.cambiaAperturaCapsula(c.id, nuova) }
        }
    }

    // MARK: La colonna di sinistra

    @ViewBuilder
    private func colonnaSinistra(nome: String, obiettivi: [Obiettivo]) -> some View {
        let attuale = sceltaAttuale(obiettivi)
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiCapsule.titolo(femminile: MotoreAree360.femminile(cliente)))
                .carattereApple(K.titolo)
                .foregroundColor(K.coloreTitolo)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiCapsule.fraseOnesta)
                .carattereApple(K.frase)
                .foregroundColor(K.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, K.sottoTitolo)
            campo
                .padding(.top, K.sopraCampo)
                .scaleEffect(sigillo.testoVola ? K.scalaVoloTesto : 1, anchor: .topLeading)
                .offset(x: sigillo.testoVola ? K.voloTesto.width : 0, y: sigillo.testoVola ? K.voloTesto.height : 0)
                .opacity(sigillo.testoVola ? 0 : 1)
            if bozzaDalTavolo {
                Text(TestiRealta.capsulaArrivata(TestiRealta.primoNome(cliente.nome)))
                    .carattereApple(K.nota)
                    .foregroundColor(K.coloreBozzaArrivata)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, K.sopraAiuto)
            }
            Text(TestiCapsule.aiutoDettatura)
                .carattereApple(K.aiuto)
                .foregroundColor(K.coloreAiuto)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, K.sopraAiuto)
            Text(TestiCapsule.etichettaQuando)
                .carattereApple(K.etichetta)
                .foregroundColor(K.coloreEtichetta)
                .padding(.top, K.sopraEtichetta)
            chip(obiettivi: obiettivi, attuale: attuale)
                .padding(.top, K.sottoEtichetta)
            if obiettivi.isEmpty {
                Text(TestiCapsule.senzaObiettivi(nome: nome))
                    .carattereApple(K.nota)
                    .foregroundColor(K.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, K.sottoEtichetta)
            }
            if attuale == .data {
                DatePicker("Si apre il", selection: $dataScelta, in: domani..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .fixedSize()
                    .padding(.top, K.sottoEtichetta)
            }
            HStack(spacing: K.spazioTavolo) {
                Button { conferma = true } label: { Text(TestiCapsule.sigilla) }
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sigillo.inCorso || istantanea
                              || stato.solaLettura || attesaTavolo)
                    .help(TestiCapsule.conferma)
                #if os(macOS)
                // Il tavolo con l'iPad: il pulsante compare solo con l'iPad collegato (come «▣ Mostra sul tavolo»)
                ScriviCapsulaSullIPad(tavolo: stato.tavolo, cliente: cliente,
                                      siApre: TestiRealta.siApreCapsula(quandoScelto(obiettivi: obiettivi, attuale: attuale)),
                                      attivo: !(sigillo.inCorso || istantanea || stato.solaLettura),
                                      inAttesa: $attesaTavolo) { arrivato in
                    testo = MotoreCapsule.unisciBozza(testo, arrivato: arrivato)
                    bozzaDalTavolo = !testo.isEmpty
                    stato.mostraAvviso(TestiRealta.capsulaArrivata(TestiRealta.primoNome(cliente.nome)))
                }
                #endif
            }
            .padding(.top, K.sopraPulsante)
        }
    }

    /// «si apre quando «Anticipo casa» è raggiunto» o «si apre a marzo 2027»: la scelta attuale, per l'iPad del tavolo.
    private func quandoScelto(obiettivi: [Obiettivo], attuale: SceltaAperturaCapsula) -> String {
        switch attuale {
        case .obiettivo(let id):
            return MotoreCapsule.quando(.obiettivo(id: id), obiettivo: obiettivi.first { $0.id == id })
        case .data:
            return MotoreCapsule.quando(.data(Calendar.current.startOfDay(for: dataScelta)), obiettivo: nil)
        }
    }

    private var campo: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $testo)
                .carattereApple(K.testoCampo)
                .foregroundColor(K.coloreTestoCampo)
                .scrollContentBackground(.hidden)
                .disabled(sigillo.inCorso || istantanea || stato.solaLettura || attesaTavolo)
                .accessibilityLabel(Text("Il messaggio della capsula"))
            if testo.isEmpty {
                Text(TestiCapsule.segnaposto)
                    .carattereApple(K.testoCampo)
                    .foregroundColor(K.coloreSegnaposto)
                    .padding(.leading, K.rientroSegnaposto)
                    .allowsHitTesting(false)
            }
        }
        .padding(K.paddingCampo)
        .frame(minHeight: K.altezzaMinimaCampo, maxHeight: K.altezzaCampo)
        .background(RoundedRectangle(cornerRadius: K.raggioCampo, style: .continuous).fill(K.fondoCampo))
        .overlay(RoundedRectangle(cornerRadius: K.raggioCampo, style: .continuous).strokeBorder(K.bordoCampo, lineWidth: K.spessoreBordo))
    }

    private func chip(obiettivi: [Obiettivo], attuale: SceltaAperturaCapsula) -> some View {
        HStack(spacing: K.spazioChip) {
            ForEach(obiettivi) { o in
                ChipCapsula(titolo: o.titolo, scelta: attuale == .obiettivo(o.id)) { scelta = .obiettivo(o.id) }
            }
            ChipCapsula(titolo: TestiCapsule.inUnaData, scelta: attuale == .data) { scelta = .data }
        }
        .disabled(sigillo.inCorso || istantanea)
    }

    private var domani: Date {
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
    }

    /// La scelta di «Si apre quando»: quella fatta o il primo obiettivo (senza obiettivi la data).
    private func sceltaAttuale(_ obiettivi: [Obiettivo]) -> SceltaAperturaCapsula {
        if let scelta {
            if case .obiettivo(let id) = scelta, !obiettivi.contains(where: { $0.id == id }) {
                return obiettivi.first.map { SceltaAperturaCapsula.obiettivo($0.id) } ?? .data
            }
            return scelta
        }
        return obiettivi.first.map { SceltaAperturaCapsula.obiettivo($0.id) } ?? .data
    }

    // MARK: La colonna di destra

    @ViewBuilder
    private func colonnaDestra(nome: String, capsule: [CapsulaTempo]) -> some View {
        let visibili = capsule.filter { $0.id != nascosta }
        let stati = Dictionary(visibili.map { ($0.id, stato.statoCapsula($0)) }, uniquingKeysWith: { a, _ in a })
        let pronte = visibili.filter { stati[$0.id]?.pronta == true }
        let altre = visibili.filter { stati[$0.id]?.pronta != true }
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiCapsule.etichettaElenco)
                .carattereApple(K.etichetta)
                .foregroundColor(K.coloreEtichetta)
                .padding(.bottom, K.sottoEtichettaElenco)
            if visibili.isEmpty {
                Text(TestiCapsule.nessuna(nome: nome))
                    .carattereApple(K.nessuna)
                    .foregroundColor(K.coloreNessuna)
            }
            ForEach(pronte) { c in
                if let dal = Self.dataPronta(stati[c.id]) {
                    TileCapsulaPronta(capsula: c, cliente: cliente, titolo: titolo(c), perche: TestiCapsule.perchePronta(c, dal: dal, oggi: Date()),
                                      attiva: modificabile) { apri(c) }
                        .padding(.bottom, K.sottoPronta)
                }
            }
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(altre) { c in
                        let s = stati[c.id] ?? .sigillata
                        RigaCapsula(cliente: cliente, titolo: titolo(c),
                                    dettaglio: TestiCapsule.riga(c, stato: s, quando: MotoreCapsule.quando(c, obiettivo: stato.obiettivoCapsula(c))),
                                    avviso: s == .nonApribile || s == .daDecidere, chiusa: s.chiusa, lampo: lampo == c.id)
                            .help(s == .nonApribile ? TestiCapsule.aiutoNonApribile : "")
                            .contextMenu {
                                if modificabile && c.stato == .sigillata {
                                    Button(TestiCapsule.cambiaQuando) { daCambiare = c }
                                    Button(TestiCapsule.elimina, role: .destructive) { daEliminare = c }
                                }
                            }
                    }
                }
            }
            .scrollIndicators(.never)
            if altre.contains(where: { stati[$0.id] == .nonApribile }) {
                Text(TestiCapsule.aiutoNonApribile)
                    .carattereApple(K.aiutoChiave)
                    .foregroundColor(K.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, K.sottoEtichettaElenco)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Il giorno da cui la capsula è pronta (nil se non è pronta).
    private static func dataPronta(_ s: StatoCapsula?) -> Date? {
        guard let s, case .pronta(let dal) = s else { return nil }
        return dal
    }

    /// «Giulia Rossi · Anticipo per la casa»: il nome e l'obiettivo (o la copia del titolo al sigillo).
    private func titolo(_ c: CapsulaTempo) -> String {
        let obiettivo = stato.obiettivoCapsula(c)?.titolo ?? c.titoloObiettivo
        return [cliente.nome, obiettivo].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Avvio

    /// Istantanea 655: la capsula di prova aperta, con il foglio fuori e il testo intero (decifrata qui, senza toccare
    /// lo stato della capsula).
    private var apertaIstantanea: CapsulaAperta? {
        guard istantanea, let id = stato.sala.provaUscite.capsulaApertaId,
              let c = stato.dati.capsule.first(where: { $0.id == id && $0.clienteId == cliente.id }),
              let k = stato.chiaveCapsula(c), let t = try? SigilloCapsule.apri(c, chiave: k) else { return nil }
        return CapsulaAperta(id: id, testo: t, password: stato.sala.provaUscite.passwordDiProva ?? TestiCapsule.passwordDiProvaIstantanee,
                             animata: false)
    }

    private func avvia(obiettivi: [Obiettivo]) {
        guard !istantanea else { return }
        // «Apri la capsula» dai traguardi: la consegna si apre subito (solo per una capsula di questo cliente)
        if let id = stato.sala.capsulaDaAprire {
            stato.sala.capsulaDaAprire = nil
            if let c = stato.dati.capsule.first(where: { $0.id == id }), c.clienteId == cliente.id { apri(c) }
        }
    }

    // MARK: Sigillare

    private func sigilla(obiettivi: [Obiettivo]) {
        let apertura: CapsulaTempo.Apertura
        switch sceltaAttuale(obiettivi) {
        case .obiettivo(let id): apertura = .obiettivo(id: id)
        case .data: apertura = .data(Calendar.current.startOfDay(for: dataScelta))
        }
        let prima = Set(stato.dati.capsule.map(\.id))
        // Riduci movimento: il campo si svuota e la riga nuova compare con la dissolvenza di 0,15 s
        let sigillata: Bool
        if calmo {
            sigillata = withAnimation(Tema.Moto.dissolvenzaCalma) { stato.sigillaCapsula(testo, apertura: apertura, cliente: cliente) }
        } else {
            sigillata = stato.sigillaCapsula(testo, apertura: apertura, cliente: cliente)
        }
        guard sigillata else {
            stato.mostraAvviso(TestiCapsule.toastNonSigillata)
            return
        }
        let nuova = stato.dati.capsule.first { !prima.contains($0.id) }?.id
        if calmo {
            testo = ""
            stato.mostraAvviso(TestiCapsule.toastSigillata)
            return
        }
        nascosta = nuova
        sigillo = PassiSigillo(inCorso: true)
        withAnimation(M.curvaVoloTesto.animazione(M.voloTesto)) { sigillo.testoVola = true }
        Movimenti.dopo(M.ritardoBusta) {
            sigillo.bustaVisibile = true
            withAnimation(.easeOut(duration: M.entrataBusta)) { sigillo.bustaEntrata = true }
        }
        Movimenti.dopo(M.ritardoLembo) {
            withAnimation(M.curvaLembo.animazione(M.lembo)) { sigillo.lemboChiuso = true }
        }
        Movimenti.dopo(M.ritardoSigillo) {
            withAnimation(M.sigilloMolla.animazione) { sigillo.sigilloImpresso = true }
        }
        Movimenti.dopo(M.ritardoVolo) {
            withAnimation(M.curvaVoloTesto.animazione(M.voloBusta)) { sigillo.bustaVola = true }
        }
        Movimenti.dopo(M.ritardoRiga) {
            testo = ""
            lampo = nuova
            withAnimation(M.curvaRiga.animazione(M.rigaNuova)) {
                nascosta = nil
                sigillo = PassiSigillo()
            }
            stato.mostraAvviso(TestiCapsule.toastSigillata)
            Movimenti.dopo(M.rigaNuova) {
                withAnimation(.easeOut(duration: M.rigaNuova)) { lampo = nil }
            }
        }
    }

    // MARK: Aprire

    private func apri(_ c: CapsulaTempo) {
        guard c.clienteId == cliente.id else { return }
        mostraAperta(c.id, animata: !calmo)
    }

    private func mostraAperta(_ id: String, animata: Bool) {
        guard let t = stato.apriCapsula(id) else {
            stato.mostraAvviso(TestiCapsule.nonApribile)
            return
        }
        let password = istantanea ? (stato.sala.provaUscite.passwordDiProva ?? TestiCapsule.passwordDiProvaIstantanee)
                                  : GeneratorePassword.nuova(cliente: cliente)
        stato.sala.dettaglioValoreAperto = true
        let nuova = CapsulaAperta(id: id, testo: t, password: password, animata: animata)
        if animata {
            withAnimation(.easeOut(duration: M.velo)) { aperta = nuova }
        } else {
            aperta = nuova
        }
    }

    /// «Chiudi», Esc o il blocco: il velo sfuma e il testo si azzera.
    private func chiudiApertura() {
        guard aperta != nil else { return }
        stato.sala.dettaglioValoreAperto = false
        if calmo || istantanea {
            aperta = nil
        } else {
            withAnimation(.easeOut(duration: M.chiusura)) { aperta = nil }
        }
    }
}

#if os(macOS)
/// «Scrivi sull'iPad» accanto a «Sigilla» (giro 16, D-C4): osserva il tavolo e compare solo con l'iPad collegato. Durante
/// l'attesa: l'indicatore, «Giulia scrive sull'iPad…» e «Annulla». Il testo arrivato va a `arrivato` (il campo, come
/// bozza); qui non si sigilla nulla.
struct ScriviCapsulaSullIPad: View {
    @ObservedObject var tavolo: TavoloMac
    let cliente: Cliente
    /// «Si apre a marzo 2027», già con la maiuscola.
    let siApre: String
    let attivo: Bool
    @Binding var inAttesa: Bool
    let arrivato: (String) -> Void

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        let primo = TestiRealta.primoNome(cliente.nome)
        // Uno ZStack (non un Group): l'osservazione dell'attesa resta anche quando non c'è niente da mostrare
        ZStack(alignment: .leading) {
            if tavolo.collegato && tavolo.capsulaInAttesa {
                HStack(spacing: K.spazioAttesa) {
                    ProgressView().controlSize(.small)
                    Text(TestiRealta.attesaCapsula(primo))
                        .carattereApple(K.attesa)
                        .foregroundColor(K.coloreAttesa)
                        .lineLimit(1)
                    Button("Annulla") { tavolo.annullaTestoCapsula() }
                        .buttonStyle(.apple)
                        .help(TestiRealta.annullaAttesaCapsula)
                }
            } else if tavolo.collegato {
                Button { chiedi(primo: primo) } label: { Text(TestiRealta.scriviSullIPad) }
                    .buttonStyle(.apple)
                    .disabled(!attivo)
                    .help(TestiRealta.aiutoScriviSullIPad)
            }
        }
        .onChange(of: tavolo.capsulaInAttesa, initial: true) { _, attesa in inAttesa = attesa }
    }

    private func chiedi(primo: String) {
        let capsula = CapsulaTavolo(nome: primo, siApre: siApre, aiuto: TestiRealta.aiutoCapsula)
        tavolo.chiediTestoCapsula(ContestoTavolo(documento: nil, pagina: 0, clienteId: cliente.id), capsula: capsula) { testo in
            arrivato(testo)
        }
    }
}
#endif

/// «Si apre quando»: un obiettivo del cliente o una data.
enum SceltaAperturaCapsula: Hashable {
    case obiettivo(String)
    case data
}

/// I passi del sigillo animato.
struct PassiSigillo {
    var inCorso = false
    var testoVola = false
    var bustaVisibile = false
    var bustaEntrata = false
    var lemboChiuso = false
    var sigilloImpresso = false
    var bustaVola = false
}

/// La capsula aperta sul palco: il testo vive solo qui, in memoria.
struct CapsulaAperta: Equatable {
    let id: String
    let testo: String
    let password: String
    let animata: Bool
}

// MARK: - Chip

/// La chip di «Si apre quando»: scelta = fondo viola e testo bianco, senza bordo.
struct ChipCapsula: View {
    let titolo: String
    let scelta: Bool
    let azione: () -> Void

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        let forma = Capsule(style: .continuous)
        Button(action: azione) {
            Text(titolo)
                .carattereApple(K.chip)
                .foregroundColor(scelta ? K.testoChipScelto : K.testoChip)
                .lineLimit(1)
                .fixedSize()
                .padding(K.paddingChip)
                .background {
                    forma.fill(scelta ? K.colore : K.fondoChip)
                        .overlay { forma.strokeBorder(scelta ? Color.clear : K.bordoChip, lineWidth: K.spessoreBordo) }
                }
                .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .accessibilityAddTraits(scelta ? .isSelected : [])
    }
}

// MARK: - Busta e sigillo

/// La busta (carta calda, bordo, lembo che ruota sull'asse orizzontale) con il sigillo. Chiara anche nello scuro.
struct BustaCapsula: View {
    /// Il lembo chiuso (0°) o aperto (180°).
    let lemboChiuso: Bool
    let sigilloImpresso: Bool
    /// Arancio per la capsula pronta, viola mentre si sigilla.
    let pronta: Bool
    var sigilloRotto = false

    private typealias K = Tema.Apple.SalaRacconti.Capsula
    private typealias M = Tema.Apple.Moto.Capsula

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: K.raggioBusta, style: .continuous)
        ZStack(alignment: .top) {
            forma.fill(K.cartaBusta)
                .overlay(forma.strokeBorder(K.bordoBusta, lineWidth: K.spessoreBordoBusta))
            LemboBusta()
                .fill(K.lembo)
                .overlay(LemboBusta().stroke(K.bordoBusta, lineWidth: K.spessoreBordoBusta))
                .frame(height: K.busta.height * K.altezzaLembo)
                .rotation3DEffect(.degrees(lemboChiuso ? 0 : 180), axis: (x: 1, y: 0, z: 0), anchor: .top)
            SigilloCapsula(colore: pronta ? K.coloreSigilloPronta : K.colore)
                .scaleEffect(sigilloRotto ? K.scalaRottura : (sigilloImpresso ? 1 : M.scalaSigillo))
                .opacity(sigilloRotto ? 0 : (sigilloImpresso ? 1 : 0))
                .offset(y: K.busta.height * K.altezzaLembo - K.raggioSigillo)
        }
        .frame(width: K.busta.width, height: K.busta.height)
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }
}

/// Il lembo: un triangolo dal bordo alto della busta fino a poco oltre la metà.
private struct LemboBusta: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Il sigillo: un cerchio con il logo di Prisma bianco.
struct SigilloCapsula: View {
    let colore: Color

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        ZStack {
            Circle().fill(colore)
            LogoPrisma(colore: K.coloreLogoSigillo)
                .frame(width: K.logoSigillo, height: K.logoSigillo)
        }
        .frame(width: K.raggioSigillo * 2, height: K.raggioSigillo * 2)
    }
}

// MARK: - Righe e tile

/// Una riga dell'elenco: avatar, «Giulia Rossi · Anticipo casa», quando si apre e lo stato, il lucchetto (mai il testo).
struct RigaCapsula: View {
    let cliente: Cliente
    let titolo: String
    let dettaglio: String
    let avviso: Bool
    let chiusa: Bool
    let lampo: Bool

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(spacing: K.spazioRiga) {
            AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: K.avatarRiga)
            VStack(alignment: .leading, spacing: K.spazioTesti) {
                Text(titolo)
                    .carattereApple(K.nomeRiga)
                    .foregroundColor(K.coloreNomeRiga)
                    .lineLimit(1)
                Text(dettaglio)
                    .carattereApple(K.dettaglioRiga)
                    .foregroundColor(avviso ? K.coloreAvvisoRiga : K.coloreDettaglioRiga)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: chiusa ? "lock.fill" : "lock.open")
                .font(.system(size: K.lucchetto))
                .foregroundColor(K.coloreLucchetto)
                .accessibilityLabel(Text(chiusa ? "Sigillata" : "Aperta"))
        }
        .padding(.vertical, K.rigaVerticale)
        .padding(.horizontal, K.rigaOrizzontale)
        .background(RoundedRectangle(cornerRadius: K.raggioLampo, style: .continuous).fill(K.colore.opacity(lampo ? K.opacitaLampo : 0)))
        .overlay(alignment: .bottom) {
            Rectangle().fill(K.filetto).frame(height: K.spessoreFiletto)
        }
        .contentShape(Rectangle())
    }
}

/// La tile della capsula pronta: bordo e fondo arancio, pulsazione dell'alone (ferma con Riduci movimento e nelle
/// istantanee), «Apri e consegna».
struct TileCapsulaPronta: View {
    let capsula: CapsulaTempo
    let cliente: Cliente
    let titolo: String
    let perche: String
    let attiva: Bool
    let apri: () -> Void

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    @State private var pulsa = false

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        let _ = ContaCorpi.segna()
        let forma = RoundedRectangle(cornerRadius: K.raggioPronta, style: .continuous)
        HStack(spacing: K.spazioPronta) {
            AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: K.avatarPronta)
            VStack(alignment: .leading, spacing: K.spazioTesti) {
                Text(titolo)
                    .carattereApple(K.nomePronta)
                    .foregroundColor(K.coloreNomeRiga)
                    .lineLimit(1)
                Text(perche)
                    .carattereApple(K.perchePronta)
                    .foregroundColor(K.colorePerchePronta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button(TestiCapsule.apriEConsegna, action: apri)
                .buttonStyle(.applePrimario)
                .disabled(!attiva || istantanea)
        }
        .padding(K.paddingPronta)
        .background(forma.fill(K.coloreSigilloPronta.opacity(K.opacitaFondoPronta)))
        .overlay(forma.strokeBorder(K.coloreSigilloPronta.opacity(K.opacitaBordoPronta), lineWidth: K.spessoreBordoPronta))
        .background(
            forma.stroke(K.coloreSigilloPronta.opacity(K.opacitaAlonePronta), lineWidth: pulsa ? K.alonePronta * 2 : 0)
        )
        .onAppear {
            guard !istantanea, !calmo else { return }
            withAnimation(.easeInOut(duration: Tema.Apple.Moto.Capsula.pulsazione / 2).repeatForever(autoreverses: true)) {
                pulsa = true
            }
        }
    }
}

// MARK: - Apertura

/// La consegna: il velo, la busta arancio che si apre, la lettera che sale con il testo due parole alla volta; sotto
/// «Stampala su carta per …», «Condividi…» (PDF protetto) e «Chiudi» (anche Esc).
struct AperturaCapsula: View {
    @Environment(StatoShell.self) var stato
    let capsula: CapsulaTempo
    let testo: String
    let password: String
    let cliente: Cliente
    let modificabile: Bool
    let chiudi: () -> Void

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    @State private var rotto = false
    @State private var lemboAperto = false
    @State private var letteraSu = false
    @State private var bustaVia = false
    @State private var scrive = false

    private typealias K = Tema.Apple.SalaRacconti.Capsula
    private typealias M = Tema.Apple.Moto.Capsula

    var body: some View {
        let _ = ContaCorpi.segna()
        let fermo = istantanea || calmo
        let nome = StatoShell.nomeBreve(cliente)
        ZStack {
            Rectangle()
                .fill(K.velo)
                .ignoresSafeArea()
                .onTapGesture {}
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    if !(bustaVia || fermo) {
                        BustaCapsula(lemboChiuso: !lemboAperto, sigilloImpresso: true, pronta: true, sigilloRotto: rotto)
                            .offset(y: K.partenzaLettera)
                            .transition(.opacity)
                    }
                    foglio(animato: !fermo)
                        .offset(y: (letteraSu || fermo) ? 0 : K.partenzaLettera)
                        .opacity((letteraSu || fermo) ? 1 : 0)
                }
                .frame(width: K.palcoApertura.width)
                .frame(minHeight: K.palcoApertura.height)
                Spacer(minLength: K.sottoFoglio)
                pulsanti(nome: nome)
                    .padding(.bottom, K.pulsantiFondo)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { avvia(fermo: fermo) }
    }

    private func foglio(animato: Bool) -> some View {
        VStack(alignment: .leading, spacing: K.sottoSopratitolo) {
            Text(TestiCapsule.sopratitolo(capsula.sigillataIl))
                .carattereApple(K.sopratitolo)
                .foregroundColor(K.coloreSopratitolo)
            Group {
                if animato {
                    if scrive {
                        TestoProgressivo(testo: testo, passo: M.passoParola)
                    } else {
                        Text(" ")
                    }
                } else {
                    Text(testo)
                }
            }
            .carattereApple(K.testoFoglio)
            .foregroundColor(K.inchiostroFoglio)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(maxHeight: K.altezzaMassimaTesto, alignment: .topLeading)
        }
        .padding(K.paddingFoglio)
        .frame(width: K.larghezzaFoglio, alignment: .topLeading)
        .frame(minHeight: K.altezzaFoglio, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: K.raggioFoglio, style: .continuous)
                .fill(K.cartaFoglio)
                .ombraApple(K.ombraFoglio)
        )
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func pulsanti(nome: String) -> some View {
        VStack(spacing: K.spazioPulsanti) {
            HStack(spacing: K.spazioPulsanti) {
                if modificabile {
                    Button(TestiCapsule.stampa(nome: nome)) { stampa() }
                        .buttonStyle(.applePrimarioGrande)
                        .disabled(istantanea)
                    PulsanteCondividi(titolo: TestiCapsule.condividi, consensoWhatsApp: cliente.consensi.whatsapp == true,
                                      prepara: { pdfProtetto() }, esito: { e in dopoCondivisione(e) })
                        .disabled(istantanea)
                }
                Button(TestiCapsule.chiudi) { chiudi() }
                    .buttonStyle(.appleGrande)
                    .keyboardShortcut(.cancelAction)
            }
            if modificabile {
                Text(TestiCapsule.notaPassword(password: password, primaVolta: stato.primaUscita(clienteId: cliente.id), nome: nome))
                    .carattereApple(K.aiutoChiave)
                    .foregroundColor(K.coloreNota)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: K.palcoApertura.width)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: Movimento

    private func avvia(fermo: Bool) {
        guard !fermo else {
            rotto = true
            lemboAperto = true
            letteraSu = true
            bustaVia = true
            scrive = true
            return
        }
        Movimenti.dopo(M.ritardoRottura) {
            withAnimation(.easeOut(duration: M.rottura)) { rotto = true }
        }
        Movimenti.dopo(M.ritardoLemboApre) {
            withAnimation(M.curvaLembo.animazione(M.lembo)) { lemboAperto = true }
        }
        Movimenti.dopo(M.ritardoLettera) {
            withAnimation(M.curvaRiga.animazione(M.lettera)) { letteraSu = true }
        }
        Movimenti.dopo(M.ritardoSvanisce) {
            withAnimation(.easeOut(duration: M.svanisce)) { bustaVia = true }
        }
        Movimenti.dopo(M.ritardoTesto) { scrive = true }
    }

    // MARK: Consegna

    @MainActor
    private func stampa() {
        guard let pdf = stato.pdfCapsula(capsula, testo: testo) else { return }
        StampaCarta.stampa(pdf, formato: Misure.Documento.prospetto)
        stato.segnaCapsulaConsegnata(capsula.id)
        stato.mostraAvviso(TestiCapsule.toastStampata)
    }

    /// Il PDF protetto con la password nuova, nella cartella temporanea delle uscite (mai in Download).
    @MainActor
    private func pdfProtetto() -> [URL]? {
        guard let chiaro = stato.pdfCapsula(capsula, testo: testo),
              let protetto = StampaCarta.protetto(chiaro, password: password),
              let url = try? CartellaUscite.scrivi(protetto, nome: TestiCapsule.nomeFile(nome: StatoShell.nomeBreve(cliente))) else {
            stato.mostraAvviso("Non riesco a preparare il PDF protetto della capsula")
            return nil
        }
        return [url]
    }

    private func dopoCondivisione(_ e: EsitoCondivisione) {
        switch e {
        case .condiviso(let via):
            stato.registraUscita(clienteId: cliente.id, genere: .capsula, descrizione: TestiCapsule.descrizioneUscita,
                                 via: via, documentoId: nil, protetto: true)
            stato.segnaCapsulaConsegnata(capsula.id)
            stato.mostraAvviso("Il PDF protetto è uscito dal foglio di condivisione: lo hai mandato tu")
        case .annullato:
            break
        case .nonRiuscito(let motivo):
            stato.mostraAvviso(motivo)
        }
    }
}

// MARK: - Cambia quando si apre

/// Il modulo «Cambia quando si apre»: un obiettivo del cliente o una data.
struct ModuloAperturaCapsula: View {
    let capsula: CapsulaTempo
    let obiettivi: [Obiettivo]
    let salva: (CapsulaTempo.Apertura) -> Void

    @Environment(\.dismiss) private var chiudi
    @State private var scelta: SceltaAperturaCapsula = .data
    @State private var data = Date()

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        VStack(alignment: .leading, spacing: K.sopraEtichetta) {
            Text(TestiCapsule.cambiaQuando)
                .carattereApple(Tema.Apple.Carattere.titoloFinestra)
            HStack(spacing: K.spazioChip) {
                ForEach(obiettivi) { o in
                    ChipCapsula(titolo: o.titolo, scelta: scelta == .obiettivo(o.id)) { scelta = .obiettivo(o.id) }
                }
                ChipCapsula(titolo: TestiCapsule.inUnaData, scelta: scelta == .data) { scelta = .data }
            }
            if scelta == .data {
                DatePicker("Si apre il", selection: $data, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .fixedSize()
            }
            HStack {
                Spacer()
                Button("Annulla") { chiudi() }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button("Salva") {
                    switch scelta {
                    case .obiettivo(let id): salva(.obiettivo(id: id))
                    case .data: salva(.data(Calendar.current.startOfDay(for: data)))
                    }
                    chiudi()
                }
                .buttonStyle(.applePrimario)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(K.paddingPronta * 1.5)
        .frame(width: K.palcoApertura.width)
        .onAppear {
            switch capsula.apertura {
            case .obiettivo(let id):
                scelta = obiettivi.contains(where: { $0.id == id }) ? .obiettivo(id) : .data
            case .data(let d):
                scelta = .data
                data = d
            }
        }
    }
}

// MARK: - PDF

/// La pagina A4 della capsula aperta: carta bianca, sopratitolo «SIGILLATA A …», il testo, il nome del cliente e il
/// piede «Aperta il … · Prisma».
enum PaginaCapsula {
    @MainActor
    static func documento(testo: String, sigillataIl: Date, apertaIl: Date, cliente: String) -> DocumentoStampabile {
        let formato = Misure.Documento.prospetto
        let pagina = FoglioCapsulaCarta(testo: testo, sigillataIl: sigillataIl, apertaIl: apertaIl, cliente: cliente)
            .padding(Misure.Documento.margineProspetto)
            .frame(width: formato.width, height: formato.height)
            .background(Tema.Apple.Carta.fondo)
        return DocumentoStampabile(titolo: "La capsula del tempo", cliente: cliente, genere: "Capsula", formato: formato,
                                   pagine: [AnyView(pagina)], tipo: .altro)
    }
}

/// Il foglio della capsula su carta bianca (colori fissi della carta, niente vetro né ombre).
struct FoglioCapsulaCarta: View {
    let testo: String
    let sigillataIl: Date
    let apertaIl: Date
    let cliente: String

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        VStack(alignment: .leading, spacing: K.spazioCarta) {
            Text(TestiCapsule.sopratitolo(sigillataIl))
                .carattereApple(K.sopratitoloCarta)
                .foregroundColor(K.coloreSopratitoloCarta)
            Text(cliente)
                .carattereApple(K.nomeCarta)
                .foregroundColor(K.coloreNomeCarta)
            Text(testo)
                .carattereApple(K.testoCarta)
                .foregroundColor(K.coloreTestoCarta)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            Rectangle().fill(K.filettoCarta).frame(height: K.spessoreFiletto)
            Text(TestiCapsule.piede(apertaIl: apertaIl))
                .carattereApple(K.piedeCarta)
                .foregroundColor(K.colorePiedeCarta)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .light)
    }
}
