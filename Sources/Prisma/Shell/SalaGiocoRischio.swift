import SwiftUI

// Il gioco del rischio (Design/template-luce-specifica.md §4.1, «Luce» giro 4, senza il tavolo a doppio senso che
// arriva con il giro 16): tre scenari raccontati uno alla volta (il valore che scende e risale, le due strade), tre
// risposte ciascuno, e alla fine il «profilo vissuto» accanto a quello dichiarato.
//
//   SCENARIO 1 DI 3  testi di prova          Il gioco prepara il questionario di adeguatezza, non lo sostituisce
//   Il tuo portafoglio di 100.000 € scende del 20% in tre mesi.
//   80.000 €                                              (A) Vendo tutto, non voglio perdere altro
//   ╲__╱╲___ ‒ ‒ ‒ ‒ ‒ ‒ 100.000 €                        (B) Aspetto: è già successo e poi è risalito
//                                                         (C) Compro ancora: adesso costa meno
//
// - Le risposte compaiono quando il grafico è finito (2,4 s; 1,7 s nelle due strade) ed entrano da destra; il tempo di
//   decisione si misura da lì. Scelta una risposta (accento neutro: nessuna è «giusta», decisione 84), dopo 0,65 s
//   arriva lo scenario seguente.
// - Il risultato: l'anello del punteggio nel colore della propensione emersa (le quattro di Prisma), le tre reazioni
//   con i secondi (nascondibili), il confronto con la propensione dichiarata (arancio se diversa) o la frase se non c'è.
//   Il gioco non scrive mai `Cliente.profilo.propensione` (decisione 59): «Salva nel dossier» (con conferma) mette la
//   partita nell'archivio, «Apri il profilo di …» porta al Profilo del dossier con l'avviso.
// - Testi, risposte e soglie da `Risorse/Sala/gioco-rischio.json`, con l'etichetta «testi di prova» finché l'utente non
//   li approva. Stato della partita locale (si azzera uscendo e cambiando cliente): a metà partita (risposte già date,
//   risultato non ancora) «‹ Sala», Esc e il cambio di cliente con le pillole chiedono conferma (§4.1.4,
//   `StatoSala.rischioAMeta` e `uscitaRischio`, dialogo in Shell/AppSala.swift).
// - Tastiera (Mac, proposta della §4.1.4): A, B, C e 1, 2, 3 scelgono la risposta, solo quando le risposte sono
//   visibili e nessuna è ancora scelta, con la Sala davanti (`ScorciatoieRischio`, pulsanti invisibili come la palestra).
// - «Riduci movimento»: grafico già tracciato, numero finale, risposte già presenti, dissolvenza di 0,15 s. Istantanee:
//   stato finale dello scenario (o del risultato) scelto da `StatoSala.rischioIstantanea`.

/// Il punto del gioco da cui partire (le istantanee): lo scenario, le risposte già date, la scelta da mostrare.
struct PuntoGiocoRischio {
    var scenario: Int
    var risposte: [RispostaRischio]
    var scelta: Int? = nil
    var risultato = false
    var data: Date? = nil
}

/// Il contenuto del palco per il gioco del rischio.
struct GiocoRischioVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Fuori dalla presentazione: i comandi del consulente (salva, apri il profilo, nascondi i secondi).
    var consulente = true

    private enum Fase: Equatable { case ultimaVolta, scenario(Int), risultato }

    @State private var fase: Fase
    @State private var risposte: [RispostaRischio]
    @State private var scelta: Int?
    @State private var visibili = false
    @State private var compaiono = Date()
    @State private var giro = 0
    @State private var dataPartita: Date
    @State private var salvata = false
    @State private var mostraSecondi = true
    @State private var confermaSalva = false

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private let scenari: ScenariGiocoRischio?
    private let ultima: PartitaRischio?

    private typealias R = Tema.Apple.SalaEsperienze.Rischio
    private typealias M = Tema.Apple.Moto.SalaEsperienze.Rischio

    init(cliente: Cliente, ultima: PartitaRischio?, punto: PuntoGiocoRischio?, consulente: Bool = true) {
        self.cliente = cliente
        self.consulente = consulente
        self.ultima = ultima
        self.scenari = MotoreGiocoRischio.caricati
        if let punto {
            _fase = State(initialValue: punto.risultato ? .risultato : .scenario(punto.scenario))
            _risposte = State(initialValue: punto.risposte)
            _scelta = State(initialValue: punto.scelta)
            _visibili = State(initialValue: true)
            _dataPartita = State(initialValue: punto.data ?? Date())
        } else {
            _fase = State(initialValue: ultima != nil && consulente ? .ultimaVolta : .scenario(0))
            _risposte = State(initialValue: [])
            _dataPartita = State(initialValue: Date())
        }
    }

    var body: some View {
        Group {
            if let scenari {
                switch fase {
                case .ultimaVolta:
                    ultimaVolta(scenari)
                case .scenario(let i) where i < scenari.scenari.count:
                    scenario(scenari, indice: i)
                        .id(giro)
                        .transition(.opacity)
                default:
                    risultato(scenari)
                        .id(giro)
                        .transition(.opacity)
                }
            } else {
                Text("I testi del gioco non si leggono (Risorse/Sala/gioco-rischio.json): il gioco non parte.")
                    .carattereApple(R.testoRiquadro)
                    .foregroundColor(R.coloreAvvertenza)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(R.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Il tavolo a doppio senso (giro 16, decisione 48): lo scenario va sull'iPad a ogni passo, la risposta torna
        // con i secondi misurati sull'iPad. Le risposte restano toccabili anche qui (ripiego del consulente)
        .dalTavolo { c in if case .rispostaRischio(let r) = c { rispondiDalTavolo(r) } }
        .onChange(of: fase) { _, _ in mandaAlTavolo() }
        .onChange(of: stato.sala.tavoloEsperienza) { _, _ in mandaAlTavolo() }
        // A metà partita uscire o cambiare cliente chiede conferma (§4.1.4): solo la vista del consulente lo dice
        .onChange(of: aMeta, initial: true) { _, nuovo in if consulente { stato.sala.rischioAMeta = nuovo } }
        .onDisappear {
            stato.lasciaTavolo(.giocoRischio)
            if consulente { stato.sala.rischioAMeta = false }
        }
    }

    /// Ci sono risposte date e il risultato non è ancora arrivato.
    private var aMeta: Bool {
        guard !risposte.isEmpty, case .scenario(let i) = fase, let s = scenari else { return false }
        return i < s.scenari.count
    }

    /// Lo scenario in corso o il risultato all'iPad (solo se il tavolo è per il gioco). Niente nomi né cifre del cliente.
    private func mandaAlTavolo() {
        guard stato.sala.tavoloEsperienza == .giocoRischio, let s = scenari else { return }
        let n = s.scenari.count
        switch fase {
        case .ultimaVolta:
            rifai()
        case .scenario(let i) where i < n:
            stato.rischioAlTavolo(RischioTavolo(indice: i, totale: n, scenario: s.scenari[i], avvertenza: s.avvertenza,
                                                testiDiProva: s.testiDiProva, emerso: nil, punteggio: nil, massimo: nil),
                                  cliente: cliente.id)
        default:
            let partita = PartitaRischio(clienteId: cliente.id, data: dataPartita, versioneScenari: s.versione, risposte: risposte)
            let profilo = MotoreGiocoRischio.profilo(partita, scenari: s)
            stato.rischioAlTavolo(RischioTavolo(indice: n, totale: n, scenario: nil, avvertenza: s.notaFinale,
                                                testiDiProva: s.testiDiProva, emerso: profilo?.rawValue,
                                                punteggio: partita.punteggio, massimo: s.massimo),
                                  cliente: cliente.id)
        }
    }

    /// La risposta toccata sull'iPad: la stessa strada della risposta sul Mac, con i secondi dell'iPad.
    private func rispondiDalTavolo(_ r: RispostaRischioTavolo) {
        guard let s = scenari, case .scenario(let n) = fase, n < s.scenari.count, s.scenari[n].id == r.scenario,
              (0..<s.scenari[n].risposte.count).contains(r.scelta) else { return }
        visibili = true
        registra(s.scenari[n], scelta: r.scelta, secondi: max(0, r.secondi))
    }

    // MARK: L'ultima volta

    private func ultimaVolta(_ s: ScenariGiocoRischio) -> some View {
        let nome = StatoShell.nomeBreve(cliente)
        let profilo = ultima.flatMap { MotoreGiocoRischio.profilo($0, scenari: s) }
        return VStack(alignment: .leading, spacing: R.spazioRiquadro) {
            Text(ultima.map { "L’ultima volta, il \(Formati.dataEstesa.string(from: $0.data)): \(profilo?.nome ?? "partita incompleta")" } ?? "")
                .carattereApple(R.testoRiquadro)
                .foregroundColor(R.coloreTitolo)
            Text("\(nome) ha già fatto il gioco. Si può rifare da capo o rivedere il risultato salvato nel dossier.")
                .carattereApple(R.avvertenza)
                .foregroundColor(R.coloreAvvertenza)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: R.spazioPulsanti) {
                Button { rifai() } label: { Text("↻ Rifai il gioco") }
                    .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                Button {
                    guard let u = ultima else { return }
                    risposte = u.risposte
                    dataPartita = u.data
                    salvata = true
                    passa(a: .risultato)
                } label: { Text("Vedi il risultato") }
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                    .disabled(profilo == nil)
            }
        }
        .padding(R.paddingRiquadro)
        .frame(maxWidth: R.larghezzaRiquadro, alignment: .leading)
        .superficieApple(R.riquadro, raggio: R.raggioRiquadro)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }

    // MARK: Uno scenario

    private func scenario(_ s: ScenariGiocoRischio, indice: Int) -> some View {
        let sc = s.scenari[indice]
        let strade = sc.andamento == nil
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Tema.Apple.Studio.Card.spazioProva) {
                Text("Scenario \(indice + 1) di \(s.scenari.count)")
                    .carattereApple(R.etichetta)
                    .foregroundColor(R.coloreEtichetta)
                if s.testiDiProva {
                    Text("testi di prova")
                        .carattereApple(R.prova)
                        .foregroundColor(R.coloreProva)
                }
                Spacer(minLength: R.spazioGrafico)
                Text(s.avvertenza)
                    .carattereApple(R.avvertenza)
                    .foregroundColor(R.coloreAvvertenza)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            if stato.sala.tavoloEsperienza == .giocoRischio {
                Text(TestiRealta.rispondeSulliPad)
                    .carattereApple(R.etichetta)
                    .foregroundColor(R.coloreEtichetta)
                    .padding(.top, R.sopraDomanda)
            }
            Text(sc.domanda)
                .carattereApple(R.domanda)
                .foregroundColor(R.coloreDomanda)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: R.larghezzaDomanda, alignment: .leading)
                .padding(.top, R.sopraDomanda)
                .padding(.bottom, R.sottoDomanda)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            HStack(alignment: .top, spacing: R.spazioGrafico) {
                VStack(alignment: .leading, spacing: 0) {
                    if let finale = MotoreGiocoRischio.valoreFinale(sc) {
                        NumeroCheConta(finale, da: MotoreGiocoRischio.valorePartenza(sc), durata: M.durataLinea)
                            .carattereApple(R.numero)
                            .foregroundColor(MotoreGiocoRischio.scende(sc) ? R.numeroScende : R.numeroSale)
                            .lineLimit(1)
                    }
                    GraficoScenarioRischio(scenario: sc)
                        .frame(height: strade ? R.graficoStrade.height : R.grafico.height)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: Tema.Apple.OpzioneLettera.fraOpzioni) {
                    ForEach(Array(sc.risposte.enumerated()), id: \.offset) { i, testo in
                        OpzioneLettera(lettera: i < Tema.Apple.OpzioneLettera.lettere.count ? Tema.Apple.OpzioneLettera.lettere[i] : "\(i + 1)",
                                       testo: testo, esito: esito(i), larghezza: R.larghezzaRisposte) {
                            rispondi(sc, i)
                        }
                        .opacity(visibili ? 1 : 0)
                        .offset(x: visibili ? 0 : M.spostamentoRisposta)
                        .animation(calmo || istantanea ? nil : M.risposta(indice: i), value: visibili)
                        .allowsHitTesting(visibili && scelta == nil)
                    }
                }
                .frame(width: R.larghezzaRisposte, alignment: .leading)
                .padding(.top, strade ? R.sopraRisposteStrade : R.sopraRisposte)
                #if os(macOS)
                .background {
                    // A, B, C e 1, 2, 3 (§4.1.4): solo con le risposte visibili e nessuna scelta; la vista del palco
                    // fuori dalla presentazione, quella della sala opaca durante (mai tutte e due)
                    if visibili && scelta == nil && consulente == (stato.presentazione == nil) {
                        ScorciatoieRischio(sistema: stato.sistema, quante: sc.risposte.count) { i in rispondi(sc, i) }
                    }
                }
                #endif
            }
            .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Spacer(minLength: 0)
        }
        .task(id: giro) { await attendiRisposte(strade: strade) }
    }

    private func esito(_ i: Int) -> OpzioneLettera.Esito {
        guard let s = scelta else { return .aperta }
        return i == s ? .scelta : .attenuata
    }

    /// Le risposte compaiono 0,2 s dopo la fine del grafico (subito con «Riduci movimento» e nelle istantanee).
    private func attendiRisposte(strade: Bool) async {
        guard !visibili else { return }
        if !(calmo || istantanea) {
            let attesa = (strade ? Tema.Apple.Moto.Linea.durata : M.durataLinea) + M.attesaRisposte
            try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000))
            guard !Task.isCancelled else { return }
        }
        compaiono = Date()
        visibili = true
    }

    private func rispondi(_ sc: ScenarioRischio, _ i: Int) {
        registra(sc, scelta: i, secondi: Date().timeIntervalSince(compaiono))
    }

    /// La parte comune della risposta (dal Mac o dall'iPad del tavolo).
    private func registra(_ sc: ScenarioRischio, scelta i: Int, secondi: Double) {
        guard scelta == nil, visibili, case .scenario(let n) = fase else { return }
        scelta = i
        risposte.removeAll { $0.scenario == sc.id }
        risposte.append(RispostaRischio(scenario: sc.id, scelta: i, secondi: secondi))
        DispatchQueue.main.asyncAfter(deadline: .now() + M.pausaDopoScelta) {
            guard case .scenario(let ora) = fase, ora == n else { return }
            passa(a: .scenario(n + 1))
        }
    }

    private func passa(a nuova: Fase) {
        let cambia = {
            fase = nuova
            scelta = nil
            visibili = false
            giro += 1
        }
        if istantanea { cambia() } else { withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : M.cambioScenario, cambia) }
    }

    private func rifai() {
        risposte = []
        salvata = false
        dataPartita = Date()
        passa(a: .scenario(0))
    }

    // MARK: Il risultato

    private func risultato(_ s: ScenariGiocoRischio) -> some View {
        let nome = StatoShell.nomeBreve(cliente)
        let partita = PartitaRischio(clienteId: cliente.id, data: dataPartita, versioneScenari: s.versione, risposte: risposte)
        let profilo = MotoreGiocoRischio.profilo(partita, scenari: s) ?? .prudente
        let colore = R.colore(profilo)
        let frazione = s.massimo > 0 ? Double(partita.punteggio) / Double(s.massimo) : 0
        return HStack(alignment: .center, spacing: R.spazioRisultato) {
            Anello(frazione: frazione, colore: colore, misura: R.anello, spessore: R.spessoreAnello,
                   ritardo: Tema.Apple.Moto.Anello.ritardoPredefinito) {
                VStack(spacing: 2) {
                    Text("Il profilo che emerge")
                        .carattereApple(R.centroEtichetta)
                        .foregroundColor(R.coloreCentroEtichetta)
                    Text(profilo.nome)
                        .carattereApple(R.nomeProfilo)
                        .foregroundColor(colore)
                        .lineLimit(1)
                        .minimumScaleFactor(R.riduzioneNome)
                }
                .frame(maxWidth: R.larghezzaNome)
            }
            .frame(width: R.colonnaAnello)
            .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            VStack(alignment: .leading, spacing: 0) {
                Text("Come ha reagito \(nome)")
                    .carattereApple(R.titoloRisultato)
                    .foregroundColor(R.coloreTitolo)
                    .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                ForEach(Array(s.scenari.enumerated()), id: \.element.id) { i, sc in
                    if let r = risposte.first(where: { $0.scenario == sc.id }), r.scelta < sc.risposte.count {
                        rigaReazione(sc, r, colore: colore)
                            .entrataCascata(2 + i, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    }
                }
                confronto(profilo, nome: nome)
                    .padding(.top, R.sopraConfronto)
                    .entrataCascata(2 + s.scenari.count, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                Text(s.notaFinale)
                    .carattereApple(R.avvertenzaFinale)
                    .foregroundColor(R.coloreAvvertenza)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, R.sopraAvvertenza)
                    .entrataCascata(3 + s.scenari.count, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                pulsanti(partita, profilo: profilo, nome: nome)
                    .padding(.top, R.sopraPulsanti)
                    .entrataCascata(4 + s.scenari.count, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .confirmationDialog("Salvare il risultato del gioco nel dossier di \(nome)?", isPresented: $confermaSalva) {
            Button("Salva nel dossier") { salva(partita) }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Il profilo di rischio di \(nome) non cambia: resta quello del questionario di adeguatezza firmato.")
        }
    }

    private func rigaReazione(_ sc: ScenarioRischio, _ r: RispostaRischio, colore: Color) -> some View {
        let testo = sc.risposte[r.scelta]
        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: R.rigaReazione) {
                Circle().fill(colore)
                    .frame(width: R.pallino, height: R.pallino)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                (Text("\(sc.etichetta): ").font(R.testoReazioneForte.font)
                    + Text(testo.prefix(1).lowercased() + testo.dropFirst()).font(R.testoReazione.font))
                    .foregroundColor(R.coloreReazione)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: R.rigaReazione)
                if mostraSecondi {
                    Text("ha deciso in \(MotoreGiocoRischio.secondi(r.secondi))")
                        .carattereApple(R.secondi)
                        .foregroundColor(R.coloreSecondi)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, R.rigaReazione)
            Rectangle().fill(R.filo).frame(height: Tema.Apple.Misura.bordo)
        }
    }

    @ViewBuilder
    private func confronto(_ emerso: ProfiloInvestitore.Propensione, nome: String) -> some View {
        let dichiarato = cliente.profilo.propensione
        switch MotoreGiocoRischio.confronto(emerso: emerso, dichiarato: dichiarato) {
        case .nessunDichiarato:
            Text("Il profilo di rischio di \(nome) non è ancora stato raccolto con il questionario.")
                .carattereApple(R.confronto)
                .foregroundColor(R.confrontoUguale)
        case let c:
            Text("Dichiarato nel questionario: \(dichiarato?.nome ?? "") · Emerso dal gioco: \(emerso.nome)")
                .carattereApple(R.confronto)
                .foregroundColor(c == .uguale ? R.confrontoUguale : R.confrontoDiverso)
        }
    }

    private func pulsanti(_ partita: PartitaRischio, profilo: ProfiloInvestitore.Propensione, nome: String) -> some View {
        HStack(spacing: R.spazioPulsanti) {
            Button { rifai() } label: { Text("↻ Rifai il gioco") }
                .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
            if consulente {
                Button { confermaSalva = true } label: { Text(salvata ? "✓ Nel dossier" : "Salva nel dossier") }
                    .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                    .disabled(salvata)
                    .help("Mette la partita nel dossier del cliente: la propensione dichiarata non cambia")
                Button {
                    stato.clienteAttivoId = cliente.id
                    stato.schedaCliente = .profilo
                    stato.apri(.clienti)
                    stato.mostraAvviso("Dal gioco del rischio è emerso: \(profilo.nome). Il profilo si cambia solo con il questionario firmato.")
                } label: { Text("Apri il profilo di \(nome)") }
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                Button { mostraSecondi.toggle() } label: { Text(mostraSecondi ? "Nascondi i secondi" : "Mostra i secondi") }
                    .buttonStyle(.apple)
                    .help("I tempi di decisione si possono nascondere quando il gioco si mostra al cliente")
            }
        }
    }

    private func salva(_ partita: PartitaRischio) {
        guard !salvata else { return }
        var p = partita
        p.vistaDalConsulenteIl = Date()
        stato.dati.partiteRischio.append(p)
        salvata = true
    }
}

// MARK: - Il grafico dello scenario

/// Il grafico di uno scenario: la linea con l'area e il riferimento tratteggiato al valore iniziale (scenari 1-2), o
/// le due strade su dieci anni con il nome in fondo a destra (scenario 3).
/// Il grafico di uno scenario (interno dal giro 16: lo usa anche l'iPad del tavolo).
struct GraficoScenarioRischio: View {
    let scenario: ScenarioRischio

    private typealias R = Tema.Apple.SalaEsperienze.Rischio
    private typealias M = Tema.Apple.Moto.SalaEsperienze.Rischio

    var body: some View {
        GeometryReader { geo in
            let w = max(0, geo.size.width - R.margineEtichette)
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                if let a = scenario.andamento {
                    andamento(a, larghezza: w, altezza: h)
                } else if let strade = scenario.strade {
                    stradeVista(strade, larghezza: w, altezza: h)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// y nel riquadro come `TracciatoGrafico` (10 di margine sopra).
    private static func y(_ normalizzato: Double, altezza h: CGFloat) -> CGFloat {
        h - CGFloat(normalizzato) * max(0, h - Tema.Apple.Grafico.Tracciato.margineAlto)
    }

    @ViewBuilder
    private func andamento(_ a: [Double], larghezza w: CGFloat, altezza h: CGFloat) -> some View {
        let lo = R.dominioMinimo, hi = R.dominioMassimo
        let n = max(1, a.count - 1)
        let punti = a.enumerated().map { CGPoint(x: Double($0.offset) / Double(n), y: ($0.element - lo) / (hi - lo)) }
        let colore = MotoreGiocoRischio.scende(scenario) ? R.lineaScende : R.lineaSale
        let yRif = Self.y((100 - lo) / (hi - lo), altezza: h)
        Path { p in
            p.move(to: CGPoint(x: 0, y: yRif))
            p.addLine(to: CGPoint(x: w, y: yRif))
        }
        .stroke(R.coloreRiferimento, style: StrokeStyle(lineWidth: Tema.Apple.Misura.bordo, dash: R.tratteggioRiferimento))
        Text(scenario.valoreIniziale.map { Formati.euro($0) } ?? "")
            .carattereApple(R.etichettaRiferimento)
            .foregroundColor(R.coloreRiferimento)
            .fixedSize()
            .position(x: w + R.margineEtichette / 2, y: yRif)
        TracciatoGrafico(punti: punti, colore: colore, spessore: R.spessoreLinea, area: true, opacitaArea: R.opacitaArea,
                         durata: M.durataLinea)
            .frame(width: w, height: h)
    }

    @ViewBuilder
    private func stradeVista(_ strade: [StradaRischio], larghezza w: CGFloat, altezza h: CGFloat) -> some View {
        let lo = R.dominioStradeMinimo, hi = R.dominioStradeMassimo
        ForEach(Array(strade.enumerated()), id: \.offset) { i, s in
            let v = MotoreGiocoRischio.punti(s)
            let n = max(1, v.count - 1)
            let punti = v.enumerated().map { CGPoint(x: Double($0.offset) / Double(n), y: ($0.element - lo) / (hi - lo)) }
            let colore = R.coloriStrade[i % R.coloriStrade.count]
            TracciatoGrafico(punti: punti, colore: colore, spessore: R.spessoreLinea, indice: i)
                .frame(width: w, height: h)
            Text(s.nome)
                .carattereApple(R.etichettaStrada)
                .foregroundColor(colore)
                .fixedSize()
                .position(x: w + R.margineEtichette / 2, y: Self.y(Double(punti.last?.y ?? 0), altezza: h))
        }
    }
}

/// I testi della conferma per lasciare il gioco del rischio a metà (§4.1.4).
enum TestiUscitaRischio {
    static let titoloLasciaRischio = "Lasciare il gioco del rischio a metà?"
    static let messaggioTornaRischio = "Le risposte date finora si perdono: il gioco non è salvato nel dossier."
    static let messaggioClienteRischio = "Cambiando cliente le risposte date finora si perdono e il gioco riparte da capo per l’altro cliente."
    static let lasciaRischio = "Lascia il gioco"
    static let continuaRischio = "Continua il gioco"
}

#if os(macOS)
/// Pulsanti invisibili, solo per i tasti: A/B/C e 1/2/3 scelgono la risposta (proposta della §4.1.4, come la palestra
/// della trattativa). Solo con la Sala davanti e senza la ricerca aperta.
private struct ScorciatoieRischio: View {
    let sistema: StatoFinestre
    let quante: Int
    let scegli: (Int) -> Void

    private static let lettere: [Character] = ["a", "b", "c"]
    private static let cifre: [Character] = ["1", "2", "3"]

    var body: some View {
        if sistema.appAttiva == .sala && !sistema.pannelloRicerca {
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
#endif
