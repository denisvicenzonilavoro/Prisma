import SwiftUI

// Pratiche › Proposta, «La proposta si costruisce da sola» (Design/template-luce-specifica.md §7.1, «Luce» giro 3).
// A sinistra la barra «Bisogni scoperti dall'analisi», a destra la colonna del bisogno scelto: testata con
// «✦ Costruisci la proposta», i cinque riquadri che si accendono uno alla volta (il prodotto, l'importo, il prospetto,
// l'adeguatezza, i moduli) e il riquadro finale «Proposta pronta». I conti li fa MotoreProposta, lo stato sta in
// StatoPraticheProposta; qui solo le viste, con i valori di Tema.Apple.Pratiche.

struct PratichePropostaApple: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoPraticheProposta(stato: stato, proposta: stato.praticheProposta)
    }
}

private struct CorpoPraticheProposta: View {
    let stato: StatoShell
    let proposta: StatoPraticheProposta

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        if stato.dati.clienti.isEmpty {
            VuotoPratiche(glifo: .proposta, frase: "Aggiungi un cliente per iniziare",
                          nota: "Le proposte nascono dai bisogni che le analisi dei tuoi clienti scoprono.",
                          pulsante: "Apri Clienti") { stato.apri(.clienti) }
        } else {
            let bisogni = stato.bisogniProposta()
            let scelto = stato.bisognoSceltoProposta(bisogni)
            HStack(alignment: .top, spacing: P.spazioLaterale) {
                barra(bisogni, scelto: scelto)
                    .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                Group {
                    if let scelto {
                        ColonnaProposta(stato: stato, vista: stato.vistaProposta(scelto))
                            .id(scelto.id)
                            .transition(.asymmetric(insertion: .opacity,
                                                    removal: .opacity.combined(with: .offset(y: P.Moto.spostamentoCambio))))
                    } else {
                        VuotoPratiche(glifo: .proposta, frase: "Niente da costruire, per ora.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            .animation(Tema.Apple.Moto.animazione(P.Moto.cambio, calmo: calmo, istantanea: istantanea), value: scelto?.id)
            // I modelli di Pratiche › Moduli per la tappa 5 (si leggono una volta, mai dentro il body)
            .onAppear { stato.moduli.carica() }
            .onDisappear { proposta.fermaSequenza() }
        }
    }

    @ViewBuilder private func barra(_ bisogni: [BisognoScoperto], scelto: BisognoScoperto?) -> some View {
        BarraLateralePratiche(titolo: "Bisogni scoperti dall'analisi") {
            if bisogni.isEmpty {
                Text("Nessun bisogno scoperto. Le analisi dei clienti sono in ordine o hanno già una proposta aperta.")
                    .carattereApple(P.motivoVoce)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(P.paddingVoce)
            } else {
                ForEach(bisogni) { b in
                    VoceLateralePratiche(titolo: b.titolo, sottotitolo: b.motivo, scelta: b.id == scelto?.id,
                                         azione: { stato.scegliBisognoProposta(b.id) }) {
                        avatar(b.clienteId, lato: P.avatarVoce)
                    }
                }
            }
        }
    }

    @ViewBuilder private func avatar(_ id: String, lato: CGFloat) -> some View {
        if let c = stato.cliente(id) {
            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: lato)
        } else {
            Circle().fill(Tema.Apple.Colore.chip).frame(width: lato, height: lato)
        }
    }
}

// MARK: - La colonna del bisogno

private struct ColonnaProposta: View {
    let stato: StatoShell
    let vista: VistaProposta

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias P = Tema.Apple.Pratiche
    private typealias Q = Tema.Apple.Pratiche.Proposta

    private var cliente: Cliente? { stato.cliente(vista.bisogno.clienteId) }
    private var nomeCompleto: String { cliente?.nome ?? "il cliente" }
    private var nome: String { MotoreProposta.primoNome(nomeCompleto) }
    private var animato: Bool { !(calmo || istantanea) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            testata
            GeometryReader { g in
                let unaRiga = g.size.width >= Q.larghezzaUnaRiga
                VStack(alignment: .leading, spacing: Q.distanzaFine) {
                    passi(unaRiga: unaRiga)
                    if vista.pronta {
                        RiquadroPropostaPronta(nomeCompleto: nomeCompleto, nome: nome,
                                               riepilogo: vista.costruita.map(MotoreProposta.riepilogo) ?? MotoreProposta.riepilogoPronta,
                                               presenta: presenta, fascicolo: nelFascicolo)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: P.Moto.Pronta.spostamento)),
                                                    removal: .opacity))
                    }
                }
                .animation(Tema.Apple.Moto.animazione(P.Moto.Pronta.animazione, calmo: calmo, istantanea: istantanea),
                           value: vista.pronta)
            }
            .padding(.top, Q.distanzaLinea)
        }
    }

    // MARK: Testata

    private var testata: some View {
        HStack(alignment: .center, spacing: P.spazioTestata) {
            if let c = cliente {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: P.avatarTestata)
            }
            VStack(alignment: .leading, spacing: P.spazioSopraTitolo) {
                Text("Per \(nomeCompleto)")
                    .carattereApple(P.sopraTitolo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                Text(vista.bisogno.titolo)
                    .carattereApple(P.titolo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: P.spazioTestata)
            pulsanteTestata
        }
    }

    @ViewBuilder private var pulsanteTestata: some View {
        let rosso: Bool = {
            if case .bloccato? = vista.costruita?.adeguatezza { return vista.accesi >= 4 }
            return false
        }()
        if vista.inCorso {
            Button("Costruisco…") {}
                .buttonStyle(.applePrimarioGrande)
                .disabled(true)
        } else if let bozza = vista.bozza, vista.costruita != nil, vista.bozza?.prodottoId != nil {
            Button(rosso ? "Rivedi la proposta" : "Apri in Posizioni") { stato.apriPosizione(bozza) }
                .buttonStyle(.applePrimarioGrande)
        } else {
            Button("✦ Costruisci la proposta") { stato.costruisciProposta(vista.bisogno, animato: animato) }
                .buttonStyle(.applePrimarioGrande)
        }
    }

    // MARK: I cinque passi

    private static let etichette = ["Il prodotto", "L'importo", "Il prospetto", "L'adeguatezza", "I moduli"]

    @ViewBuilder private func passi(unaRiga: Bool) -> some View {
        let colonne = Array(repeating: GridItem(.flexible(), spacing: Q.spazioPassi, alignment: .top),
                            count: unaRiga ? 5 : Q.colonneStrette)
        LazyVGrid(columns: colonne, alignment: .leading, spacing: Q.spazioPassi) {
            ForEach(0..<5, id: \.self) { i in
                RiquadroPassoProposta(numero: i + 1, etichetta: Self.etichette[i], aspetto: aspetto(i)) {
                    contenuto(i)
                }
            }
        }
    }

    /// L'aspetto del riquadro i: spento finché la sequenza non ci arriva, poi secondo l'esito della tappa.
    private func aspetto(_ i: Int) -> AspettoPasso {
        guard let r = vista.costruita, i < vista.accesi else { return .spento }
        switch i {
        case 0: return aspetto(r.prodotto)
        case 1: return r.importo.map(aspetto) ?? .spento
        case 2: return r.prospetto.map(aspetto) ?? .spento
        case 3: return r.adeguatezza.map(aspetto) ?? .spento
        default: return r.moduli.map(aspetto) ?? .spento
        }
    }

    private func aspetto<T>(_ e: EsitoPasso<T>) -> AspettoPasso {
        switch e {
        case .fatto: return .acceso
        case .daScegliere: return .scelta
        case .manca: return .fermo
        case .bloccato: return .rosso
        case .inArrivo: return .neutro
        }
    }

    @ViewBuilder private func contenuto(_ i: Int) -> some View {
        if let r = vista.costruita, i < vista.accesi {
            switch i {
            case 0: passoProdotto(r.prodotto)
            case 1: r.importo.map { passoImporto($0) }
            case 2: r.prospetto.map { passoProspetto($0) }
            case 3: r.adeguatezza.map { passoAdeguatezza($0) }
            default: r.moduli.map { passoModuli($0) }
            }
        }
    }

    // MARK: Contenuti

    @ViewBuilder private func passoProdotto(_ e: EsitoPasso<Prodotto>) -> some View {
        switch e {
        case .fatto(let p):
            VStack(alignment: .leading, spacing: Q.spazioDentro) {
                TasselloGlifo(glifo: .proposta, lato: Q.tassello)
                Text(p.nome)
                    .carattereApple(Q.nomeProdotto)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                EtichettaCanale(canale: p.canale, compatta: true)
                if MotoreProposta.diProva(p) { EtichettaDatiDiProvaPratiche() }
            }
        case .daScegliere(let prodotti):
            VStack(alignment: .leading, spacing: Q.spazioScelta) {
                Text("Più prodotti adatti: scegli quello da proporre.")
                    .carattereApple(Q.frase)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(prodotti) { p in
                    Button {
                        stato.scegliProdottoProposta(vista.bisogno, prodotto: p.id, animato: animato)
                    } label: {
                        VStack(alignment: .leading, spacing: Q.spazioRighe) {
                            Text(p.nome)
                                .carattereApple(Q.nomeScelta)
                                .foregroundColor(Tema.Apple.Colore.inchiostro)
                                .fixedSize(horizontal: false, vertical: true)
                            EtichettaCanale(canale: p.canale, compatta: true)
                        }
                        .padding(Q.rigaScelta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Q.raggioScelta, style: .continuous).fill(Q.fondoScelta))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StileSemplice())
                }
            }
        case .manca(let frase, let rimedio):
            fermo(frase, rimedio: rimedio)
        case .bloccato(let frase):
            Text(frase).carattereApple(Q.frase).foregroundColor(Q.anelloRosso)
        case .inArrivo(let frase):
            Text(frase).carattereApple(Q.frase).foregroundColor(Tema.Apple.Colore.inchiostro2)
        }
    }

    @ViewBuilder private func passoImporto(_ e: EsitoPasso<ImportoProposta>) -> some View {
        switch e {
        case .fatto(let v):
            VStack(alignment: .leading, spacing: Q.spazioRighe) {
                NumeroCheConta(v.cifra)
                    .carattereApple(Q.importo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(v.spiegazione)
                    .carattereApple(Q.spiegazione)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(v.riga)
                    .carattereApple(Q.rigaPremio)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Q.spazioPremio)
            }
            .contentShape(Rectangle())
            .onTapGesture { if let b = vista.bozza { stato.apriPosizione(b) } }
        case .manca(let frase, let rimedio):
            fermo(frase, rimedio: rimedio)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func passoProspetto(_ e: EsitoPasso<ProspettoProposta>) -> some View {
        switch e {
        case .fatto(let v):
            VStack(alignment: .leading, spacing: Q.spazioDentro) {
                MiniaturaProspettoProposta()
                Text("\(v.pagine) \(v.pagine == 1 ? "pagina" : "pagine") · " + (v.attualeId != nil ? "restare o cambiare" : "su carta bianca"))
                    .carattereApple(Q.spiegazione)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            .contentShape(Rectangle())
            .onTapGesture { if let b = vista.bozza { stato.apriProspettoProposta(b, prospetto: v) } }
        case .manca(let frase, let rimedio):
            fermo(frase, rimedio: rimedio)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func passoAdeguatezza(_ e: EsitoPasso<AdeguatezzaProposta>) -> some View {
        switch e {
        case .fatto(let a):
            VStack(alignment: .leading, spacing: Q.spazioDentro) {
                Anello(frazione: 1, colore: colore(a.semaforo), misura: Q.anello, spessore: Q.spessoreAnello,
                       ritardo: P.Moto.ritardoAnello) {
                    if a.semaforo == .verde || a.semaforo == nil {
                        SpuntaDisegnata(disegnata: true, lato: Q.spunta)
                    } else {
                        Text("!").carattereApple(Q.importo).foregroundColor(colore(a.semaforo))
                    }
                }
                Text(a.titolo)
                    .carattereApple(Q.esitoAdeguatezza)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text(a.dettaglio)
                    .carattereApple(Q.dettaglio)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
            // La scheda di adeguatezza (PannelloAdeguatezza) nel dettaglio della proposta; la liquidità non ne ha
            .onTapGesture {
                guard let b = vista.bozza else { return }
                if a.semaforo == nil { stato.apriPosizione(b) } else { stato.apriAdeguatezzaProposta(b) }
            }
        case .bloccato(let frase):
            VStack(alignment: .leading, spacing: Q.spazioDentro) {
                Anello(frazione: 1, colore: Q.anelloRosso, misura: Q.anello, spessore: Q.spessoreAnello,
                       ritardo: P.Moto.ritardoAnello) {
                    Text("✕").carattereApple(Q.importo).foregroundColor(Q.anelloRosso)
                }
                Text(frase)
                    .carattereApple(Q.dettaglio)
                    .foregroundColor(Q.anelloRosso)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .manca(let frase, let rimedio):
            fermo(frase, rimedio: rimedio)
        default:
            EmptyView()
        }
    }

    /// I moduli della proposta, ognuno con «N campi compilati · M da chiedere»; senza modelli (o per Alleanza) la frase.
    /// Un clic apre Pratiche › Moduli sul primo modulo della proposta.
    @ViewBuilder private func passoModuli(_ e: EsitoPasso<[ModuloProposta]>) -> some View {
        switch e {
        case .fatto(let elenco):
            VStack(alignment: .leading, spacing: Q.spazioModuli) {
                ForEach(Array(elenco.enumerated()), id: \.element.id) { i, m in
                    RigaModuloProposta(modulo: m, indice: i)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if let b = vista.bozza { stato.apriModuliProposta(b, modulo: elenco.first?.modelloId) } }
            .accessibilityAddTraits(.isButton)
        case .inArrivo(let frase):
            VStack(alignment: .leading, spacing: Q.spazioDentro) {
                TasselloGlifo(glifo: .modulo, lato: Q.tassello)
                Text(frase)
                    .carattereApple(Q.frase)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
            .onTapGesture { if let b = vista.bozza { stato.apriModuliProposta(b, modulo: nil) } }
        default:
            EmptyView()
        }
    }

    /// Il passo fermo: la frase arancio e «Rimedia».
    private func fermo(_ frase: String, rimedio: RimedioPasso) -> some View {
        VStack(alignment: .leading, spacing: Q.spazioDentro) {
            Text(frase)
                .carattereApple(Q.frase)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Button("Rimedia") { stato.rimediaProposta(rimedio, bisogno: vista.bisogno, bozza: vista.bozza) }
                .buttonStyle(.apple)
        }
    }

    private func colore(_ s: Semaforo?) -> Color {
        switch s {
        case .verde?, nil: return Q.anelloVerde
        case .giallo?: return Q.anelloGiallo
        case .rosso?: return Q.anelloRosso
        case .grigio?: return Q.anelloNeutro
        }
    }

    // MARK: Azioni del riquadro finale

    private func presenta() {
        if let b = vista.bozza { stato.presentaProposta(b, prospetto: vista.costruita?.prospetto?.valore) }
    }

    private func nelFascicolo() {
        let b = vista.bisogno
        stato.clienteAttivoId = b.clienteId
        let adesso = Date()
        let prossimo = stato.appuntamentiCliente(b.clienteId).filter { $0.inizio > adesso }.min { $0.inizio < $1.inizio }
        if let a = prossimo {
            stato.sceltaFascicolo = TipoProspetto.perIncontro(a, posizione: vista.bozza)
            stato.fascicoloAppuntamento = a.id
        } else {
            stato.fascicoloAppuntamento = nil
        }
        switch b.area {
        case .protezione: stato.sceltaFascicolo.insert(.protezione)
        case .previdenza: stato.sceltaFascicolo.insert(.previdenza)
        case .liquidita: stato.sceltaFascicolo.insert(.liquidita)
        default: break
        }
        stato.apriProspetto(.fascicolo)
        stato.mostraAvviso(prossimo != nil ? "Aggiunta al fascicolo del prossimo incontro."
                                           : "Nessun incontro fissato con \(nomeCompleto): il fascicolo è pronto in Prospetti.")
    }
}

// MARK: - Un modulo della proposta

/// Una riga dei moduli (`.prep`): il pallino con la spunta che diventa verde, il nome e «N campi compilati».
private struct RigaModuloProposta: View {
    let modulo: ModuloProposta
    let indice: Int

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var accesa = false

    private typealias Q = Tema.Apple.Pratiche.Proposta

    var body: some View {
        let acceso = accesa || fermo
        HStack(alignment: .top, spacing: Q.spazioPallino) {
            ZStack {
                Circle().fill(acceso ? Q.pallinoAcceso : Color.clear)
                Circle().strokeBorder(acceso ? Q.pallinoAcceso : Q.pallinoSpento, lineWidth: Q.bordoPallinoModulo)
                SpuntaPiccolaApple()
                    .stroke(Q.spuntaModulo, style: StrokeStyle(lineWidth: Q.trattoSpuntaModulo, lineCap: .butt, lineJoin: .miter))
                    .opacity(acceso ? 1 : 0)
            }
            .frame(width: Q.pallinoModulo, height: Q.pallinoModulo)
            VStack(alignment: .leading, spacing: Q.spazioRighe) {
                Text(modulo.titolo)
                    .carattereApple(Q.nomeModulo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                Text(modulo.riga)
                    .carattereApple(Q.rigaModulo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
        }
        .accessibilityElement(children: .combine)
        // Le spunte diventano verdi una dopo l'altra (Pratiche.Moto.Spunte); ferme nelle istantanee e con «Riduci movimento»
        .onAppear {
            guard !fermo else { return }
            let m = Tema.Apple.Pratiche.Moto.self
            withAnimation(m.animazioneSpunta.delay(m.ritardoSpunta(indice))) { accesa = true }
        }
    }
}

// MARK: - Il riquadro di un passo

/// Come appare un riquadro: spento (tratteggiato), acceso, fermo (arancio), da scegliere, non adeguato (rosso),
/// neutro (la tappa arriva più avanti).
enum AspettoPasso: Equatable {
    case spento, acceso, scelta, fermo, rosso, neutro

    var spento: Bool { self == .spento }
}

/// Un riquadro della linea dei passi: alto 320, raggio 20, padding 16; in alto il tondo col numero e l'etichetta.
/// Spento: bordo tratteggiato, vuoto, opacità 0,7. Acceso: fondo `cardPiena`, bordo, ombra, tondo verde scala 1,1; il
/// contenuto sale da 12 con scala 0,97. Riusabile per i passi dei sinistri.
struct RiquadroPassoProposta<Contenuto: View>: View {
    let numero: Int
    let etichetta: String
    let aspetto: AspettoPasso
    @ViewBuilder let contenuto: () -> Contenuto

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias Q = Tema.Apple.Pratiche.Proposta
    private typealias M = Tema.Apple.Pratiche.Moto

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Q.raggioPasso, style: .continuous)
        VStack(alignment: .leading, spacing: Q.spazioDentro) {
            HStack(spacing: Q.spazioNumero) {
                Text("\(numero)")
                    .carattereApple(Q.cifra)
                    .foregroundColor(aspetto.spento ? Tema.Apple.Colore.inchiostro2 : Q.cifraAccesa)
                    .frame(width: Q.numero, height: Q.numero)
                    .background(Circle().fill(fondoNumero))
                    .scaleEffect(aspetto == .acceso ? Q.scalaNumeroAcceso : 1)
                    .animation(Tema.Apple.Moto.animazione(M.numero, calmo: calmo, istantanea: istantanea), value: aspetto)
                Text(etichetta)
                    .carattereApple(Q.etichetta)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            if !aspetto.spento {
                contenuto()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.asymmetric(insertion: .offset(y: M.Passo.spostamento)
                                                .combined(with: .scale(scale: M.Passo.scala, anchor: .top))
                                                .combined(with: .opacity),
                                            removal: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(Q.paddingPasso)
        .frame(maxWidth: .infinity, minHeight: Q.altezzaPasso, maxHeight: Q.altezzaPasso, alignment: .topLeading)
        .background { fondo(forma) }
        .overlay { bordo(forma) }
        .opacity(aspetto.spento ? Q.opacitaSpento : 1)
        .animation(Tema.Apple.Moto.animazione(M.Passo.accensione, calmo: calmo, istantanea: istantanea), value: aspetto)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(numero). \(etichetta)"))
    }

    private var fondoNumero: Color {
        switch aspetto {
        case .spento: return Q.fondoNumero
        case .acceso, .neutro, .scelta: return Q.fondoNumeroAcceso
        case .fermo: return Q.fondoNumeroFermo
        case .rosso: return Q.fondoNumeroRosso
        }
    }

    @ViewBuilder private func fondo(_ forma: RoundedRectangle) -> some View {
        switch aspetto {
        case .spento: Color.clear
        case .acceso, .neutro, .scelta: forma.fill(Q.fondoAcceso).ombraApple(.card)
        case .fermo: forma.fill(Q.fondoFermo)
        case .rosso: forma.fill(Q.fondoRosso)
        }
    }

    @ViewBuilder private func bordo(_ forma: RoundedRectangle) -> some View {
        switch aspetto {
        case .spento:
            forma.strokeBorder(Q.coloreSpento, style: StrokeStyle(lineWidth: Q.trattoSpento, dash: Q.tratteggio))
        case .acceso, .neutro, .scelta:
            forma.strokeBorder(Q.bordoAcceso, lineWidth: Tema.Apple.Misura.bordo)
        case .fermo:
            forma.strokeBorder(Q.bordoFermo, lineWidth: Tema.Apple.Misura.bordo)
        case .rosso:
            forma.strokeBorder(Q.bordoRosso, lineWidth: Tema.Apple.Misura.bordo)
        }
    }
}

// MARK: - La miniatura del prospetto

/// Il prospetto in miniatura: carta bianca (anche in scuro), quattro righe e il grafico che si disegna.
struct MiniaturaProspettoProposta: View {
    private typealias N = Tema.Apple.Pratiche.Proposta.Miniatura

    var body: some View {
        let larghezzaUtile = N.larghezza - 2 * N.padding
        VStack(alignment: .leading, spacing: N.spazioRighe) {
            riga(N.larghezze[0], larghezzaUtile)
            riga(N.larghezze[1], larghezzaUtile)
            TracciatoGrafico(punti: N.linea, colore: N.coloreLinea, spessore: N.tratto, ritardo: Tema.Apple.Pratiche.Moto.ritardoLinea)
                .frame(width: N.grafico.width, height: N.grafico.height)
            riga(N.larghezze[2], larghezzaUtile)
            riga(N.larghezze[3], larghezzaUtile)
        }
        .padding(N.padding)
        .frame(width: N.larghezza, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: N.raggio, style: .continuous).fill(N.fondo)
                        .shadow(color: N.ombra, radius: N.ombraRaggio, x: 0, y: N.ombraY))
        .accessibilityHidden(true)
    }

    private func riga(_ quota: CGFloat, _ larghezza: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: N.raggioRiga, style: .continuous)
            .fill(N.coloreRiga)
            .frame(width: larghezza * quota, height: N.riga)
    }
}

// MARK: - Il riquadro finale

/// «Proposta pronta»: la spunta verde, il titolo, la frase e i due pulsanti. Mai i secondi.
private struct RiquadroPropostaPronta: View {
    let nomeCompleto: String
    let nome: String
    let riepilogo: String
    let presenta: () -> Void
    let fascicolo: () -> Void

    private typealias Q = Tema.Apple.Pratiche.Proposta

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Q.raggioPronta, style: .continuous)
        HStack(spacing: Q.spazioPronta) {
            SpuntaDisegnata(disegnata: true, lato: Q.spuntaPronta)
            VStack(alignment: .leading, spacing: Q.spazioRighe) {
                Text("Proposta pronta")
                    .carattereApple(Q.titoloPronta)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text("Per \(nomeCompleto): \(riepilogo)")
                    .carattereApple(Q.testoPronta)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Q.spazioPronta)
            Button("Presenta a \(nome)", action: presenta)
                .buttonStyle(.applePrimarioGrande)
            Button("Nel fascicolo", action: fascicolo)
                .buttonStyle(.appleGrande)
        }
        .padding(Q.paddingPronta)
        .background(forma.fill(Q.fondoPronta))
        .overlay(forma.strokeBorder(Q.bordoPronta, lineWidth: Tema.Apple.Misura.bordo))
        .accessibilityElement(children: .contain)
    }
}
