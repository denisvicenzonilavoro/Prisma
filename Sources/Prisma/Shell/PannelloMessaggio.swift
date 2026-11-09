import SwiftUI

// Il pannello del messaggio di Messaggi (Design/template-novita-specifica.md §5.1.4, §5.1.6, §5.2.2), lo stesso sul
// Mac, sull'iPad e sull'iPhone:
//
//   ◉  A: Giulia Rossi · giulia.rossi@example.com              [Perché adesso: Incontro di ieri alle 17:30]
//      Il riepilogo dell'incontro di ieri
//   [Cordiale · Formale · Breve] [Mail · Messaggi]                       ◎ Vera scrive con i dati del dossier
//   Oggetto: Il riepilogo del nostro incontro
//   ──────────────────────────────────────────────────────────────────────────────────────────────
//   Ciao Giulia, …   (parola per parola mentre Vera scrive, poi modificabile; con Messaggi nella nuvoletta blu)
//   [Decisioni · …] [Prossimo incontro · 3 dicembre 2026]
//   Le cifre vengono da Prisma · Scritto da Vera con qwen3.5:4b
//   [Apri in Mail] [Salva nel dossier] [↻ Riscrivi]                                  Lo controlli e lo spedisci tu
//
// - Il testo lo scrive Qwen sul Mac (SessioneMessaggi, MessaggiVera): mentre arriva compare parola per parola
//   (TestoProgressivo, 22 ms a parola) e, finito, diventa un campo di testo da correggere. Se Qwen non è pronto, o se
//   il suo testo cambia una cifra, resta il testo di Prisma con la riga che lo spiega (sfera ferma).
// - Senza email o telefono nel dossier la testata lo dice e il pulsante principale porta all'anagrafica.
// - Un messaggio che propone qualcosa a un cliente senza consenso commerciale valido: pillola arancio e conferma.
// - Prisma non spedisce mai: «Apri in Mail» apre Mail già compilato, la spedizione la fa il consulente.
// - `compatto` (iPhone, iPad in verticale): controlli e pulsanti uno sotto l'altro; `incorniciato` (Mac e iPad): la
//   barra dei pulsanti resta in fondo e scorre solo il testo.
// - «Riduci movimento»: niente cascata né comparsa parola per parola (tutto subito); istantanee: stato finale, il
//   testo come testo (senza il campo), nessun puntino.
// Valori in DesignSystem/Apple/Tema.Apple+Messaggi.swift.

@MainActor
struct PannelloMessaggio: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var sessione: SessioneMessaggi
    let occasione: OccasioneMessaggio
    let cliente: Cliente
    @Binding var tono: TonoMessaggio
    @Binding var canale: CanaleMessaggio
    var compatto = false
    var incorniciato = true
    /// La cascata: base (0,14 all'apertura, 0 a un cambio di occasione) e il primo indice (dopo le voci dell'elenco).
    var base: Double = Tema.Apple.Messaggi.Moto.baseApertura
    var primoIndice = 0
    /// Solo nelle istantanee: il testo già pronto (nessuna scrittura parte).
    var scrittoIstantanea: TestoScrittoMessaggio? = nil

    @Environment(\.prismaScatto) private var scatto
    @State private var chiediConsenso = false
    /// «La seconda lettura» (fase 3 di Vera): gli avvisi prima di aprire Mail o Messaggi; decide il consulente.
    @State private var lettura: EsitoSecondaLettura?

    private typealias P = Tema.Apple.Messaggi.Pannello
    private typealias T = Tema.Apple.Messaggi.Testo

    private var chiave: ChiaveTestoMessaggio {
        ChiaveTestoMessaggio(occasione: occasione.id, tono: tono, canale: canale)
    }

    /// «Scrive come te» (fase 4 di Vera, funzione 15): le regole dello stile che il testo pronto non rispetta.
    @ViewBuilder
    private var avvisiStile: some View {
        if let s = pronto {
            AvvisiStileMessaggioVista(testo: s.testo, clienteId: cliente.id)
                .padding(.top, Tema.Apple.Messaggi.Barra.sopra)
        }
    }

    private var pronto: TestoScrittoMessaggio? {
        scrittoIstantanea ?? sessione.scritto(chiave)
    }

    private var scrive: Bool {
        scrittoIstantanea == nil && sessione.inScrittura == chiave
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let k = chiave
        let contenuto = VStack(alignment: .leading, spacing: 0) {
            testata
                .entrataCascata(primoIndice, base: base)
            controlli
                .padding(.top, P.controlliSopra)
                .padding(.bottom, P.controlliSotto)
                .entrataCascata(primoIndice + 1, base: base)
            if canale == .mail {
                rigaOggetto
                    .entrataCascata(primoIndice + 2, base: base)
            }
            if incorniciato {
                ScrollView(.vertical, showsIndicators: true) {
                    corpo
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .entrataCascata(primoIndice + 3, base: base)
                avvisiStile
                barra
                    .padding(.top, Tema.Apple.Messaggi.Barra.sopra)
            } else {
                corpo
                    .entrataCascata(primoIndice + 3, base: base)
                avvisiStile
                barra
                    .padding(.top, Tema.Apple.Messaggi.Barra.sopra)
            }
        }
        .padding(compatto ? P.paddingCompatto : P.padding)
        .frame(maxWidth: .infinity, maxHeight: incorniciato ? .infinity : nil, alignment: .topLeading)
        .superficieApple(P.superficie, raggio: P.raggio)
        return contenuto
            .task(id: k) {
                // Nelle istantanee il testo è già pronto: nessuna scrittura, nessuna verifica di Qwen
                guard scrittoIstantanea == nil, !scatto else { return }
                sessione.prepara(occasione, stato: stato)
            }
            .sheet(item: $lettura) { e in
                FoglioSecondaLettura(esito: e, avanti: "Apri lo stesso", correggi: { e in
                    if let s = pronto { sessione.correggi(chiave, e.corretto(s.testo)) }
                }, continua: { apri(riletto: true) })
            }
            .alert(TestiMessaggi.confermaConsensoTitolo, isPresented: $chiediConsenso) {
                Button(TestiMessaggi.confermaConsensoApri) { apri() }
                Button(TestiMessaggi.confermaConsensoNo, role: .cancel) {}
            } message: {
                Text(TestiMessaggi.confermaConsenso(cliente.nome))
            }
    }

    // MARK: Testata

    private var testata: some View {
        let d = TestiMessaggi.destinatario(cliente, canale: canale)
        let titoli = VStack(alignment: .leading, spacing: P.spazioTitolo) {
            Text(d.testo)
                .carattereApple(P.destinatario)
                .foregroundColor(d.manca ? P.coloreRecapitoMancante : P.coloreDestinatario)
                .lineLimit(compatto ? 2 : 1)
                .truncationMode(.middle)
            Text(occasione.titolo)
                .carattereApple(P.titolo)
                .foregroundColor(P.coloreTitolo)
                .fixedSize(horizontal: false, vertical: true)
        }
        return Group {
            if compatto {
                VStack(alignment: .leading, spacing: P.spazioTestata) {
                    HStack(alignment: .center, spacing: P.spazioTestata) {
                        avatar
                        titoli
                    }
                    pillole
                }
            } else {
                HStack(alignment: .center, spacing: P.spazioTestata) {
                    avatar
                    titoli
                    Spacer(minLength: P.spazioTestata)
                    pillole
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var avatar: some View {
        AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: P.avatar)
            .accessibilityHidden(true)
    }

    private var pillole: some View {
        let senzaConsenso = occasione.commerciale && !stato.consensoCommercialeValido(cliente)
        return Group {
            if compatto {
                VStack(alignment: .leading, spacing: P.spazioPillole) { contenutoPillole(senzaConsenso) }
            } else {
                VStack(alignment: .trailing, spacing: P.spazioPillole) { contenutoPillole(senzaConsenso) }
            }
        }
    }

    @ViewBuilder private func contenutoPillole(_ senzaConsenso: Bool) -> some View {
        pillola(TestiMessaggi.perche(occasione), fondo: P.fondoPerche, testo: P.testoPerche)
        if senzaConsenso {
            pillola(TestiMessaggi.senzaConsenso, fondo: P.fondoConsenso, testo: P.testoConsenso)
        }
        if let c = occasione.canale {
            EtichettaCanaleApple(canale: c, compatta: compatto)
        }
    }

    private func pillola(_ testo: String, fondo: Color, testo colore: Color) -> some View {
        Text(testo)
            .carattereApple(P.pillola)
            .foregroundColor(colore)
            .lineLimit(1)
            .padding(P.paddingPillola)
            .background { Capsule(style: .continuous).fill(fondo) }
            .fixedSize()
    }

    // MARK: Controlli

    private var segmentatoTono: some View {
        SegmentatoPillola(selezione: $tono, valori: TonoMessaggio.allCases, titolo: { $0.nome }, larghezzaPiena: compatto)
    }

    private var segmentatoCanale: some View {
        SegmentatoPillola(selezione: $canale, valori: CanaleMessaggio.allCases, titolo: { $0.nome }, larghezzaPiena: compatto)
    }

    @ViewBuilder private var controlli: some View {
        if compatto {
            VStack(alignment: .leading, spacing: P.spazioControlli) {
                segmentatoTono
                segmentatoCanale
                notaVera
            }
        } else {
            HStack(alignment: .center, spacing: P.spazioControlli) {
                segmentatoTono.fixedSize()
                segmentatoCanale.fixedSize()
                Spacer(minLength: P.spazioControlli)
                notaVera
            }
        }
    }

    /// La sfera di Vera con chi scrive: viva quando scrive Vera, ferma sul testo di Prisma.
    private var notaVera: some View {
        let vera = scrive || pronto?.autore == .vera
        let testo = scrive ? TestiMessaggi.veraStaScrivendo : (pronto == nil || vera ? TestiMessaggi.veraScrive : TestiMessaggi.testoPrisma)
        return HStack(spacing: P.spazioSfera) {
            SferaVera(misura: P.sfera, viva: vera || pronto == nil, pensa: scrive)
            Text(testo)
                .carattereApple(P.notaVera)
                .foregroundColor(P.coloreNotaVera)
                .lineLimit(1)
        }
        .fixedSize()
    }

    // MARK: Oggetto

    private var rigaOggetto: some View {
        let oggetto = pronto?.oggetto ?? ModelliMessaggi.oggetto(occasione, canale: .mail) ?? occasione.oggetto
        return HStack(alignment: .firstTextBaseline, spacing: P.spazioOggetto) {
            Text("Oggetto:")
                .carattereApple(P.oggetto)
                .foregroundColor(P.coloreEtichettaOggetto)
            Text(oggetto)
                .carattereApple(P.oggettoForte)
                .foregroundColor(P.coloreOggetto)
        }
            .lineLimit(compatto ? 2 : 1)
            .padding(.vertical, P.paddingOggetto)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle().fill(P.filetto).frame(height: P.spessoreFiletto).allowsHitTesting(false)
            }
    }

    // MARK: Il testo

    @ViewBuilder private var corpo: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !scrive, let a = pronto?.avviso {
                HStack(alignment: .top, spacing: P.spazioSfera) {
                    SferaVera(misura: P.sfera, viva: false)
                    Text(a)
                        .carattereApple(P.avviso)
                        .foregroundColor(P.coloreAvviso)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, P.sopraAvviso)
            }
            if stato.haDatiDiProva, StatoShell.clientiDiProva.contains(cliente.id) {
                Text(TestiMessaggi.datiDiProva)
                    .carattereApple(P.prova)
                    .foregroundColor(P.coloreProva)
                    .padding(.top, P.sopraProva)
            }
            testoMessaggio
                .padding(.top, T.sopra)
            cifre
            nota
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Il testo: i puntini finché non arriva niente, poi parola per parola, poi il campo da correggere.
    @ViewBuilder private var testoMessaggio: some View {
        let k = chiave
        let nuvoletta = canale == .messaggi
        let correggibile = !scatto && pronto != nil && !scrive && sessione.comparsi.contains(k)
        if correggibile {
            CampoTestoMessaggio(testo: Binding(get: { sessione.testo(k) ?? "" }, set: { sessione.correggi(k, $0) }))
                .contenitoreTestoMessaggio(nuvoletta: nuvoletta, compatto: compatto)
        } else if pronto == nil && sessione.parziale.isEmpty {
            PuntiniScrittura()
                .padding(.top, T.sopraPuntini)
                .frame(maxWidth: .infinity, minHeight: nuvoletta ? nil : (compatto ? T.altezzaMinimaCompatta : T.altezzaMinima),
                       alignment: nuvoletta ? .topTrailing : .topLeading)
        } else {
            TestoProgressivo(testo: pronto?.testo ?? sessione.parziale, passo: Tema.Apple.Messaggi.Moto.parola,
                             anima: !scatto, finito: { sessione.comparso(k) })
                .carattereApple(T.carattere)
                .id("\(k.occasione)-\(k.tono.rawValue)-\(k.canale.rawValue)-\(sessione.giri[k] ?? 0)")
                .contenitoreTestoMessaggio(nuvoletta: nuvoletta, compatto: compatto)
        }
    }

    /// Le cifre della scheda come piccole etichette: le sole che il testo può citare.
    @ViewBuilder private var cifre: some View {
        let C = Tema.Apple.Messaggi.Cifre.self
        if !occasione.cifre.isEmpty {
            DisposizioneAcapoRicerca(spazio: C.spazio) {
                ForEach(Array(occasione.cifre.enumerated()), id: \.offset) { _, cifra in
                    HStack(spacing: C.spazioInterno) {
                        Text(cifra.etichetta)
                            .carattereApple(C.etichetta)
                            .foregroundColor(C.coloreEtichetta)
                        Text(cifra.valore)
                            .carattereApple(C.valore)
                            .foregroundColor(C.coloreValore)
                            .truncationMode(.tail)
                    }
                    .lineLimit(1)
                    .padding(C.padding)
                    .background { Capsule(style: .continuous).fill(C.fondo) }
                    .frame(maxWidth: C.larghezzaMassima, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .help("\(cifra.etichetta): \(cifra.valore)")
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, C.sopra)
        }
    }

    private var nota: some View {
        let C = Tema.Apple.Messaggi.Cifre.self
        let autore = pronto.map { TestiMessaggi.autore($0) }
        return Text([TestiMessaggi.cifreDaPrisma, autore].compactMap { $0 }.joined(separator: " · "))
            .carattereApple(C.nota)
            .foregroundColor(C.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, C.sopraNota)
    }

    // MARK: Pulsanti

    @ViewBuilder private var barra: some View {
        let B = Tema.Apple.Messaggi.Barra.self
        if compatto {
            VStack(alignment: .leading, spacing: B.spazio) {
                pulsantePrincipale.frame(maxWidth: .infinity)
                HStack(spacing: B.spazio) {
                    pulsanteSalva.frame(maxWidth: .infinity)
                    pulsanteRiscrivi.frame(maxWidth: .infinity)
                }
                notaSpedisci
            }
        } else {
            HStack(alignment: .center, spacing: B.spazio) {
                pulsantePrincipale
                pulsanteSalva
                pulsanteRiscrivi
                Spacer(minLength: B.spazio)
                notaSpedisci
            }
        }
    }

    private var notaSpedisci: some View {
        let B = Tema.Apple.Messaggi.Barra.self
        return Text(TestiMessaggi.spedisciTu)
            .carattereApple(B.nota)
            .foregroundColor(B.coloreNota)
            .lineLimit(1)
    }

    private var manca: Bool { AperturaMessaggi.recapito(cliente, canale: canale) == nil }

    @ViewBuilder private var pulsantePrincipale: some View {
        if manca {
            Button { stato.apriAnagraficaMessaggio(cliente.id) } label: {
                Text(TestiMessaggi.aggiungiNelDossier).frame(maxWidth: compatto ? .infinity : nil)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(stato.inModoCliente)
            .help(AperturaMessaggi.mancante(canale))
        } else {
            Button { primario() } label: {
                Text(TestiMessaggi.apri(canale)).frame(maxWidth: compatto ? .infinity : nil)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(pronto == nil || scrive)
            .help("Apre \(canale.nome) già compilato: niente parte da solo")
        }
    }

    private var pulsanteSalva: some View {
        Button { salva() } label: {
            Text(TestiMessaggi.salva).frame(maxWidth: compatto ? .infinity : nil)
        }
        .buttonStyle(.appleGrande)
        .disabled(pronto == nil || scrive || stato.solaLettura)
        .help("Il messaggio resta nel dossier di \(cliente.nome), con la data, il canale e il tono")
    }

    private var pulsanteRiscrivi: some View {
        Button { sessione.riscrivi(occasione, stato: stato) } label: {
            Text(TestiMessaggi.riscrivi).frame(maxWidth: compatto ? .infinity : nil)
        }
        .buttonStyle(.appleGrande)
        .disabled(scrive || scrittoIstantanea != nil)
        .help("Vera scrive di nuovo lo stesso messaggio, con le stesse cifre")
    }

    // MARK: Fare

    private func primario() {
        if occasione.commerciale && !stato.consensoCommercialeValido(cliente) {
            chiediConsenso = true
        } else {
            apri()
        }
    }

    /// Apre Mail o Messaggi già compilati (mai un invio) e ricorda il messaggio segnato nel dossier.
    private func apri(riletto: Bool = false) {
        let k = chiave
        guard let s = pronto else { return }
        // La seconda lettura: parole a rischio e cifre senza fonte (anche nel testo corretto a mano)
        if !riletto {
            let e = stato.secondaLetturaMessaggio(occasione, testo: s.testo)
            if !e.pulito {
                lettura = e
                return
            }
        }
        let prima = sessione.idSalvato(k)
        let esito = stato.apriMessaggio(occasione, tono: s.tono ?? k.tono, canale: k.canale, scritto: s, id: prima)
        stato.mostraAvviso(esito.messaggio)
        if esito.aperto {
            sessione.ricordaSalvato(k, id: prima ?? stato.dati.messaggi.last(where: { $0.occasioneId == occasione.id })?.id)
        }
    }

    /// Salva nel dossier (o aggiorna il messaggio già salvato o aperto, che resta aperto).
    private func salva() {
        let k = chiave
        guard let s = pronto else { return }
        let prima = sessione.idSalvato(k)
        let statoPrima = prima.flatMap { id in stato.dati.messaggi.first(where: { $0.id == id })?.stato }
        let nuovo: StatoMessaggio = (statoPrima == .apertoInMail || statoPrima == .apertoInMessaggi) ? (statoPrima ?? .salvato) : .salvato
        guard let m = stato.salvaMessaggio(occasione, tono: s.tono ?? k.tono, canale: k.canale, scritto: s, stato: nuovo, id: prima) else {
            return
        }
        sessione.ricordaSalvato(k, id: m.id)
        stato.mostraAvviso(TestiMessaggi.salvato(cliente.nome))
    }
}

// MARK: - Il campo di testo

/// Il campo di testo del messaggio (TextEditor del sistema) alto quanto il testo: un testo invisibile uguale dà
/// l'altezza, il campo ci sta sopra senza fondo proprio. Il margine interno del campo si toglie, così il testo non
/// si sposta quando la comparsa parola per parola finisce e il campo prende il suo posto.
private struct CampoTestoMessaggio: View {
    @Binding var testo: String

    private typealias T = Tema.Apple.Messaggi.Testo

    var body: some View {
        Text(testo + "\n")
            .carattereApple(T.carattere)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(0)
            .accessibilityHidden(true)
            .overlay {
                TextEditor(text: $testo)
                    .carattereApple(T.carattere)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .padding(.horizontal, -T.rientroCampo)
                    .accessibilityLabel(Text("Testo del messaggio"))
            }
    }
}

// MARK: - Mail o nuvoletta

private struct ContenitoreTestoMessaggio: ViewModifier {
    let nuvoletta: Bool
    let compatto: Bool

    private typealias T = Tema.Apple.Messaggi.Testo

    @ViewBuilder func body(content: Content) -> some View {
        if nuvoletta {
            content
                .foregroundColor(T.testoNuvoletta)
                .tint(T.testoNuvoletta)
                .padding(T.paddingNuvoletta)
                .background {
                    RettangoloAngoli(altoSinistra: T.raggioNuvoletta, altoDestra: T.raggioNuvoletta,
                                     bassoDestra: T.raggioNuvolettaStretto, bassoSinistra: T.raggioNuvoletta)
                        .fill(T.fondoNuvoletta)
                }
                .frame(maxWidth: T.larghezzaNuvoletta, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            content
                .foregroundColor(T.colore)
                .frame(maxWidth: .infinity, minHeight: compatto ? T.altezzaMinimaCompatta : T.altezzaMinima, alignment: .topLeading)
        }
    }
}

private extension View {
    func contenitoreTestoMessaggio(nuvoletta: Bool, compatto: Bool) -> some View {
        modifier(ContenitoreTestoMessaggio(nuvoletta: nuvoletta, compatto: compatto))
    }
}
