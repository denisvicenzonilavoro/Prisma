import SwiftUI
import UniformTypeIdentifiers

// Una giornata della pensione (Design/template-luce-specifica.md §4.2, «Luce» giro 4): la pensione mensile stimata
// diventa una giornata. In alto la frase e la cifra grande (si conta), a destra «Senza piano · Con il piano»; sotto le
// scene in fila (ora, tassello, titolo, frase, cifra, esito); poi la striscia con la barra e quanto resta (o manca) al
// mese; in fondo la nota.
//
//   Giulia, a 67 anni · la pensione al mese                       ( Senza piano | Con il piano )
//   1.400 €
//   ┌07:30──┐┌10:00──┐┌16:30──┐┌20:30──┐┌Agosto─┐
//   │ ☕    ││ ⌂     ││ ☺☺    ││ ⑂     ││ ✈     │
//   │…      ││…      ││…      ││…      ││…      │
//   │60 €   ││1.250 €││150 €  ││160 €  ││250 €  │
//   │✓ ci sta││✓ coperte││✕ non ci sta│ …
//   └───────┘└───────┘└───────┘└───────┘└───────┘
//   [██████████████░░░░░░]                     Restano 90 € al mese
//   Stime in euro di oggi…
//
// - Le cifre della pensione vengono da `PensioneEsperienze` (pubblica + piani in essere; «con il piano» + le proposte
//   vere in Posizioni): mai il 3% del template, mai le ipotesi predefinite non confermate (decisioni 75-77).
// - Le voci e i costi li scrive il consulente con il cliente (decisione 83): un clic sulla scena apre il dettaglio
//   (importo, titolo, priorità, togli); le scene si trascinano per cambiare la priorità; fino a 6 scene. La casa e la
//   spesa non si toglie. Senza importi la scena dice «Scrivi con Giulia quanto costa» con il campo: nessuna cifra di
//   ripiego. Le spese fisse si precompilano dal fabbisogno di oggi solo se l'area Protezione è confermata, e
//   comunque «da confermare».
// - Movimento: cifra che si conta (0,9 s ai cambi), barra che si allarga, solo la scena il cui esito cambia gira su sé
//   stessa (0,62 s, passo 0,08 da sinistra) e si spegne. «Riduci movimento»: dissolvenza di 0,15 s. Istantanee: stato
//   finale della modalità scelta.

/// Il contenuto del palco per una giornata della pensione.
struct GiornataPensioneVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Nella presentazione e sul tavolo la giornata si guarda, non si modifica.
    var modificabile = true

    @State private var conPiano: Bool
    @State private var scenaAperta: String?

    private typealias G = Tema.Apple.SalaEsperienze.Giornata

    init(cliente: Cliente, conPiano: Bool, modificabile: Bool = true) {
        self.cliente = cliente
        self.modificabile = modificabile
        self._conPiano = State(initialValue: conPiano)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let nome = StatoShell.nomeBreve(cliente)
        let analisi = stato.dati.analisi[cliente.id]
        let calcolo = PensioneEsperienze.calcola(cliente: cliente, posizioni: stato.posizioniCliente(cliente.id), analisi: analisi)
        let giornata = analisi?.giornata ?? MotoreGiornataPensione.daCompilare(fabbisognoConfermato: Self.fabbisogno(analisi))
        let cifre: CifrePensioneEsperienze? = { if case .pronto(let c) = calcolo { return c } else { return nil } }()
        let pensione: Double? = conPiano ? cifre?.conPiano : cifre?.senzaPiano
        let esito = pensione.map { MotoreGiornataPensione.calcola(giornata, pensione: $0) }
        let esitoSenza = cifre.map { MotoreGiornataPensione.calcola(giornata, pensione: $0.senzaPiano) }
        let voci = giornata.voci.sorted { $0.priorita < $1.priorita }

        VStack(alignment: .leading, spacing: 0) {
            testa(nome: nome, calcolo: calcolo, cifre: cifre, pensione: pensione, giornata: giornata)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            HStack(alignment: .top, spacing: G.spazioScene) {
                ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                    SchedaScena(voce: v, indice: i, esito: esito?.scene.first { $0.voce.id == v.id }, nome: nome,
                                modificabile: modificabile, aperta: legame(v.id),
                                scrivi: { importo in scrivi(importo, voce: v.id) },
                                modifica: { cambia in modifica(v.id, cambia) },
                                togli: { togli(v.id) },
                                sposta: { daId in sposta(daId, prima: v.id) })
                        .frame(maxWidth: .infinity)
                        .entrataCascata(1 + i, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
            }
            // Le scene alte quanto serve (almeno 270), non stirate fino in fondo
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, G.sottoTesta)
            // Senza nessun importo scritto la striscia non dice nulla: niente «restano» di ripiego
            if let esito, !giornata.daCompilare {
                StrisciaResto(esito: esito, esitoSenza: conPiano ? esitoSenza : nil, voci: giornata.voci)
                    .padding(.top, G.sopraStriscia)
                    .entrataCascata(1 + voci.count, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            piede(giornata: giornata, voci: voci)
                .padding(.top, G.sopraNota)
            Spacer(minLength: 0)
        }
        .padding(G.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: conPiano) { stato.sala.giornataConPiano = $0 }
    }

    // MARK: Testa

    @ViewBuilder
    private func testa(nome: String, calcolo: PensioneEsperienze.Esito, cifre: CifrePensioneEsperienze?, pensione: Double?,
                       giornata: GiornataPensione) -> some View {
        HStack(alignment: .bottom, spacing: G.spazioTesta) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Tema.Apple.Studio.Card.spazioProva) {
                    Text(cifre.map { "\(nome), a \($0.etaPensione) anni · la pensione al mese" } ?? "\(nome) · la pensione al mese")
                        .carattereApple(G.frase)
                        .foregroundColor(G.coloreFrase)
                    if giornata.diProva == true {
                        Text("dati di prova")
                            .carattereApple(G.etichettaStato)
                            .foregroundColor(G.coloreEtichettaStato)
                    }
                }
                .lineLimit(1)
                if let pensione {
                    NumeroCheConta(pensione, da: 0, durata: Tema.Apple.Moto.NumeroCambio.durata)
                        .carattereApple(G.pensione)
                        .foregroundColor(G.colorePensione)
                        .lineLimit(1)
                } else {
                    statoSenzaCifra(nome: nome, calcolo: calcolo)
                }
            }
            Spacer(minLength: G.spazioTesta)
            SegmentatoPillola(selezione: $conPiano, voci: [(false, "Senza piano"), (true, "Con il piano")])
                .fixedSize()
                .padding(.bottom, G.sottoSegmentato)
                .help("Senza piano: la pensione pubblica e i piani che ha già. Con il piano: anche le proposte di previdenza in Posizioni")
        }
    }

    /// Al posto della cifra grande: perché non c'è (dati mancanti, ipotesi da confermare, nessun piano in proposta).
    @ViewBuilder
    private func statoSenzaCifra(nome: String, calcolo: PensioneEsperienze.Esito) -> some View {
        let frase = PensioneEsperienze.frase(calcolo, nome: nome)
            ?? "Nessun piano per la pensione in proposta per \(nome): preparalo in Posizioni."
        let versoPosizioni = PensioneEsperienze.frase(calcolo, nome: nome) == nil
        VStack(alignment: .leading, spacing: G.spazioStato) {
            Text(frase)
                .carattereApple(G.stato)
                .foregroundColor(G.coloreStato)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: G.larghezzaStato, alignment: .leading)
            if modificabile {
                Button {
                    if versoPosizioni {
                        stato.clienteAttivoId = cliente.id
                        stato.apri(.posizioni)
                    } else {
                        stato.clienteAttivoId = cliente.id
                        stato.areaAnalisi = .previdenza
                        stato.apri(.analisi360)
                    }
                } label: { Text(versoPosizioni ? "Apri Posizioni" : "Apri Analisi 360 › Previdenza") }
                    .buttonStyle(.apple)
            }
        }
        .padding(.top, G.spazioStato)
    }

    // MARK: Piede

    private func piede(giornata: GiornataPensione, voci: [VoceGiornata]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: G.spazioStriscia) {
            Text("Stime in euro di oggi, dalla pensione pubblica stimata, dai piani che ha già e, con il piano, dalle proposte di previdenza in Posizioni. Non sono garanzie.")
                .carattereApple(G.nota)
                .foregroundColor(G.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if modificabile && voci.count < MotoreGiornataPensione.massimoVoci {
                Button { aggiungi() } label: { Text("＋ Aggiungi una scena") }
                    .buttonStyle(.apple)
                    .help("Una scena in più della giornata, da scrivere con il cliente (al massimo \(MotoreGiornataPensione.massimoVoci))")
            }
        }
    }

    // MARK: Modifiche (sempre nell'Analisi 360 del cliente)

    private func legame(_ id: String) -> Binding<Bool> {
        Binding(get: { scenaAperta == id }, set: { scenaAperta = $0 ? id : nil })
    }

    private func scrivi(_ importo: Double?, voce id: String) {
        modifica(id) { v in
            v.importoMensile = importo
            v.daConfermare = nil
        }
    }

    private func modifica(_ id: String, _ cambia: (inout VoceGiornata) -> Void) {
        stato.modificaGiornata(cliente.id) { g in
            guard let i = g.voci.firstIndex(where: { $0.id == id }) else { return }
            cambia(&g.voci[i])
        }
    }

    private func togli(_ id: String) {
        scenaAperta = nil
        stato.modificaGiornata(cliente.id) { g in
            g.voci.removeAll { $0.id == id && !$0.fissa }
            g.voci = MotoreGiornataPensione.riordina(g.voci.sorted { $0.priorita < $1.priorita })
        }
    }

    private func sposta(_ id: String, prima di: String) {
        guard id != di else { return }
        stato.modificaGiornata(cliente.id) { g in
            g.voci = MotoreGiornataPensione.sposta(g.voci.sorted { $0.priorita < $1.priorita }, id: id, prima: di)
        }
    }

    private func aggiungi() {
        let id = "scena-\(UUID().uuidString.prefix(8))"
        stato.modificaGiornata(cliente.id) { g in
            guard g.voci.count < MotoreGiornataPensione.massimoVoci else { return }
            g.voci.append(VoceGiornata(id: id, quando: "", titolo: "Una scena nuova", frase: "da scrivere con il cliente",
                                       glifo: GlifoScena.sole.rawValue, priorita: (g.voci.map(\.priorita).max() ?? -1) + 1))
        }
        scenaAperta = id
    }

    /// Il fabbisogno mensile di oggi, solo se l'area Protezione è confermata con il cliente.
    static func fabbisogno(_ a: Analisi360?) -> Double? {
        guard let a, a.confermate.contains(.protezione) else { return nil }
        return a.protezione.fabbisognoMensile
    }
}

extension StatoShell {
    /// Cambia la giornata della pensione del cliente nella sua Analisi 360 (creata se manca, con la giornata da
    /// compilare se non c'è ancora). Togliere i dati di prova: la prima modifica a mano la rende una giornata vera.
    func modificaGiornata(_ clienteId: String, _ cambia: (inout GiornataPensione) -> Void) {
        var a = dati.analisi[clienteId] ?? Analisi360(cliente: cliente(clienteId), posizioni: posizioniCliente(clienteId))
        var g = a.giornata ?? MotoreGiornataPensione.daCompilare(fabbisognoConfermato: GiornataPensioneVista.fabbisogno(a))
        cambia(&g)
        g.aggiornataIl = Date()
        g.diProva = nil
        a.giornata = g
        dati.analisi[clienteId] = a
    }
}

// MARK: - La scena

/// Una scena della giornata: ora, tassello, titolo, frase, cifra ed esito. Si spegne se non ci sta; gira su sé stessa
/// quando l'esito cambia.
private struct SchedaScena: View {
    let voce: VoceGiornata
    let indice: Int
    let esito: EsitoGiornata.Scena?
    let nome: String
    let modificabile: Bool
    @Binding var aperta: Bool
    let scrivi: (Double?) -> Void
    let modifica: ((inout VoceGiornata) -> Void) -> Void
    let togli: () -> Void
    let sposta: (String) -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var mostrato: StatoScena?
    @State private var precedente: StatoScena?
    @State private var angolo: Double = 0
    @State private var testoImporto = ""
    @State private var bersaglio = false

    private typealias G = Tema.Apple.SalaEsperienze.Giornata
    private typealias M = Tema.Apple.Moto.SalaEsperienze.Giornata

    init(voce: VoceGiornata, indice: Int, esito: EsitoGiornata.Scena?, nome: String, modificabile: Bool,
         aperta: Binding<Bool>, scrivi: @escaping (Double?) -> Void, modifica: @escaping ((inout VoceGiornata) -> Void) -> Void,
         togli: @escaping () -> Void, sposta: @escaping (String) -> Void) {
        self.voce = voce
        self.indice = indice
        self.esito = esito
        self.nome = nome
        self.modificabile = modificabile
        self._aperta = aperta
        self.scrivi = scrivi
        self.modifica = modifica
        self.togli = togli
        self.sposta = sposta
    }

    /// L'esito come si disegna.
    enum StatoScena: Equatable { case ciSta, nonCiSta, senzaImporto, senzaPensione }

    private var statoAttuale: StatoScena {
        guard let esito else { return voce.importoMensile == nil ? .senzaImporto : .senzaPensione }
        if esito.senzaImporto { return .senzaImporto }
        return esito.ciSta ? .ciSta : .nonCiSta
    }

    var body: some View {
        let s = mostrato ?? statoAttuale
        let spenta = s == .nonCiSta
        let forma = RoundedRectangle(cornerRadius: G.raggioScena, style: .continuous)
        VStack(alignment: .leading, spacing: G.spazioScena) {
            VStack(alignment: .leading, spacing: G.spazioScena) {
                Text(voce.quando.isEmpty ? " " : voce.quando)
                    .carattereApple(G.ora)
                    .foregroundColor(G.coloreOra)
                tassello
                    .padding(.top, G.sopraTassello)
                    .padding(.bottom, G.sottoTassello)
                Text(voce.titolo)
                    .carattereApple(G.titolo)
                    .foregroundColor(G.coloreTitolo)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(voce.frase)
                    .carattereApple(G.fraseScena)
                    .foregroundColor(G.coloreFraseScena)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(spenta ? G.opacitaSpenta : 1)
            .grayscale(spenta ? G.grigioSpenta : 0)
            Spacer(minLength: G.spazioScena)
            cifra(s, spenta: spenta)
        }
        .padding(G.paddingScena)
        .frame(maxWidth: .infinity, minHeight: G.altezzaScena, alignment: .topLeading)
        .background(forma.fill(G.fondoScena))
        .overlay(forma.strokeBorder(bersaglio ? Tema.Apple.Colore.accento : G.filoScena, lineWidth: G.bordoScena))
        .contentShape(forma)
        .rotation3DEffect(.degrees(angolo), axis: (x: 0, y: 1, z: 0), perspective: G.altezzaScena / M.prospettiva)
        .onTapGesture { if modificabile { aperta = true } }
        .popover(isPresented: $aperta, arrowEdge: .bottom) {
            DettaglioScena(voce: voce, nome: nome, modifica: modifica, togli: togli, chiudi: { aperta = false })
        }
        .modifier(TrascinaScena(attivo: modificabile, id: voce.id, bersaglio: $bersaglio, sposta: sposta))
        .onAppear { precedente = statoAttuale }
        .onChange(of: statoAttuale) { cambia(a: $0) }
        .help(modificabile ? "Clic per scrivere con \(nome) quanto costa e quanto conta; trascina per cambiare la priorità" : "")
        .accessibilityElement(children: .combine)
    }

    private var tassello: some View {
        let forma = RoundedRectangle(cornerRadius: G.raggioTassello, style: .continuous)
        let g = GlifoScena(rawValue: voce.glifo) ?? .sole
        return ZStack {
            forma.fill(g.colore).ombraApple(.tasselloScena)
            GlifoScenaVista(glifo: g, lato: G.glifo, tratto: G.trattoGlifo)
        }
        .frame(width: G.tassello, height: G.tassello)
    }

    @ViewBuilder
    private func cifra(_ s: StatoScena, spenta: Bool) -> some View {
        if let importo = voce.importoMensile {
            HStack(spacing: Tema.Apple.Studio.Card.spazioProva) {
                Text("\(Formati.euro(importo)) al mese")
                    .carattereApple(G.cifra)
                    .foregroundColor(G.coloreCifra)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .opacity(spenta ? G.opacitaSpenta : 1)
            if voce.daConfermare == true {
                Text("da confermare")
                    .carattereApple(G.etichettaStato)
                    .foregroundColor(G.coloreEtichettaStato)
            }
            esitoTesto(s)
        } else {
            Text("Scrivi con \(nome) quanto costa")
                .carattereApple(G.invito)
                .foregroundColor(G.coloreInvito)
                .fixedSize(horizontal: false, vertical: true)
            if modificabile {
                TextField("€ al mese", text: $testoImporto)
                    .textFieldStyle(.plain)
                    .carattereApple(G.campo)
                    .padding(G.paddingCampo)
                    .background(RoundedRectangle(cornerRadius: G.raggioCampo, style: .continuous).fill(G.fondoCampo))
                    .onSubmit { scrivi(Self.importo(testoImporto)) }
            }
        }
    }

    @ViewBuilder
    private func esitoTesto(_ s: StatoScena) -> some View {
        switch s {
        case .ciSta:
            Text(voce.fissa ? "✓ coperte" : "✓ ci sta").carattereApple(G.esito).foregroundColor(G.ciSta)
        case .nonCiSta:
            Text(voce.fissa ? "✕ non coperte" : "✕ non ci sta").carattereApple(G.esito).foregroundColor(G.nonCiSta)
        case .senzaImporto, .senzaPensione:
            EmptyView()
        }
    }

    /// Il cambio di esito: solo questa scena gira (0 → 90° → 0) con il contenuto che cambia a metà giro; con «Riduci
    /// movimento» la dissolvenza, nelle istantanee subito.
    private func cambia(a nuovo: StatoScena) {
        let vecchio = precedente ?? nuovo
        precedente = nuovo
        guard !istantanea else {
            mostrato = nil
            return
        }
        let gira = (vecchio == .ciSta && nuovo == .nonCiSta) || (vecchio == .nonCiSta && nuovo == .ciSta)
        guard gira, !calmo else {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : M.spegnimento) { mostrato = nil }
            return
        }
        let ritardo = Double(indice) * M.passoGiro
        mostrato = vecchio
        withAnimation(M.mezzoGiro(ritardo: ritardo)) { angolo = M.angoloGiro }
        DispatchQueue.main.asyncAfter(deadline: .now() + ritardo + M.giro / 2) {
            withAnimation(M.spegnimento) { mostrato = nil }
            withAnimation(M.mezzoGiro(ritardo: 0)) { angolo = 0 }
        }
    }

    /// «1.250», «1250 €», «60,5» → euro; vuoto o illeggibile = nessun importo.
    static func importo(_ testo: String) -> Double? {
        let pulito = testo.replacingOccurrences(of: "€", with: "").replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        guard let v = Double(pulito), v >= 0, v.isFinite else { return nil }
        return v
    }
}

/// Trascinare una scena sopra un'altra: la priorità cambia (decisione 83). Solo dove la giornata si modifica.
private struct TrascinaScena: ViewModifier {
    let attivo: Bool
    let id: String
    @Binding var bersaglio: Bool
    let sposta: (String) -> Void

    func body(content: Content) -> some View {
        if attivo {
            content
                .onDrag { NSItemProvider(object: id as NSString) }
                .onDrop(of: [UTType.plainText, UTType.text], isTargeted: $bersaglio) { fornitori in
                    guard let f = fornitori.first else { return false }
                    _ = f.loadObject(ofClass: NSString.self) { oggetto, _ in
                        guard let altro = oggetto as? NSString else { return }
                        let s = String(altro)
                        DispatchQueue.main.async { sposta(s) }
                    }
                    return true
                }
        } else {
            content
        }
    }
}

/// Il dettaglio di una scena: l'importo scritto con il cliente, il titolo, la frase, l'ora; prima o dopo nella
/// priorità; togliere (non la casa e la spesa).
private struct DettaglioScena: View {
    let voce: VoceGiornata
    let nome: String
    let modifica: ((inout VoceGiornata) -> Void) -> Void
    let togli: () -> Void
    let chiudi: () -> Void

    @State private var importo = ""
    @State private var titolo = ""
    @State private var frase = ""
    @State private var quando = ""

    private typealias G = Tema.Apple.SalaEsperienze.Giornata

    var body: some View {
        VStack(alignment: .leading, spacing: G.spazioDettaglio) {
            Text(voce.fissa ? "Le spese di tutti i mesi" : "La scena della giornata")
                .carattereApple(G.titoloDettaglio)
            campo("Quanto costa al mese (euro di oggi), scritto con \(nome)", testo: $importo, segnaposto: "€ al mese")
            campo("Titolo", testo: $titolo, segnaposto: "La colazione al bar")
            campo("Frase", testo: $frase, segnaposto: "con gli amici di sempre")
            campo("Quando", testo: $quando, segnaposto: "07:30")
            HStack(spacing: G.spazioDettaglio) {
                if !voce.fissa {
                    Button("Togli la scena") { togli() }
                        .buttonStyle(.apple)
                }
                Spacer(minLength: 0)
                Button("Fatto") { salva() }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
            }
            Text("La priorità si cambia trascinando le scene: si pagano da sinistra, dopo le spese di tutti i mesi.")
                .carattereApple(G.etichettaDettaglio)
                .foregroundColor(G.coloreInvito)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(G.paddingDettaglio)
        .frame(width: G.larghezzaDettaglio)
        .onAppear {
            importo = voce.importoMensile.map { Formati.euro($0).replacingOccurrences(of: " €", with: "") } ?? ""
            titolo = voce.titolo
            frase = voce.frase
            quando = voce.quando
        }
    }

    private func campo(_ etichetta: String, testo: Binding<String>, segnaposto: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etichetta)
                .carattereApple(G.etichettaDettaglio)
                .foregroundColor(G.coloreInvito)
                .fixedSize(horizontal: false, vertical: true)
            TextField(segnaposto, text: testo)
                .textFieldStyle(.roundedBorder)
                .onSubmit { salva() }
        }
    }

    private func salva() {
        let nuovo = SchedaScena.importo(importo)
        let cambiato = nuovo != voce.importoMensile
        modifica { v in
            v.importoMensile = nuovo
            if cambiato { v.daConfermare = nil }
            v.titolo = titolo.trimmingCharacters(in: .whitespaces).isEmpty ? v.titolo : titolo
            v.frase = frase
            v.quando = quando
        }
        chiudi()
    }
}

// MARK: - La striscia

/// La barra (spese fisse grigio-azzurre e scene verdi sul binario) e quanto resta o manca al mese.
private struct StrisciaResto: View {
    let esito: EsitoGiornata
    /// Con il piano: l'esito senza piano, per dire di quanto cresce il resto.
    let esitoSenza: EsitoGiornata?
    let voci: [VoceGiornata]

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias G = Tema.Apple.SalaEsperienze.Giornata

    var body: some View {
        let p = max(esito.pensione, 1)
        let fisse = min(esito.fisse, p)
        let scene = min(esito.usate, max(0, p - fisse))
        HStack(spacing: G.spazioStriscia) {
            BarraPienaSegmenti(pezzi: [
                PezzoBarraPiena(id: "fisse", peso: fisse, colore: G.coloreFisse),
                PezzoBarraPiena(id: "scene", peso: scene, colore: G.coloreScene),
                PezzoBarraPiena(id: "resto", peso: max(0, p - fisse - scene), colore: G.binario)
            ], altezza: G.altezzaBarra, spazio: 0, raggioPezzo: 0, raggioContenitore: G.raggioBarra)
            .animation(calmo || istantanea ? nil : Tema.Apple.Moto.Barra.animazione, value: esito.usate)
            .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 2) {
                resto
                    .lineLimit(1)
                if let riga = rigaSotto {
                    Text(riga)
                        .carattereApple(G.manca)
                        .foregroundColor(G.coloreManca)
                        .lineLimit(1)
                }
            }
            .fixedSize()
        }
        .padding(G.paddingStriscia)
        .superficieApple(G.superficieStriscia, raggio: G.raggioStriscia)
    }

    private var resto: some View {
        let f = G.resto.font
        let testo: Text
        if esito.resto >= 0 {
            testo = Text("Restano ").font(f).foregroundColor(G.coloreResto)
                + Text(Formati.euro(esito.resto)).font(f).foregroundColor(G.colorePositivo)
                + Text(" al mese").font(f).foregroundColor(G.coloreResto)
        } else {
            let fissa = voci.first(where: \.fissa)?.titolo ?? "le spese fisse"
            let quale = esito.fisseCoperte ? "" : " solo per " + fissa.prefix(1).lowercased() + fissa.dropFirst()
            testo = Text("Mancano ").font(f).foregroundColor(G.coloreResto)
                + Text(Formati.euro(-esito.resto)).font(f).foregroundColor(G.coloreMancano)
                + Text(" al mese\(quale)").font(f).foregroundColor(G.coloreResto)
        }
        return testo
    }

    /// Sotto: quanto manca per tutta la giornata, o di quanto il piano fa crescere il resto quando ci stava già tutto.
    private var rigaSotto: String? {
        if esito.fisseCoperte, esito.mancaPerTutto > 0 {
            return "Per vivere tutta la giornata mancano \(Formati.euro(esito.mancaPerTutto)) al mese"
        }
        if let s = esitoSenza, s.mancaPerTutto == 0, esito.resto > s.resto {
            return "Con il piano \(Formati.euro(esito.resto - s.resto)) in più al mese"
        }
        return nil
    }
}
