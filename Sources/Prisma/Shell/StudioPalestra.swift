#if os(macOS)
import AppKit
#endif
import SwiftUI

// Studio › Palestra, la palestra della trattativa (Design/template-luce-specifica.md §5.3, «Luce» giro 5; template
// righe 1729-1757):
//
//   ┌ LA PALESTRA DELLA TRATTATIVA ─┐ ┌──────────────────────────────────────────────────────────┐
//   │ (GR) Giulia Rossi  Allenati… │ │ (GR) Giulia · recitata da Vera                            │
//   │      Vera nei panni di Giulia│ │      ( Mi piace l'idea, ma… restano bloccati? )           │
//   │ ┌ Chi è · I suoi timori ┐    │ │                         ( Guardiamo insieme la linea… )   │
//   │ └ L'obiettivo ──────────┘    │ │                       ✓ Ottima: hai usato Prisma per…     │
//   │ DIFFICOLTÀ  Facile·Realistica│ │ RISPONDI  (A) …  (B) …  (C) …                             │
//   │ Obiezione 1 di 3  ▬▬▬───────│ │ ( Oppure rispondi a parole tue…              🎙  ↑ )      │
//   │ Vera recita il cliente…      │ └──────────────────────────────────────────────────────────┘
//   └──────────────────────────────┘
//
// - Vera recita il cliente scelto (quello attivo della shell, un altro dal menu «Allenati con…», o un profilo
//   inventato) con le cifre preparate da Prisma (PalestraVera); un'obiezione alla volta, tre in tutto; il consulente
//   risponde con A/B/C (o 1/2/3, A/B/C sulla tastiera quando il campo non ha il cursore) o con parole sue, anche a voce.
// - Alla fine il resoconto: anello del punteggio (indicativo), la frase del cliente, cosa ha funzionato, cosa si poteva
//   usare, i tre strumenti di Prisma per quel cliente e «↻ Rifai l'allenamento».
// - Qwen non pronto: la palestra lo dice e non parte. Esc interrompe Vera mentre scrive.
// - «Riduci movimento»: tutto fermo con la dissolvenza di 0,15 s. Istantanee: conversazione scritta nel codice
//   dell'istantanea, stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Palestra.swift; stato in StatoPalestra.swift.

// MARK: - Testi

enum TestiPalestra {
    static let titolo = "La palestra della trattativa"
    static let difficolta = "Difficoltà"
    static let allenatiCon = "Allenati con…"
    static let inventato = "Profilo inventato…"
    static let nota = "Vera recita il cliente con il suo profilo vero. Le risposte suggerite sono esempi: puoi anche scrivere le tue."
    static let notaInventato = "Vera recita il profilo che hai scritto. Le risposte suggerite sono esempi: puoi anche scrivere le tue."
    static let rispondi = "Rispondi"
    static let campo = "Oppure rispondi a parole tue…"
    static let chiE = "Chi è:"
    static let timori = "I suoi timori:"
    static let obiettivo = "L’obiettivo:"
    static let eta = "Età"
    static let lavoro = "Lavoro"
    static let timoriCampo = "Timori"
    static let sceltaTitolo = "Scegli un cliente per allenarti"
    static let sceltaTesto = "Dal menu «Allenati con…»: un cliente del tuo archivio o un profilo inventato (solo età, lavoro e timori)."
    static let inizia = "▶︎ Inizia l’allenamento"
    static let rifai = "↻ Rifai l’allenamento"
    static let nonProntaTitolo = "Vera non è pronta: la palestra ha bisogno di Qwen sul Mac."
    static let apriImpostazioni = "Impostazioni › Vera"
    static let riprova = "Riprova"
    static let lenta = "Vera ci sta mettendo un po’…"
    static let annulla = "Annulla"
    static let indicativo = "punteggio indicativo"
    static let haFunzionato = "Cosa ha funzionato:"
    static let potevi = "Cosa potevi usare:"
    static let lineaVita = "Linea della vita"
    static let lanciaAnno = "Lancia l’anno"
    static let film = "Il film del piano"
    static let bloccata = "La difficoltà si sceglie prima di cominciare: per cambiarla, rifai l’allenamento."

    static func panni(_ s: SchedaRecita) -> String { "Vera nei panni di \(s.nomeBreve)" }
    static func recitata(_ s: SchedaRecita) -> String { "\(s.nomeBreve) · recitata da Vera" }
    static func scarno(_ s: SchedaRecita) -> String { "Di \(s.nomeBreve) Prisma sa poco: l’allenamento sarà generico." }
    static func obiezione(_ k: Int) -> String { "Obiezione \(k) di \(PalestraVera.obiezioni)" }

    static func invito(_ s: SchedaRecita) -> (titolo: String, testo: String) {
        ("Pronto ad allenarti con \(s.nomeBreve)?",
         "Vera recita \(s.nomeBreve) con il profilo che ha Prisma: tre obiezioni, una alla volta. Scegli la difficoltà e comincia.")
    }

    /// «2 risposte che hanno fatto vedere i numeri».
    static func funzionato(_ ottime: Int) -> String {
        switch ottime {
        case 0: return "nessuna risposta ha fatto vedere i numeri di Prisma."
        case 1: return "1 risposta che ha fatto vedere i numeri di Prisma."
        default: return "\(ottime) risposte che hanno fatto vedere i numeri di Prisma."
        }
    }

    static func strumenti(_ s: [StrumentoPalestra]) -> String {
        let nomi = s.map(\.nome)
        guard nomi.count > 1 else { return (nomi.first ?? "") + "." }
        return nomi.dropLast().joined(separator: ", ") + " e " + (nomi.last ?? "") + "."
    }
}

// MARK: - La vista

/// Il contenuto di Studio › Palestra.
struct PalestraStudioVista: View {
    let stato: StatoShell
    @Bindable var palestra: StatoPalestra
    let base: Double

    private typealias P = Tema.Apple.Palestra

    var body: some View {
        let scheda = palestra.schedaMostrata(stato)
        GeometryReader { geo in
            let colonna = geo.size.width < P.larghezzaColonna * 2.4 ? P.larghezzaColonnaMinima : P.larghezzaColonna
            HStack(alignment: .top, spacing: P.gioco) {
                ColonnaPalestra(stato: stato, palestra: palestra, scheda: scheda)
                    .frame(width: colonna)
                    .frame(maxHeight: .infinity)
                    .superficieApple(P.superficie, raggio: P.raggio)
                    .entrataCascata(0, base: base)
                ConversazionePalestra(stato: stato, palestra: palestra, scheda: scheda)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .superficieApple(P.superficie, raggio: P.raggio)
                    .entrataCascata(1, base: base)
            }
        }
        #if os(macOS)
        .onExitCommand { palestra.annulla() }
        #endif
    }
}

// MARK: - Colonna sinistra

private struct ColonnaPalestra: View {
    let stato: StatoShell
    @Bindable var palestra: StatoPalestra
    let scheda: SchedaRecita?

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias P = Tema.Apple.Palestra

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiPalestra.titolo)
                .carattereApple(P.etichetta)
                .foregroundColor(P.coloreEtichetta)
            profilo
                .padding(.top, P.sopraProfilo)
            tile
                .padding(.top, P.sopraTile)
            Text(TestiPalestra.difficolta)
                .carattereApple(P.etichetta)
                .foregroundColor(P.coloreEtichetta)
                .padding(.top, P.sopraDifficolta)
                .padding(.bottom, P.sottoDifficolta)
            SegmentatoPillola(selezione: Binding(get: { palestra.difficolta }, set: { nuova in
                guard !palestra.inCorso else { return }
                palestra.difficolta = nuova
                if palestra.fase != .attesa { palestra.azzera() }
            }), valori: DifficoltaPalestra.allCases, titolo: { $0.titolo })
                .fixedSize()
                .opacity(palestra.inCorso ? 0.55 : 1)
                .allowsHitTesting(!palestra.inCorso)
                .help(palestra.inCorso ? TestiPalestra.bloccata : "")
            Text(TestiPalestra.obiezione(numero))
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(P.coloreNota)
                .padding(.top, P.sopraAvanzamento)
            BarraAvanzamentoPalestra(frazione: frazione)
                .padding(.top, P.sottoTestoAvanzamento)
            Spacer(minLength: P.sopraAvanzamento)
            Text(palestra.usaInventato ? TestiPalestra.notaInventato : TestiPalestra.nota)
                .carattereApple(P.nota)
                .foregroundColor(P.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(P.paddingColonna)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// «Obiezione k di 3».
    private var numero: Int { min(max(palestra.turni.count, 1), PalestraVera.obiezioni) }

    /// Un terzo per ogni obiezione superata (con la replica), piena alla fine.
    private var frazione: Double {
        if palestra.fase == .fine { return 1 }
        return Double(palestra.turni.filter { $0.replica != nil }.count) / Double(PalestraVera.obiezioni)
    }

    private var profilo: some View {
        HStack(alignment: .center, spacing: P.spazioAvatar) {
            if let s = scheda {
                AvatarPalestra(stato: stato, scheda: s, lato: P.avatar)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.nome)
                        .carattereApple(P.nome)
                        .foregroundColor(P.coloreNome)
                        .lineLimit(1)
                        .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
                    Text(TestiPalestra.panni(s))
                        .carattereApple(P.ruolo)
                        .foregroundColor(P.coloreRuolo)
                        .lineLimit(1)
                }
            } else {
                Text(TestiPalestra.sceltaTitolo)
                    .carattereApple(P.nome)
                    .foregroundColor(P.coloreNome)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            selettore
        }
    }

    /// «Allenati con…»: i clienti dell'archivio e il profilo inventato (bloccato durante l'allenamento).
    private var selettore: some View {
        Menu {
            ForEach(stato.clienti) { c in
                Button(c.nome) { palestra.scegli(cliente: c.id) }
            }
            Divider()
            Button(TestiPalestra.inventato) { palestra.scegliInventato() }
        } label: {
            Text(TestiPalestra.allenatiCon)
                .carattereApple(P.selettore)
                .foregroundColor(P.coloreSelettore)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(palestra.inCorso)
        .help(TestiPalestra.allenatiCon)
    }

    @ViewBuilder private var tile: some View {
        if palestra.usaInventato && palestra.fase == .attesa {
            VStack(alignment: .leading, spacing: 8) {
                campoInventato(TestiPalestra.eta, testo: $palestra.inventato.eta)
                campoInventato(TestiPalestra.lavoro, testo: $palestra.inventato.lavoro)
                campoInventato(TestiPalestra.timoriCampo, testo: $palestra.inventato.timori)
            }
            .padding(P.paddingTile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(P.tile)
        } else if let s = scheda {
            VStack(alignment: .leading, spacing: 0) {
                riga(TestiPalestra.chiE, s.chiE)
                riga(TestiPalestra.timori, s.timori)
                riga(TestiPalestra.obiettivo, s.obiettivo)
                if s.scarna {
                    Text(TestiPalestra.scarno(s))
                        .carattereApple(P.profilo)
                        .foregroundColor(P.coloreScarno)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(P.paddingTile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(P.tile)
        } else {
            Text(TestiPalestra.sceltaTesto)
                .carattereApple(P.profilo)
                .foregroundColor(P.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(P.paddingTile)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(P.tile)
        }
    }

    @ViewBuilder private func riga(_ etichetta: String, _ valore: String?) -> some View {
        if let grezzo = valore {
            let v = grezzo.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            (Text(etichetta).fontWeight(.bold) + Text(" " + v.prefix(1).uppercased() + v.dropFirst() + "."))
                .carattereApple(P.profilo)
                .foregroundColor(P.coloreProfilo)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func campoInventato(_ titolo: String, testo: Binding<String>) -> some View {
        TextField(titolo, text: testo)
            .textFieldStyle(.roundedBorder)
            .carattereApple(P.profilo)
    }
}

/// L'avatar del cliente recitato (iniziali nella sua tinta; il profilo inventato in blu).
private struct AvatarPalestra: View {
    let stato: StatoShell
    let scheda: SchedaRecita
    let lato: CGFloat

    var body: some View {
        let tinta = scheda.clienteId.flatMap { stato.cliente($0)?.tinta } ?? .blu
        AvatarCliente(iniziali: scheda.iniziali, tinta: tinta.colori, lato: lato)
    }
}

/// La barra d'avanzamento alta 8 in accento: cresce in 0,6 s.
private struct BarraAvanzamentoPalestra: View {
    let frazione: Double

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous).fill(Tema.Apple.Colore.binario)
                Capsule(style: .continuous)
                    .fill(Tema.Apple.Palestra.coloreBarra)
                    .frame(width: geo.size.width * CGFloat(min(max(frazione, 0), 1)))
            }
        }
        .frame(height: Tema.Apple.Palestra.altezzaBarra)
        .animation(calmo || istantanea ? nil : Tema.Apple.Moto.Palestra.animazioneAvanzamento, value: frazione)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((frazione * 100).rounded()))%"))
    }
}

// MARK: - Conversazione

private struct ConversazionePalestra: View {
    let stato: StatoShell
    @Bindable var palestra: StatoPalestra
    let scheda: SchedaRecita?

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @FocusState private var campoAttivo: Bool

    private typealias P = Tema.Apple.Palestra
    private static let fondo = "fondo-palestra"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch palestra.fase {
            case .attesa:
                attesa
            case .nonPronta(let motivo):
                nonPronta(motivo)
            default:
                conversazione
                risposte
                    .padding(.bottom, P.sottoRisposte - P.paddingConversazione.bottom)
            }
        }
        .padding(P.paddingConversazione)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Stati

    private var attesa: some View {
        VStack(spacing: P.spazioStato) {
            SferaVera(misura: P.sferaStato, viva: false)
            if let s = scheda {
                let i = TestiPalestra.invito(s)
                Text(i.titolo)
                    .carattereApple(P.titoloStato)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text(i.testo)
                    .carattereApple(P.testoStato)
                    .foregroundColor(P.coloreStato)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button { palestra.inizia(stato) } label: { Text(TestiPalestra.inizia) }
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                    .padding(.top, P.spazioStato)
            } else {
                Text(TestiPalestra.sceltaTitolo)
                    .carattereApple(P.titoloStato)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text(TestiPalestra.sceltaTesto)
                    .carattereApple(P.testoStato)
                    .foregroundColor(P.coloreStato)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: P.larghezzaStato)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func nonPronta(_ motivo: String) -> some View {
        VStack(spacing: P.spazioStato) {
            SferaVera(misura: P.sferaStato, viva: false)
            Text(TestiPalestra.nonProntaTitolo)
                .carattereApple(P.titoloStato)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(motivo)
                .carattereApple(P.testoStato)
                .foregroundColor(P.coloreStato)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: P.fraPulsanti) {
                Button {
                    stato.ancoraImpostazioni = nil
                    stato.schedaImpostazioni = .vera
                    stato.apri(.impostazioni)
                } label: { Text(TestiPalestra.apriImpostazioni) }
                    .buttonStyle(StilePulsanteApple(.secondaria))
                Button { palestra.inizia(stato) } label: { Text(TestiPalestra.riprova) }
                    .buttonStyle(StilePulsanteApple(.principale))
            }
            .padding(.top, P.spazioStato)
        }
        .frame(maxWidth: P.larghezzaStato)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Le bolle

    private var conversazione: some View {
        ScrollViewReader { lettore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: P.fraBolle) {
                    if let s = scheda {
                        ForEach(palestra.turni) { t in
                            BollaClientePalestra(stato: stato, scheda: s, testo: t.obiezione)
                            if let r = t.risposta {
                                BollaConsulentePalestra(testo: r, giudizio: t.giudizio, motivo: t.motivo)
                            }
                            if let r = t.replica {
                                BollaClientePalestra(stato: stato, scheda: s, testo: r)
                            }
                        }
                        if palestra.fase == .veraScrive {
                            BollaClientePalestra(stato: stato, scheda: s, testo: palestra.parziale, scrive: true)
                            if palestra.lenta { lenta }
                        }
                        if case .errore(let m) = palestra.fase { errore(m) }
                        if palestra.fase == .fine { FinePalestra(stato: stato, palestra: palestra, scheda: s) }
                    }
                    Color.clear.frame(height: 1).id(Self.fondo)
                }
                .padding(.top, P.sopraConversazione - P.paddingConversazione.top)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear { lettore.scrollTo(Self.fondo, anchor: .bottom) }
            .onChange(of: passi) { _ in
                if calmo || istantanea {
                    lettore.scrollTo(Self.fondo, anchor: .bottom)
                } else {
                    withAnimation(Tema.Apple.Moto.Palestra.animazioneScorrimento) { lettore.scrollTo(Self.fondo, anchor: .bottom) }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    /// Cambia a ogni bolla nuova (e mentre Vera scrive): la conversazione scorre in fondo.
    private var passi: String {
        "\(palestra.turni.count)-\(palestra.turni.last?.risposta != nil)-\(palestra.turni.last?.replica != nil)-\(palestra.fase == .fine)-\(palestra.parziale.count / 40)-\(palestra.lenta)"
    }

    private var lenta: some View {
        HStack(spacing: P.fraPulsanti) {
            Text(TestiPalestra.lenta)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(P.coloreNota)
            Button { palestra.annulla() } label: { Text(TestiPalestra.annulla) }
                .buttonStyle(StilePulsanteApple(.sobria))
        }
        .padding(.leading, P.Bolla.avatar + P.Bolla.spazioAvatar)
    }

    private func errore(_ m: String) -> some View {
        HStack(spacing: P.fraPulsanti) {
            Text(m)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.rosso)
                .fixedSize(horizontal: false, vertical: true)
            Button { palestra.riprova(stato) } label: { Text(TestiPalestra.riprova) }
                .buttonStyle(StilePulsanteApple(.secondaria))
        }
        .padding(.leading, P.Bolla.avatar + P.Bolla.spazioAvatar)
    }

    // MARK: Le risposte

    @ViewBuilder private var risposte: some View {
        switch palestra.fase {
        case .fine:
            HStack {
                Button { palestra.inizia(stato) } label: { Text(TestiPalestra.rifai) }
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                Spacer(minLength: 0)
            }
            .padding(.top, P.fraBolle)
        case .tuoTurno, .veraScrive:
            VStack(alignment: .leading, spacing: P.fraOpzioni) {
                if palestra.fase == .tuoTurno, let t = palestra.turni.last, !t.suggerite.isEmpty {
                    Text(TestiPalestra.rispondi)
                        .carattereApple(P.etichetta)
                        .foregroundColor(P.coloreEtichetta)
                        .padding(.bottom, P.sottoRispondi - P.fraOpzioni)
                    ForEach(Array(t.suggerite.enumerated()), id: \.offset) { i, testo in
                        OpzionePalestra(indice: i, testo: testo) { palestra.rispondi(testo, stato: stato) }
                    }
                    #if os(macOS)
                    if !campoAttivo {
                        ScorciatoiePalestra(sistema: stato.sistema, quante: t.suggerite.count) { i in
                            guard i < t.suggerite.count else { return }
                            palestra.rispondi(t.suggerite[i], stato: stato)
                        }
                    }
                    #endif
                }
                campo
                    .padding(.top, P.sopraCampo)
            }
            .padding(.top, P.fraBolle)
        default:
            EmptyView()
        }
    }

    private var campo: some View {
        let attivo = palestra.fase == .tuoTurno
        return HStack(spacing: 6) {
            TextField(TestiPalestra.campo, text: $palestra.campo)
                .textFieldStyle(.plain)
                .carattereApple(P.testoCampo)
                .focused($campoAttivo)
                .onSubmit { palestra.rispondi(palestra.campo, stato: stato) }
            #if os(macOS)
            Button { stato.ascoltaPalestra() } label: {
                Image(systemName: palestra.ascolta ? "mic.fill" : "mic")
                    .foregroundColor(palestra.ascolta ? P.coloreMicrofonoAcceso : P.coloreMicrofono)
            }
            .buttonStyle(.plain)
            .help(palestra.ascolta ? "Smetti di ascoltare" : "Rispondi a voce")
            .accessibilityLabel(Text(palestra.ascolta ? "Smetti di ascoltare" : "Rispondi a voce"))
            #endif
            Button { palestra.rispondi(palestra.campo, stato: stato) } label: { Text("↑") }
                .buttonStyle(StilePulsanteApple(.principale))
                .disabled(palestra.campo.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(Text("Rispondi"))
        }
        .padding(P.paddingCampo)
        .background(Capsule(style: .continuous).fill(P.fondoCampo))
        .disabled(!attivo)
        .opacity(attivo ? 1 : 0.55)
    }
}

// MARK: - Bolle

/// La bolla del cliente (a sinistra): avatar 34, «… · recitata da Vera», bolla `--chip`. Mentre Vera scrive: il testo
/// che arriva e i puntini.
private struct BollaClientePalestra: View {
    let stato: StatoShell
    let scheda: SchedaRecita
    let testo: String
    var scrive = false

    private typealias B = Tema.Apple.Palestra.Bolla

    var body: some View {
        HStack(alignment: .top, spacing: B.spazioAvatar) {
            AvatarPalestra(stato: stato, scheda: scheda, lato: B.avatar)
            VStack(alignment: .leading, spacing: B.sottoChi) {
                Text(TestiPalestra.recitata(scheda))
                    .carattereApple(B.chi)
                    .foregroundColor(B.coloreChi)
                VStack(alignment: .leading, spacing: 4) {
                    if !testo.isEmpty {
                        Text(testo)
                            .carattereApple(B.testo)
                            .foregroundColor(B.testoCliente)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if scrive { PuntiniScrittura() }
                }
                .padding(B.padding)
                .background(RettangoloAngoli(altoSinistra: B.raggio, altoDestra: B.raggio, bassoDestra: B.raggio,
                                             bassoSinistra: B.raggioPunta).fill(B.fondoCliente))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: B.larghezzaMassima, alignment: .leading)
        .modifier(EntrataBollaPalestra())
    }
}

/// La bolla del consulente (a destra, accento con il testo bianco) e sotto il giudizio, con il motivo al passaggio.
private struct BollaConsulentePalestra: View {
    let testo: String
    let giudizio: GiudizioPalestra?
    let motivo: String?

    private typealias B = Tema.Apple.Palestra.Bolla

    var body: some View {
        VStack(alignment: .trailing, spacing: Tema.Apple.Palestra.sopraGiudizio) {
            Text(testo)
                .carattereApple(B.testo)
                .foregroundColor(B.testoConsulente)
                .fixedSize(horizontal: false, vertical: true)
                .padding(B.padding)
                .background(RettangoloAngoli(altoSinistra: B.raggio, altoDestra: B.raggio, bassoDestra: B.raggioPunta,
                                             bassoSinistra: B.raggio).fill(B.fondoConsulente))
            if let giudizio {
                Text(giudizio.testo)
                    .carattereApple(Tema.Apple.Palestra.giudizio)
                    .foregroundColor(Tema.Apple.Palestra.colore(giudizio))
                    .help(motivo ?? "")
                    .modifier(EntrataGiudizioPalestra())
            }
        }
        .frame(maxWidth: B.larghezzaMassima, alignment: .trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .modifier(EntrataBollaPalestra())
    }
}

/// La bolla che entra: da y +14, scala 0,97, opacità 0, con la molla (0,42 s). Calmo: dissolvenza; istantanee: ferma.
private struct EntrataBollaPalestra: ViewModifier {
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var dentro = false

    func body(content: Content) -> some View {
        let m = Tema.Apple.Moto.Bolla.self
        let visibile = istantanea || dentro
        let fermo = visibile || calmo
        return content
            .opacity(visibile ? 1 : 0)
            .offset(y: fermo ? 0 : m.spostamento)
            .scaleEffect(fermo ? 1 : m.scala)
            .onAppear {
                guard !istantanea, !dentro else { return }
                withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : m.animazione) { dentro = true }
            }
    }
}

/// Il giudizio che arriva: scala 0,8 → 1 dopo 0,3 s (curva «punti»).
private struct EntrataGiudizioPalestra: ViewModifier {
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var dentro = false

    func body(content: Content) -> some View {
        let m = Tema.Apple.Moto.Palestra.self
        let visibile = istantanea || dentro
        return content
            .opacity(visibile ? 1 : 0)
            .scaleEffect(visibile || calmo ? 1 : m.scalaGiudizio, anchor: .trailing)
            .onAppear {
                guard !istantanea, !dentro else { return }
                withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : m.animazioneGiudizio) { dentro = true }
            }
    }
}

/// Una risposta suggerita (`.opz` della palestra: padding 10 / 14, 14 pt, lettera 26): entra da y +10, una ogni 0,07 s.
private struct OpzionePalestra: View {
    let indice: Int
    let testo: String
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var dentro = false
    @State private var sopra = false

    private typealias P = Tema.Apple.Palestra
    private typealias O = Tema.Apple.OpzioneLettera

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: P.raggioOpzione, style: .continuous)
        let lettera = indice < O.lettere.count ? O.lettere[indice] : "\(indice + 1)"
        let visibile = istantanea || dentro
        return Button(action: azione) {
            HStack(alignment: .center, spacing: O.spazio) {
                Text(lettera)
                    .carattereApple(O.carattereLettera)
                    .foregroundColor(O.coloreLettera)
                    .frame(width: P.letteraOpzione, height: P.letteraOpzione)
                    .background(Circle().fill(O.fondoLettera))
                Text(testo)
                    .carattereApple(P.testoOpzione)
                    .foregroundColor(O.coloreTesto)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(P.paddingOpzione)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(forma.fill(O.fondo))
            .overlay(forma.strokeBorder(O.coloreBordo, lineWidth: O.bordo))
            .contentShape(forma)
        }
        .buttonStyle(.plain)
        .offset(x: sopra && !calmo && !istantanea ? O.spostamentoPassaggio : 0,
                y: visibile || calmo ? 0 : Tema.Apple.Moto.Palestra.spostamentoOpzione)
        .opacity(visibile ? 1 : 0)
        .animation(calmo || istantanea ? nil : O.animazione, value: sopra)
        .onHover { dentro in
            guard !istantanea, sopra != dentro else { return }
            sopra = dentro
        }
        .onAppear {
            guard !istantanea, !dentro else { return }
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.Palestra.opzione(indice: indice)) { dentro = true }
        }
        .accessibilityLabel(Text("\(lettera). \(testo)"))
    }
}

// MARK: - La fine

/// La tile finale: anello del punteggio, la frase del cliente, cosa ha funzionato e cosa si poteva usare, i tre
/// strumenti di Prisma per il cliente recitato.
private struct FinePalestra: View {
    let stato: StatoShell
    @Bindable var palestra: StatoPalestra
    let scheda: SchedaRecita

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var dentro = false

    private typealias P = Tema.Apple.Palestra

    var body: some View {
        let punteggio = palestra.punteggio ?? 0
        let ottime = palestra.turni.filter { $0.giudizio == .ottima }.count
        let frase = PalestraVera.fraseFinale(convinta: palestra.convinta, scheda: scheda, ultimaReplica: palestra.turni.last?.replica)
        let visibile = istantanea || dentro
        return HStack(alignment: .center, spacing: P.spazioFine) {
            VStack(spacing: 4) {
                AnelliConcentrici(voci: [VoceAnello(id: "palestra", valore: Double(punteggio), colore: P.coloreAnello(punteggio))],
                                  misura: P.anelloFinale, spessore: P.spessoreFinale,
                                  ritardo: Tema.Apple.Moto.Palestra.ritardoAnelloFine) {
                    Text("\(punteggio)%")
                        .carattereApple(P.punteggio)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                Text(TestiPalestra.indicativo)
                    .carattereApple(P.indicativo)
                    .foregroundColor(P.coloreIndicativo)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(frase)
                    .carattereApple(P.titoloFine)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                (Text(TestiPalestra.haFunzionato).fontWeight(.bold) + Text(" " + TestiPalestra.funzionato(ottime)) + Text("\n")
                    + Text(TestiPalestra.potevi).fontWeight(.bold)
                    + Text(" " + TestiPalestra.strumenti(PalestraVera.strumentiDaUsare(palestra.strumenti))))
                    .carattereApple(P.testoFine)
                    .foregroundColor(P.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, P.sopraTestoFine)
                HStack(spacing: P.fraPulsanti) {
                    pulsante(TestiPalestra.lineaVita, .lineaVita)
                    pulsante(TestiPalestra.lanciaAnno, .lanciaAnno)
                    pulsante(TestiPalestra.film, .film)
                }
                .padding(.top, P.sopraPulsantiFine)
            }
            Spacer(minLength: 0)
        }
        .padding(Tema.Apple.Misura.Padding.tile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(P.tileFine)
        .opacity(visibile ? 1 : 0)
        .offset(y: visibile || calmo ? 0 : Tema.Apple.Moto.Palestra.spostamentoFine)
        .onAppear {
            guard !istantanea, !dentro else { return }
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.Palestra.animazioneFine) { dentro = true }
        }
    }

    private func pulsante(_ titolo: String, _ s: StrumentoPalestra) -> some View {
        Button { stato.apriDallaPalestra(s, cliente: scheda.clienteId) } label: { Text(titolo) }
            .buttonStyle(StilePulsanteApple(.secondaria))
            .disabled(scheda.clienteId == nil)
    }
}

// MARK: - Tastiera e voce (Mac)

#if os(macOS)
/// Pulsanti invisibili, solo per i tasti: 1/2/3 e A/B/C scelgono la risposta. Ci sono solo con Studio davanti, senza la
/// ricerca aperta e con il campo senza cursore, così le lettere non si rubano a un testo che si sta scrivendo.
private struct ScorciatoiePalestra: View {
    let sistema: StatoFinestre
    let quante: Int
    let scegli: (Int) -> Void

    private static let lettere: [Character] = ["a", "b", "c"]
    private static let cifre: [Character] = ["1", "2", "3"]

    var body: some View {
        if sistema.appAttiva == .studio && !sistema.pannelloRicerca {
            HStack(spacing: 0) {
                ForEach(0..<min(quante, Self.lettere.count), id: \.self) { i in
                    Button("") { scegli(i) }
                        .keyboardShortcut(KeyEquivalent(Self.lettere[i]), modifiers: [])
                    Button("") { scegli(i) }
                        .keyboardShortcut(KeyEquivalent(Self.cifre[i]), modifiers: [])
                }
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
        }
    }
}

extension StatoShell {
    /// Il microfono del campo della palestra: la frase detta va nel campo (il consulente la rilegge e la manda). Usa
    /// il riconoscimento del Mac già in Vera; con «Dettatura di macOS» la catena automatica di Prisma.
    func ascoltaPalestra() {
        guard persistente, !bloccato else { return }
        let p = palestra
        if p.ascolta {
            ascoltoVera.ferma(invia: true)
            return
        }
        voceVera.zitta()
        let vera = dati.impostazioni.vera
        let scelta: SceltaRiconoscimento = (vera.riconoscimento == .automatico || vera.riconoscimento == .dettatura)
            ? (SceltaRiconoscimento.catenaAutomatica.first ?? .classico) : vera.riconoscimento
        ascoltoVera.azzera()
        p.ascolta = true
        ascoltoVera.concluso = { [weak p] frase in
            DispatchQueue.main.async {
                p?.ascolta = false
                if p?.fase == .tuoTurno { p?.campo = frase }
            }
        }
        ascoltoVera.problema = { [weak self, weak p] motivo in
            DispatchQueue.main.async {
                p?.ascolta = false
                self?.mostraAvviso(motivo)
            }
        }
        ascoltoVera.avvia(scelta)
    }
}
#endif
