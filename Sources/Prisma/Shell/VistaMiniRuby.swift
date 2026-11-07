#if os(macOS)
import AppKit
import SwiftUI

/// La mini finestra di Ruby (Design/ruby-mini.html): una sola superficie di vetro che cambia forma.
/// Capsula 440 × 72 mentre ascolta, pensa o si sveglia; scheda 460, alta quanto serve, quando risponde e per scrivere.
/// Il passaggio è una molla di 0,55 s (con «Riduci movimento» una dissolvenza breve).
struct VistaMiniRuby: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    /// Entrata e uscita (opacità, un po' più in alto e più piccola).
    @State private var mostrata = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        superficie
            .padding(EdgeInsets(top: m.margineOmbraSopra, leading: m.margineOmbraLati, bottom: m.margineOmbraSotto, trailing: m.margineOmbraLati))
            .frame(width: m.larghezzaScheda + 2 * m.margineOmbraLati, alignment: .topTrailing)
            .frame(maxHeight: .infinity, alignment: .top)
            .onAppear {
                guard !modoIstantanea else { return mostrata = mini.visibile }
                withAnimation(movimentoRidotto ? Tema.Moto.MiniRuby.ridotto : Tema.Moto.MiniRuby.entrata) { mostrata = mini.visibile }
            }
            .onChange(of: mini.visibile) { v in
                withAnimation(v ? (movimentoRidotto ? Tema.Moto.MiniRuby.ridotto : Tema.Moto.MiniRuby.entrata) : Tema.Moto.MiniRuby.uscita) {
                    mostrata = v
                }
            }
    }

    private var superficie: some View {
        let m = Tema.Misura.MiniRuby.self
        let capsula = mini.fase.capsula
        let raggio = capsula ? m.altezzaCapsula / 2 : Tema.Raggio.MiniRuby.scheda
        let forma = FormaVetro.arrotondata(raggio)
        let moto: Animation? = modoIstantanea ? nil : (movimentoRidotto ? Tema.Moto.MiniRuby.ridotto : Tema.Moto.MiniRuby.forma)
        return contenuto
            .frame(width: mini.larghezza)
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(forma)
            // Sopra le finestre e le app: nelle istantanee coprente, il testo sotto non si legge attraverso
            .vetro(.pannello, forma: forma, riempimento: Tema.Colore.MiniRuby.fondo, sopra: true)
            .animation(moto, value: mini.fase)
            .animation(moto, value: mini.inArrivo)
            .opacity(mostrata ? 1 : 0)
            .scaleEffect(mostrata || movimentoRidotto ? 1 : m.scalaUscita, anchor: .topTrailing)
            .offset(y: mostrata || movimentoRidotto ? 0 : m.salitaUscita)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Ruby")
    }

    @ViewBuilder
    private var contenuto: some View {
        Group {
            switch mini.fase {
            case .ascolta: CapsulaAscolto()
            case .pensa: CapsulaPensa()
            case .nonPronta: CapsulaNonPronta()
            case .risponde: SchedaRisposta()
            case .scrivi: SchedaScrivi()
            }
        }
        .id(mini.fase)
        .transition(.opacity)
    }
}

// MARK: - Capsule

/// Ti ascolto…: la sfera e l'onda seguono il livello della voce, la frase si scrive mentre parli.
private struct CapsulaAscolto: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby

    var body: some View {
        if stato.persistente {
            OsservaAscoltoMini(ascolto: stato.ascoltoRuby) { capsula($0) }
        } else {
            capsula(stato.voceIstantanea ?? StatoVoce(ascolta: true))
        }
    }

    private func capsula(_ v: StatoVoce) -> some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        let livello = CGFloat(v.livello)
        return HStack(spacing: m.spazioCapsula) {
            SferaAcquaRuby(lato: m.sferaCapsula, livello: livello, velocita: Tema.Moto.MiniRuby.velocitaAscolto)
            VStack(alignment: .leading, spacing: m.spazioSotto) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(v.trascritto.isEmpty ? "Ti ascolto…" : v.trascritto)
                        .foregroundColor(v.trascritto.isEmpty ? c.testoTerziario : c.testo)
                        .lineLimit(2)
                    CursoreMiniRuby()
                }
                .font(Tema.Testo.MiniRuby.frase)
                Text(v.prepara ? (v.nota ?? "Mi preparo ad ascoltarti…") : sotto)
                    .font(Tema.Testo.MiniRuby.sotto)
                    .foregroundColor(c.testoTerziario)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            OndaMiniRuby(livello: livello, attiva: v.ascolta && !v.prepara)
            TastoTondoMiniRuby(simbolo: "xmark", aiuto: "Chiudi · Esc") { stato.chiudiMiniRuby() }
        }
        .padding(Tema.Misura.MiniRuby.margineCapsula)
        .frame(minHeight: m.altezzaCapsula)
    }

    private var sotto: String {
        guard let c = mini.contesto else { return "Su tutto il portafoglio" }
        return "Su \(c.nome)" + (c.app.map { " · \($0)" } ?? "")
    }
}

/// Segue l'ascolto e ridisegna solo la capsula.
private struct OsservaAscoltoMini<C: View>: View {
    @ObservedObject var ascolto: AscoltoRuby
    let contenuto: (StatoVoce) -> C

    var body: some View {
        contenuto(StatoVoce(ascolta: ascolto.ascolta, prepara: ascolto.siPrepara, trascritto: ascolto.trascritto,
                            livello: ascolto.livello, nota: ascolto.nota))
    }
}

/// Ruby pensa: i passi scorrono con un luccichio, la domanda sotto.
private struct CapsulaPensa: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        HStack(spacing: m.spazioCapsula) {
            SferaAcquaRuby(lato: m.sferaCapsula, velocita: Tema.Moto.MiniRuby.velocitaPensiero)
            VStack(alignment: .leading, spacing: m.spazioSotto) {
                LuccichioMiniRuby(testo: mini.passo)
                Text(mini.domanda)
                    .font(Tema.Testo.MiniRuby.sotto)
                    .foregroundColor(Tema.Colore.MiniRuby.testoTerziario)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TastoTondoMiniRuby(simbolo: "xmark", aiuto: "Chiudi · Esc") { stato.chiudiMiniRuby() }
        }
        .padding(m.margineCapsula)
        .frame(minHeight: m.altezzaCapsula)
    }
}

/// Qwen non è pronto: «Mi sto svegliando…», la barra di avanzamento e Riprova. Nessuna risposta inventata.
private struct CapsulaNonPronta: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        HStack(spacing: m.spazioCapsula) {
            SferaAcquaRuby(lato: m.sferaCapsula, spenta: true)
            VStack(alignment: .leading, spacing: m.spazioSotto) {
                Text("Mi sto svegliando…")
                    .font(Tema.Testo.MiniRuby.fraseSveglia)
                    .foregroundColor(c.testo)
                Text(mini.motivoNonPronta ?? "Qwen si avvia sul Mac, qualche secondo e ci sono. Non invento nulla nel frattempo.")
                    .font(Tema.Testo.MiniRuby.sotto)
                    .foregroundColor(c.testoTerziario)
                    .fixedSize(horizontal: false, vertical: true)
                AvanzamentoMiniRuby(attivo: mini.preparazioneInCorso || mini.motivoNonPronta == nil)
                    .padding(.top, m.spazioAvanzamento - m.spazioSotto)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PulsanteMiniRuby(titolo: "Riprova") { stato.riprovaMiniRuby() }
            TastoTondoMiniRuby(simbolo: "xmark", aiuto: "Chiudi · Esc") { stato.chiudiMiniRuby() }
        }
        .padding(m.margineCapsula)
        .frame(minHeight: m.altezzaCapsula)
    }
}

// MARK: - Schede

/// La risposta: la domanda in alto, il testo, le cifre di Prisma con il canale, la fonte, i pulsanti e gli spunti.
private struct SchedaRisposta: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: m.spazioTesta) {
                SferaAcquaRuby(lato: m.sferaScheda, velocita: mini.inArrivo ? Tema.Moto.MiniRuby.velocitaPensiero : 1)
                VStack(alignment: .leading, spacing: m.spazioDomanda) {
                    HStack(spacing: m.spazioFonte) {
                        Text(mini.inArrivo ? "Ruby" : "Ruby · ora")
                        if mini.inArrivo { ParlaMiniRuby() }
                    }
                    .font(Tema.Testo.MiniRuby.autore)
                    .foregroundColor(c.testoTerziario)
                    Text(mini.domanda)
                        .font(Tema.Testo.MiniRuby.domanda)
                        .foregroundColor(c.testo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TastoTondoMiniRuby(simbolo: "arrow.up.forward", aiuto: "Continua nell'app Ruby") { stato.apriInRubyDaMiniRuby() }
                TastoTondoMiniRuby(simbolo: "xmark", aiuto: "Chiudi · Esc") { stato.chiudiMiniRuby() }
            }
            .padding(m.margineTesta)
            // Il corpo scorre se la risposta è lunga: la scheda non supera l'altezza massima
            ScrollView(.vertical) { corpo }
                .frame(maxHeight: corpoMassimo)
            CampoMiniRuby(segnaposto: "Chiedi altro a Ruby…")
            PiedeMiniRuby()
        }
    }

    /// Lo spazio del corpo: l'altezza disponibile sullo schermo meno testa, campo e piede. La scheda è alta quanto
    /// serve; scorre solo se la risposta non sta nello schermo.
    private var corpoMassimo: CGFloat { mini.altezzaMassima - Tema.Misura.MiniRuby.cornice }

    private var corpo: some View {
        let m = Tema.Misura.MiniRuby.self
        let cifre = mini.cifre
        let mostra = !mini.inArrivo
        return VStack(alignment: .leading, spacing: 0) {
            if let t = mini.titolo, t == "Ruby non ha potuto rispondere" || t == "Qwen non è pronto" {
                Text(t)
                    .font(Tema.Testo.MiniRuby.rispostaForte)
                    .foregroundColor(Tema.Colore.MiniRuby.testo)
                    .padding(.bottom, m.spazioSotto * 2)
            }
            TestoRispostaMiniRuby(testo: mini.risposta)
            if mostra {
                Group {
                    // .reveal del template: linea del tempo, righe, fonte, pulsanti e spunti salgono uno dopo l'altro
                    if let l = cifre.linea { LineaTempoVista(linea: l).padding(.top, m.spazioBlocchi).comparsaMiniRuby(0) }
                    if !cifre.righe.isEmpty { RigheMiniRuby(righe: cifre.righe).padding(.top, m.spazioRighe).comparsaMiniRuby(1) }
                    // Lo scenario «E se…?»: la stessa tabella prima/dopo dell'app Ruby, con le cifre di Prisma
                    if let s = cifre.scenario {
                        TabellaScenarioApple(colonnaOggi: s.colonnaOggi, colonnaScenario: s.colonnaScenario, righe: s.righe)
                            .padding(.top, m.spazioBlocchi)
                            .comparsaMiniRuby(1)
                    }
                    if let f = cifre.fonte {
                        HStack(spacing: m.spazioFonte) {
                            Image(systemName: "doc.text").font(.system(size: m.simboloFonte))
                            Text(f).lineLimit(1)
                        }
                        .font(Tema.Testo.MiniRuby.fonte)
                        .foregroundColor(Tema.Colore.MiniRuby.testoTerziario)
                        .padding(.top, m.spazioRighe)
                        .comparsaMiniRuby(2)
                    }
                    if !cifre.azioni.isEmpty {
                        DisposizioneAcapoRicerca(spazio: m.spazioPulsante) {
                            ForEach(cifre.azioni) { a in
                                PulsanteMiniRuby(titolo: a.titolo, simbolo: a.simbolo, primario: a.primaria) { stato.eseguiMiniRuby(a) }
                            }
                        }
                        .padding(.top, m.spazioBlocchi)
                        .comparsaMiniRuby(3)
                    }
                    if !cifre.seguiti.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            EtichettaMiniRuby(testo: "Puoi chiedermi anche")
                            DisposizioneAcapoRicerca(spazio: m.spazioSpunti) {
                                ForEach(cifre.seguiti) { s in SpuntoMiniRubyVista(spunto: s) }
                            }
                        }
                        .comparsaMiniRuby(4)
                    }
                }
            }
        }
        .padding(m.margineCorpo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Tema.Moto.MiniRuby.comparsa, value: mostra)
    }
}

/// Pronta per scrivere: il gettone del contesto, il campo, gli spunti del cliente, la giornata e i recenti.
private struct SchedaScrivi: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: m.spazioTesta) {
                SferaAcquaRuby(lato: m.sferaScheda)
                Group {
                    if let c = mini.contesto {
                        GettoneContestoMiniRuby(contesto: c, togli: stato.inModoCliente ? nil : { stato.togliContestoMiniRuby() })
                    } else {
                        Text("Su tutto il portafoglio")
                            .font(Tema.Testo.MiniRuby.gettone)
                            .foregroundColor(Tema.Colore.MiniRuby.testoSecondario)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TastoTondoMiniRuby(simbolo: "xmark", aiuto: "Chiudi · Esc") { stato.chiudiMiniRuby() }
            }
            .padding(m.margineTesta)
            CampoMiniRuby(segnaposto: "Chiedi a Ruby, o tieni premuto ⌥ Spazio e parla…", fuoco: true)
            VStack(alignment: .leading, spacing: 0) {
                if let n = mini.nota {
                    Text(n)
                        .font(Tema.Testo.MiniRuby.sotto)
                        .foregroundColor(Tema.Colore.MiniRuby.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, m.spazioRighe)
                }
                if let c = mini.contesto {
                    sezione("Su \(c.nome)", CifreMiniRuby.spuntiCliente)
                }
                if !stato.inModoCliente {
                    sezione(mini.contesto == nil ? "Il portafoglio" : "La tua giornata",
                            mini.contesto == nil ? Array(CifreMiniRuby.spuntiGiornata.prefix(1)) + CifreMiniRuby.spuntiPortafoglio : CifreMiniRuby.spuntiGiornata)
                    let recenti = stato.recentiMiniRuby()
                    if !recenti.isEmpty {
                        EtichettaMiniRuby(testo: "Recenti")
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(recenti) { r in RecenteMiniRuby(messaggio: r) }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 2, leading: m.margineCorpo.leading, bottom: m.margineCorpo.bottom, trailing: m.margineCorpo.trailing))
            PiedeMiniRuby()
        }
    }

    private func sezione(_ titolo: String, _ spunti: [SpuntoMiniRuby]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            EtichettaMiniRuby(testo: titolo)
            DisposizioneAcapoRicerca(spazio: Tema.Misura.MiniRuby.spazioSpunti) {
                ForEach(spunti) { s in SpuntoMiniRubyVista(spunto: s) }
            }
        }
    }
}

// MARK: - Pezzi della scheda

/// Il testo della risposta, con le cifre in grassetto (come nel template).
private struct TestoRispostaMiniRuby: View {
    let testo: String
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    /// Le parole già scritte: la risposta si scrive una parola alla volta, come se Ruby parlasse (.answer .w).
    /// Mentre Qwen scrive il testo cresce a blocchi; qui le parole lo seguono con un ritmo regolare.
    @State private var scritte = 0
    @State private var precedente = ""

    var body: some View {
        let tutte = Self.parole(testo)
        let fermo = movimentoRidotto || modoIstantanea
        let n = fermo ? tutte.count : min(scritte, tutte.count)
        let m = Tema.Misura.MiniRuby.self
        // Ogni parola affiora da sfocata a nitida (.w: opacità e blur 3 px, 0,35 s); quelle non ancora scritte
        // ci sono già, invisibili: la scheda non cambia altezza a ogni parola
        return ParoleACapoMiniRuby(spazio: m.spazioParola, interlinea: m.interlinea / 2, paragrafo: m.spazioParagrafo) {
            ForEach(tutte) { p in
                let scritta = p.id < n
                Text(p.testo)
                    .font(p.forte ? Tema.Testo.MiniRuby.rispostaForte : Tema.Testo.MiniRuby.risposta)
                    .opacity(scritta ? 1 : 0)
                    .blur(radius: scritta ? 0 : m.sfocaturaParola)
                    .animation(fermo ? nil : Tema.Moto.MiniRuby.parolaEntra, value: scritta)
                    .layoutValue(key: InizioParagrafoMiniRuby.self, value: p.aCapo)
            }
        }
        .foregroundColor(Tema.Colore.MiniRuby.testo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(testo)
        .task(id: testo) {
            // Una risposta nuova riparte da capo; una che cresce continua da dove era arrivata
            if !testo.hasPrefix(precedente) { scritte = 0 }
            precedente = testo
            let totale = Self.parole(testo).count
            while scritte < totale && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Tema.Moto.MiniRuby.parola)
                scritte += 1
            }
        }
    }

    /// Una parola della risposta: in grassetto se fa parte di una cifra, con l'a capo se apre un paragrafo.
    struct Parola: Identifiable {
        let id: Int
        let testo: String
        let forte: Bool
        let aCapo: Bool
    }

    private static let spazi = try? NSRegularExpression(pattern: #"\S+"#)

    /// Le parole del testo, nell'ordine, con le cifre (euro, percentuali, quantità) in grassetto.
    static func parole(_ s: String) -> [Parola] {
        guard let r = spazi else { return [] }
        let ns = s as NSString
        let tutto = NSRange(location: 0, length: ns.length)
        let forti = cifre?.matches(in: s, range: tutto).map(\.range) ?? []
        var esito: [Parola] = []
        var fine = 0
        for m in r.matches(in: s, range: tutto) {
            let tra = ns.substring(with: NSRange(location: fine, length: m.range.location - fine))
            let forte = forti.contains { NSIntersectionRange($0, m.range).length > 0 }
            esito.append(Parola(id: esito.count, testo: ns.substring(with: m.range), forte: forte,
                                aCapo: !esito.isEmpty && tra.contains("\n")))
            fine = m.range.location + m.range.length
        }
        return esito
    }

    private static let cifre = try? NSRegularExpression(pattern: #"€\s?\d[\d.,]*|\d[\d.,]*\s?(?:%|€|euro\b)|\b\d+\s(?:posizion[ei]|mesi|anni|scadenze)\b"#)

    /// Le cifre (euro, percentuali, quantità) in grassetto, il resto normale.
    static func conCifre(_ s: String) -> Text {
        guard let r = cifre else { return Text(s) }
        let ns = s as NSString
        var esito = Text("")
        var da = 0
        for m in r.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            if m.range.location > da { esito = esito + Text(ns.substring(with: NSRange(location: da, length: m.range.location - da))) }
            esito = esito + Text(ns.substring(with: m.range)).font(Tema.Testo.MiniRuby.rispostaForte)
            da = m.range.location + m.range.length
        }
        if da < ns.length { esito = esito + Text(ns.substring(from: da)) }
        return esito
    }
}

/// Le posizioni citate (.rows): nome e nota, il canale, la cifra e la data.
private struct RigheMiniRuby: View {
    let righe: [RigaMiniRuby]

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        VStack(spacing: 0) {
            ForEach(Array(righe.enumerated()), id: \.element.id) { i, r in
                HStack(spacing: m.spazioRiga) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(r.titolo).font(Tema.Testo.MiniRuby.rigaTitolo).foregroundColor(c.testo).lineLimit(1)
                        Text(r.sotto).font(Tema.Testo.MiniRuby.rigaSotto).foregroundColor(c.testoSecondario).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    EtichettaCanaleApple(canale: r.canale, compatta: true)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(r.valore).font(Tema.Testo.MiniRuby.rigaValore).foregroundColor(c.testo)
                        if let d = r.data {
                            Text("\(Formati.giornoMeseBreve.string(from: d)) \(Formati.formato("yyyy").string(from: d))")
                                .font(Tema.Testo.MiniRuby.rigaData).foregroundColor(c.testoSecondario)
                        }
                    }
                }
                .padding(m.margineRiga)
                .overlay(alignment: .top) {
                    if i > 0 { Rectangle().fill(c.separatore).frame(height: Tema.Misura.filo) }
                }
            }
        }
        // Una scheda dei calcoli come quelle dell'app Ruby (tile del tema Apple col filo)
        .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Ruby.SchedaCalcoli.raggio, style: .continuous))
        .superficieApple(Tema.Apple.Ruby.SchedaCalcoli.superficie, raggio: Tema.Apple.Ruby.SchedaCalcoli.raggio)
    }
}

/// Il campo (.composer): «Chiedi altro a Ruby…», il tasto ⏎ e il microfono.
private struct CampoMiniRuby: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mini: StatoMiniRuby
    let segnaposto: String
    var fuoco = false
    @FocusState private var attivo: Bool

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        HStack(spacing: m.spazioCampo) {
            TextField(segnaposto, text: $mini.testo)
                .textFieldStyle(.plain)
                .font(Tema.Testo.MiniRuby.campo)
                .foregroundColor(c.testo)
                .focused($attivo)
                .frame(height: m.altezzaCampo)
                .onSubmit { stato.inviaMiniRuby(DomandaMiniRuby(testo: mini.testo)) }
            TastoMiniRuby(testo: "⏎")
            Button { stato.alternaAscoltoMiniRuby() } label: {
                Image(systemName: "mic")
                    .font(.system(size: m.simboloMicrofono, weight: .semibold))
                    .foregroundColor(c.testoSuAccento)
                    .frame(width: m.microfono, height: m.microfono)
                    .background(Circle().fill(c.accento))
            }
            .buttonStyle(StilePressioneMiniRuby())
            .help("Parla (o tieni premuto ⌥ Spazio)")
        }
        .padding(m.margineCampo)
        .background(Capsule(style: .continuous).fill(c.scheda))
        .overlay(Capsule(style: .continuous).strokeBorder(c.bordoScheda, lineWidth: Tema.Misura.filo))
        .overlay(Capsule(style: .continuous).stroke(c.accento.opacity(attivo ? 0.28 : 0), lineWidth: m.anelloCampo).padding(-m.anelloCampo / 2))
        .padding(m.margineScrittura)
        .onAppear {
            guard fuoco else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { attivo = true }
        }
    }
}

/// Il piede (.foot): in locale sul Mac, le scorciatoie.
private struct PiedeMiniRuby: View {
    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Circle().fill(c.inLocale).frame(width: m.spiaLocale, height: m.spiaLocale)
                    .background(Circle().fill(c.inLocale.opacity(0.18)).padding(-m.aloneSpia))
                Text("In locale sul Mac")
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                TastoMiniRuby(testo: "⌥ Spazio")
                Text("parla ·")
                TastoMiniRuby(testo: "esc")
                Text("chiudi")
            }
        }
        .font(Tema.Testo.MiniRuby.piede)
        .foregroundColor(c.testoTerziario)
        .padding(m.marginePiede)
    }
}

/// Il gettone del contesto (.ctx-chip): l'avatar, il cliente, l'app e la ✕ per toglierlo.
private struct GettoneContestoMiniRuby: View {
    let contesto: ContestoMiniRuby
    let togli: (() -> Void)?

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        let tinta = contesto.tinta.colori
        HStack(spacing: m.spazioGettone) {
            Text(contesto.iniziali)
                .font(Tema.Testo.MiniRuby.avatarGettone)
                .foregroundColor(tinta.testo)
                .frame(width: m.avatarGettone, height: m.avatarGettone)
                .background(Circle().fill(Gradienti.avatar(tinta)))
            (Text(contesto.nome).font(Tema.Testo.MiniRuby.gettone).foregroundColor(c.testo)
             + Text(contesto.app.map { " · \($0)" } ?? "").font(Tema.Testo.MiniRuby.gettoneApp).foregroundColor(c.testoSecondario))
                .lineLimit(1)
            if let togli {
                Button(action: togli) {
                    Image(systemName: "xmark")
                        .font(.system(size: m.simboloTogli, weight: .bold))
                        .foregroundColor(c.testoSecondario)
                        .frame(width: m.togliGettone, height: m.togliGettone)
                        .background(Circle().fill(c.pozzetto))
                }
                .buttonStyle(StileSemplice())
                .help("Togli il contesto: Ruby parla di tutto il portafoglio")
            }
        }
        .padding(.horizontal, m.margineGettone)
        .frame(height: m.gettone)
        .background(Capsule(style: .continuous).fill(c.chip))
        .overlay(Capsule(style: .continuous).strokeBorder(c.bordoChip, lineWidth: Tema.Misura.filo))
        .fixedSize()
        .help("Ruby parte da ciò che hai aperto")
    }
}

/// Una domanda recente (.recent).
private struct RecenteMiniRuby: View {
    @EnvironmentObject var stato: StatoShell
    let messaggio: MessaggioRuby
    @State private var sopra = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        Button { stato.inviaMiniRuby(DomandaMiniRuby(testo: messaggio.testo)) } label: {
            HStack(spacing: m.spazioRecente) {
                Image(systemName: "clock.arrow.circlepath").font(.system(size: m.simboloPulsante)).foregroundColor(c.testoTerziario)
                Text(messaggio.testo).font(Tema.Testo.MiniRuby.recente).foregroundColor(c.testo).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Formati.giornoRelativo(messaggio.data)).font(Tema.Testo.MiniRuby.quando).foregroundColor(c.testoTerziario)
            }
            .padding(m.margineRecente)
            .background(RoundedRectangle(cornerRadius: Tema.Raggio.MiniRuby.recente, style: .continuous).fill(sopra ? c.pozzetto : .clear))
            .padding(.horizontal, -m.margineRecente.leading)
        }
        .buttonStyle(StileSemplice())
        .onHover { sopra = $0 }
    }
}

/// Uno spunto (.sugg button): pozzetto a capsula con il simbolo blu.
private struct SpuntoMiniRubyVista: View {
    @EnvironmentObject var stato: StatoShell
    let spunto: SpuntoMiniRuby
    @State private var sopra = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        Button {
            stato.inviaMiniRuby(DomandaMiniRuby(testo: spunto.domanda, spunto: spunto.spunto, portafoglio: spunto.portafoglio))
        } label: {
            HStack(spacing: m.spazioSpunti) {
                Image(systemName: spunto.simbolo).font(.system(size: m.simboloPulsante)).foregroundColor(c.link)
                Text(spunto.testo).font(Tema.Testo.MiniRuby.spunto).foregroundColor(c.testo).lineLimit(1)
            }
            .padding(.horizontal, m.margineSpunto)
            .frame(height: m.spunto)
            .background(Capsule(style: .continuous).fill(sopra ? c.pozzettoSopra : c.pozzetto))
            .overlay(Capsule(style: .continuous).strokeBorder(c.separatore, lineWidth: Tema.Misura.filo))
        }
        .buttonStyle(StilePressioneMiniRuby())
        .onHover { sopra = $0 }
    }
}

private struct EtichettaMiniRuby: View {
    let testo: String

    var body: some View {
        Text(testo.uppercased())
            .font(Tema.Testo.MiniRuby.etichetta)
            .tracking(Tema.Testo.MiniRuby.spaziaturaEtichetta)
            .foregroundColor(Tema.Colore.MiniRuby.testoTerziario)
            .padding(Tema.Misura.MiniRuby.margineEtichetta)
    }
}

// MARK: - Controlli

/// Pulsante di vetro (.btn), o pieno dell'accento (.btn.primary).
private struct PulsanteMiniRuby: View {
    let titolo: String
    var simbolo: String?
    var primario = false
    let azione: () -> Void
    @State private var sopra = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        Button(action: azione) {
            HStack(spacing: m.spazioPulsante) {
                if let simbolo { Image(systemName: simbolo).font(.system(size: m.simboloPulsante, weight: .medium)) }
                Text(titolo).lineLimit(1)
            }
            .font(Tema.Testo.MiniRuby.pulsante)
            .foregroundColor(primario ? c.testoSuAccento : c.testo)
            .padding(.horizontal, m.marginePulsante)
            .frame(height: m.pulsante)
            .background(Capsule(style: .continuous).fill(primario ? c.accento : (sopra ? c.chipSopra : c.chip)))
            .overlay(Capsule(style: .continuous).strokeBorder(primario ? Color.clear : c.bordoChip, lineWidth: Tema.Misura.filo))
            .overlay(alignment: .top) {
                Capsule(style: .continuous).trim(from: 0.6, to: 0.9).stroke(primario ? Color.white.opacity(0.35) : c.lucePulsante, lineWidth: 1)
                    .padding(1).allowsHitTesting(false)
            }
            .ombraTema(primario ? Tema.Ombra.pulsantePrimario : Tema.Ombra.pulsante)
            .fixedSize()
        }
        .buttonStyle(StilePressioneMiniRuby())
        .onHover { sopra = $0 }
    }
}

/// Pulsante tondo (.ico): ✕ e la freccia verso l'app Ruby.
private struct TastoTondoMiniRuby: View {
    let simbolo: String
    let aiuto: String
    let azione: () -> Void
    @State private var sopra = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let c = Tema.Colore.MiniRuby.self
        Button(action: azione) {
            Image(systemName: simbolo)
                .font(.system(size: m.simboloIco, weight: .semibold))
                .foregroundColor(sopra ? c.testo : c.testoSecondario)
                .frame(width: m.ico, height: m.ico)
                .background(Circle().fill(sopra ? c.pozzettoSopra : c.pozzetto))
        }
        .buttonStyle(StilePressioneMiniRuby())
        .onHover { sopra = $0 }
        .help(aiuto)
        .accessibilityLabel(aiuto)
    }
}

/// Il tasto di una scorciatoia (.kb).
private struct TastoMiniRuby: View {
    let testo: String

    var body: some View {
        Text(testo)
            .font(Tema.Testo.MiniRuby.tasto)
            .foregroundColor(Tema.Colore.MiniRuby.testoSecondario)
            .padding(Tema.Misura.MiniRuby.margineTasto)
            .background(RoundedRectangle(cornerRadius: Tema.Raggio.MiniRuby.tasto, style: .continuous).fill(Tema.Colore.MiniRuby.pozzetto))
    }
}

/// La pressione del tema: un rimbalzo appena più piccolo.
private struct StilePressioneMiniRuby: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(Tema.Moto.molla, value: configuration.isPressed)
    }
}

// MARK: - Movimenti piccoli

/// La parola apre un paragrafo (dopo un a capo nel testo).
private struct InizioParagrafoMiniRuby: LayoutValueKey {
    static let defaultValue = false
}

/// Le parole della risposta a capo come un testo: spazio fra le parole, interlinea, un po' d'aria fra i paragrafi.
private struct ParoleACapoMiniRuby: Layout {
    var spazio: CGFloat
    var interlinea: CGFloat
    var paragrafo: CGFloat

    private func posizioni(larghezza: CGFloat, _ subviews: Subviews) -> (punti: [CGPoint], misura: CGSize) {
        var punti: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, riga: CGFloat = 0, destra: CGFloat = 0
        for (i, s) in subviews.enumerated() {
            let d = s.sizeThatFits(.unspecified)
            if i > 0 && s[InizioParagrafoMiniRuby.self] {
                y += riga + interlinea + paragrafo
                x = 0
                riga = 0
            } else if x > 0 && x + d.width > larghezza {
                y += riga + interlinea
                x = 0
                riga = 0
            }
            punti.append(CGPoint(x: x, y: y))
            destra = max(destra, x + d.width)
            x += d.width + spazio
            riga = max(riga, d.height)
        }
        return (punti, CGSize(width: destra, height: y + riga))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezza = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        let m = posizioni(larghezza: larghezza, subviews).misura
        return CGSize(width: proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? m.width, height: m.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let punti = posizioni(larghezza: bounds.width, subviews).punti
        for (s, p) in zip(subviews, punti) {
            s.place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
}

/// .reveal: un blocco della risposta sale di 6 punti e compare, dopo i blocchi prima di lui (0,16 s l'uno).
private struct ComparsaMiniRuby: ViewModifier {
    let indice: Int
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    @State private var visibile = false

    func body(content: Content) -> some View {
        let fermo = movimentoRidotto || modoIstantanea
        content
            .opacity(fermo || visibile ? 1 : 0)
            .offset(y: fermo || visibile ? 0 : Tema.Misura.MiniRuby.salitaComparsa)
            .onAppear {
                guard !fermo else { return }
                withAnimation(Tema.Moto.MiniRuby.comparsa.delay(Tema.Moto.MiniRuby.ritardoBlocco * Double(indice))) { visibile = true }
            }
    }
}

extension View {
    fileprivate func comparsaMiniRuby(_ indice: Int) -> some View { modifier(ComparsaMiniRuby(indice: indice)) }
}

/// Il cursore che lampeggia (.caret).
private struct CursoreMiniRuby: View {
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let fermo = movimentoRidotto || modoIstantanea
        TimelineView(.periodic(from: .now, by: Tema.Moto.MiniRuby.lampeggio / 2)) { t in
            let acceso = fermo || Int(t.date.timeIntervalSinceReferenceDate / (Tema.Moto.MiniRuby.lampeggio / 2)) % 2 == 0
            Rectangle()
                .fill(Tema.Colore.MiniRuby.cursore)
                .frame(width: m.cursore.width, height: m.cursore.height)
                .opacity(acceso ? 1 : 0)
        }
        .frame(width: m.cursore.width, height: m.cursore.height)
    }
}

/// L'onda della voce (.wave): barre simmetriche guidate dal livello del microfono.
private struct OndaMiniRuby: View {
    let livello: CGFloat
    let attiva: Bool
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let muove = attiva && !movimentoRidotto && !modoIstantanea
        TimelineView(.animation(minimumInterval: 1 / Tema.Moto.MiniRuby.fotogrammi, paused: !muove)) { t in
            let k = muove ? t.date.timeIntervalSinceReferenceDate : 0.6
            HStack(spacing: m.spazioOnda) {
                ForEach(0..<m.barreOnda, id: \.self) { i in
                    Capsule()
                        .fill(LinearGradient(colors: [Tema.Colore.MiniRuby.accento, Tema.Colore.MiniRuby.ondaFine], startPoint: .top, endPoint: .bottom))
                        .frame(width: m.barraOnda, height: altezza(i, k))
                }
            }
        }
        .frame(height: m.altezzaOnda)
        .fixedSize()
    }

    private func altezza(_ i: Int, _ k: Double) -> CGFloat {
        let m = Tema.Misura.MiniRuby.self
        let n = CGFloat(m.barreOnda)
        let centro = 1 - abs(CGFloat(i) - (n - 1) / 2) / (n / 2)
        let rumore = 0.6 + 0.4 * abs(sin(k * 9 + Double(i) * 1.7))
        return m.barraOndaMinima + min(max(livello, 0), 1) * m.barraOndaVoce * (0.35 + 0.65 * centro) * CGFloat(rumore)
    }
}

/// Il passo di «pensa» con il luccichio che scorre (.shimmer).
private struct LuccichioMiniRuby: View {
    let testo: String
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea

    var body: some View {
        let c = Tema.Colore.MiniRuby.self
        let muove = !movimentoRidotto && !modoIstantanea
        TimelineView(.animation(minimumInterval: 1 / Tema.Moto.MiniRuby.fotogrammi, paused: !muove)) { t in
            let fase = muove ? (t.date.timeIntervalSinceReferenceDate / Tema.Moto.MiniRuby.luccichio).truncatingRemainder(dividingBy: 1) : 0.45
            let centro = -0.4 + 1.8 * fase
            Text(testo)
                .font(Tema.Testo.MiniRuby.pensa)
                .lineLimit(1)
                .foregroundStyle(LinearGradient(stops: [.init(color: c.testoTerziario, location: 0), .init(color: c.testo, location: 0.5),
                                                        .init(color: c.testoTerziario, location: 1)],
                                                 startPoint: UnitPoint(x: centro - 0.5, y: 0.5), endPoint: UnitPoint(x: centro + 0.5, y: 0.5)))
        }
    }
}

/// Le barrette accanto a «Ruby» mentre la risposta arriva (.speak).
private struct ParlaMiniRuby: View {
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let muove = !movimentoRidotto && !modoIstantanea
        TimelineView(.animation(minimumInterval: 1 / Tema.Moto.MiniRuby.fotogrammi, paused: !muove)) { t in
            let k = muove ? t.date.timeIntervalSinceReferenceDate : 0.3
            HStack(spacing: 1.5) {
                ForEach(0..<m.barreParla, id: \.self) { i in
                    let ritardo = [0, 0.2, 0.45][i]
                    let u = (k + ritardo).truncatingRemainder(dividingBy: 0.7) / 0.7
                    Capsule().fill(Tema.Colore.MiniRuby.accento)
                        .frame(width: m.barraParla, height: 3 + (m.altezzaParla - 3) * CGFloat((1 - cos(2 * .pi * u)) / 2))
                }
            }
            .frame(height: m.altezzaParla)
        }
    }
}

/// La barra di avanzamento di «Mi sto svegliando…» (.prog).
private struct AvanzamentoMiniRuby: View {
    let attivo: Bool
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        let muove = attivo && !movimentoRidotto && !modoIstantanea
        GeometryReader { g in
            TimelineView(.animation(minimumInterval: 1 / Tema.Moto.MiniRuby.fotogrammi, paused: !muove)) { t in
                let w = g.size.width * m.quotaAvanzamento
                let fase = muove ? (t.date.timeIntervalSinceReferenceDate / Tema.Moto.MiniRuby.avanzamento).truncatingRemainder(dividingBy: 1) : 0.4
                let u = (1 - cos(.pi * fase)) / 2
                Capsule().fill(Tema.Colore.MiniRuby.avanzamento)
                    .frame(width: w, height: m.barraAvanzamento)
                    .offset(x: -w + (g.size.width + w) * CGFloat(u))
            }
        }
        .frame(height: m.barraAvanzamento)
        .background(Capsule().fill(Tema.Colore.MiniRuby.pozzetto))
        .clipShape(Capsule())
    }
}

// MARK: - La sfera nella barra superiore

/// La sfera di Ruby nella capsula degli strumenti: apre e chiude la mini finestra (⌥ Spazio).
/// Ferma a riposo (niente consumi), viva mentre la mini finestra è aperta.
struct PulsanteSferaRuby: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var mini: StatoMiniRuby
    @State private var sopra = false

    var body: some View {
        let m = Tema.Misura.MiniRuby.self
        Button { stato.alternaMiniRuby() } label: {
            // La sfera del template nella barra (24): respira mentre la mini finestra è aperta, ferma a riposo
            SferaRuby(misura: Tema.Apple.Ruby.Sfera.barra, viva: mini.visibile)
                .frame(width: m.sferaPulsanteBarra, height: m.sferaPulsanteBarra)
                .frame(minWidth: Tema.Misura.Shell.pulsanteBarraMinimo, minHeight: Tema.Misura.pulsanteBarra)
                .background {
                    if mini.visibile || sopra { Capsule(style: .continuous).fill(Tema.Colore.MiniRuby.sferaBarraAperta) }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .onHover { s in withAnimation(Tema.Moto.passaggio) { sopra = s } }
        .help("Ruby · ⌥ Spazio (tieni premuto per parlare)")
        .accessibilityLabel("Chiama Ruby")
    }
}
#endif
