import SwiftUI

// Il verbale finale del copilota (Design/template-novita-specifica.md §8.1.4, §8.2.4, §8.4): il dettaglio 940×520 che
// nasce dal pulsante della testata. A sinistra il verbale (riformulato da Vera con Qwen se è pronto, con le stesse cifre,
// altrimenti composto da Prisma dalle schede) e le attività; a destra «Cosa entra nel dossier». Si conferma tutto
// insieme o voce per voce (un clic sulla riga la toglie o la rimette); le voci già confermate durante l'ascolto sono
// già spuntate. «Conserva la trascrizione» è spento di base: alla conferma il testo del cliente si dimentica e resta
// il verbale. Sull'iPad la conferma si dà sul Mac, dove arrivano le schede. Valori in Tema.Apple+Copilota.swift.

@MainActor
struct VerbaleCopilotaVista: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var copilota: StatoCopilotaIncontro
    let clienteId: String
    let incontro: Incontro?

    private typealias V = Tema.Apple.Copilota.Verbale

    var body: some View {
        let _ = ContaCorpi.segna()
        let cliente = stato.cliente(clienteId)
        let nome = cliente?.nome ?? "Cliente"
        let sessione = copilota.sessione(per: clienteId, in: stato)
        let valide = (sessione?.schede ?? []).filter { $0.stato != .scartata }
        let dossier = valide.filter { $0.tipo != .attivita }
        let attivita = valide.filter { $0.tipo == .attivita }
        let punti = dossier.map { "• " + ApplicaCopilota.punto($0) }
        let scelte = sessione.map { copilota.scelte($0) } ?? []
        return VStack(alignment: .leading, spacing: 0) {
            Text("Incontro concluso · \(nome)")
                .carattereApple(V.occhiello)
                .foregroundColor(V.coloreOcchiello)
            Text(incontro?.titolo ?? "Incontro senza appuntamento")
                .carattereApple(V.titolo)
                .foregroundColor(V.coloreTitolo)
                .lineLimit(1)
                // Lo spazio del ✕
                .padding(.trailing, Tema.Apple.Misura.Padding.chiudiDettaglio * 2)
            HStack(alignment: .top, spacing: V.spazioColonne) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        occhiello("Il verbale")
                            .padding(.bottom, V.sottoOcchiello)
                        verbale(punti: punti)
                        firma(punti: punti)
                        occhiello("Le attività")
                            .padding(.top, V.sopraAttivita)
                            .padding(.bottom, V.sottoOcchiello)
                        if attivita.isEmpty {
                            vuoto(TestiCopilota.nessunaAttivita)
                        } else {
                            ForEach(Array(attivita.enumerated()), id: \.element.id) { k, x in
                                voce(x, testo: testoAttivita(x), scelte: scelte, sessione: sessione, ordine: dossier.count + k)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 0) {
                    occhiello("Cosa entra nel dossier")
                        .padding(.bottom, V.sottoOcchielloDossier)
                    if dossier.isEmpty {
                        vuoto(TestiCopilota.nienteNelDossier)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(dossier.enumerated()), id: \.element.id) { k, x in
                                    voce(x, testo: x.azione.nome + ": " + x.titolo, scelte: scelte, sessione: sessione, ordine: k)
                                }
                            }
                        }
                    }
                    if CopilotaIncontro.suIPad {
                        vuoto("Cosa entra nel dossier lo confermi sul Mac, dove arrivano le schede.")
                            .padding(.top, V.sopraAttivita)
                    }
                }
                .frame(width: V.larghezzaDestra, alignment: .topLeading)
            }
            .padding(.top, V.sopraColonne)
            .frame(maxHeight: .infinity, alignment: .top)
            pulsanti(sessione: sessione, scelte: scelte, nome: nome)
                .padding(.top, V.sopraPulsanti)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { scriviConVera(sessione, punti: punti, nome: nome) }
        .onChange(of: punti) { p in scriviConVera(sessione, punti: p, nome: nome) }
    }

    // MARK: Parti

    private func occhiello(_ t: String) -> some View {
        Text(t)
            .carattereApple(Tema.Apple.Carattere.etichetta)
            .foregroundColor(Tema.Apple.Colore.inchiostro2)
            .accessibilityAddTraits(.isHeader)
    }

    private func vuoto(_ t: String) -> some View {
        Text(t)
            .carattereApple(V.vuoto)
            .foregroundColor(V.coloreVuoto)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func verbale(punti: [String]) -> some View {
        if punti.isEmpty {
            vuoto(TestiCopilota.nienteRiconosciuto)
        } else {
            Text(copilota.verbaleVera ?? punti.joined(separator: "\n"))
                .carattereApple(V.testo)
                .foregroundColor(V.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder private func firma(punti: [String]) -> some View {
        if !punti.isEmpty {
            let testo: String = {
                if copilota.verbaleVera != nil { return TestiCopilota.firmaVera }
                if copilota.verbaleVeraInCorso { return TestiCopilota.firmaPrisma + " · Vera lo sta riscrivendo con Qwen…" }
                if !copilota.qwenPronto(stato) { return TestiCopilota.firmaPrisma + " · " + TestiCopilota.veraNonPronta }
                return TestiCopilota.firmaPrisma
            }()
            Text(testo)
                .carattereApple(V.firma)
                .foregroundColor(V.coloreFirma)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, V.sottoOcchiello)
        }
    }

    private func testoAttivita(_ x: SchedaCopilota) -> String {
        guard let d = x.cifre.scadenza else { return x.titolo }
        return x.titolo + " · entro il " + Formati.dataBreve.string(from: d)
    }

    /// Una riga con il pallino: spuntata se è già nel dossier; le altre si scelgono con un clic (sul Mac).
    private func voce(_ x: SchedaCopilota, testo: String, scelte: Set<String>, sessione: SessioneCopilota?, ordine: Int) -> some View {
        let fatta = x.stato == .confermata
        let scelta = fatta || scelte.contains(x.id)
        return VoceVerbaleCopilota(testo: testo, fatta: fatta, scelta: scelta, ordine: ordine,
                                   attiva: !CopilotaIncontro.suIPad && !fatta && sessione != nil) {
            if let s = sessione { copilota.alterna(x.id, in: s) }
        }
    }

    // MARK: I pulsanti

    @ViewBuilder private func pulsanti(sessione: SessioneCopilota?, scelte: Set<String>, nome: String) -> some View {
        let proposte = sessione?.proposte.count ?? 0
        let titolo: String = proposte == 0 ? "Chiudi l’incontro" : (scelte.count == proposte ? "Conferma tutto" : "Conferma le scelte")
        HStack(spacing: V.spazioPulsanti) {
            if CopilotaIncontro.suIPad {
                Button("Manda al Mac") { copilota.mandaAlMac(stato) }
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(copilota.inAttesaPonte == 0 || copilota.invioInCorso)
            } else {
                Button(titolo) { conferma(sessione) }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(sessione == nil || stato.solaLettura || (sessione?.aperta == false && proposte == 0))
            }
            Button("Scrivi il riepilogo a \(TestiCopilota.primoNome(nome))") { riepilogo() }
                .buttonStyle(.appleGrande)
            Button("Più tardi") { copilota.dettaglio.chiudi() }
                .buttonStyle(.appleGrande)
            Spacer(minLength: 0)
            Toggle(isOn: $copilota.conservaTrascrizione) {
                Text(TestiCopilota.conservaTrascrizione)
                    .carattereApple(V.interruttore)
                    .foregroundColor(V.coloreInterruttore)
            }
            .toggleStyle(.apple)
            .fixedSize()
            .disabled(sessione?.aperta != true)
            .help("Spento: alla conferma il testo dell’incontro si dimentica e resta il verbale. Acceso: la trascrizione resta nel dossier (solo testo).")
        }
    }

    // MARK: Fare

    private func conferma(_ s: SessioneCopilota?) {
        guard let s else { return }
        copilota.confermaVerbale(stato, sessione: s)
    }

    /// Messaggi con il riepilogo dell'incontro di quel cliente; le voci non confermate restano in sospeso.
    private func riepilogo() {
        copilota.dettaglio.chiudi(subito: true)
        if let i = incontro, let o = stato.occasioneRiepilogo(i) {
            stato.preparaMessaggio(clienteId: o.clienteId, occasioneId: o.id)
        } else {
            stato.preparaMessaggio(clienteId: clienteId)
        }
    }

    private func scriviConVera(_ s: SessioneCopilota?, punti: [String], nome: String) {
        guard let s else { return }
        copilota.scriviVerbaleConVera(stato, sessione: s, punti: punti, cliente: nome)
    }
}

/// Una riga del verbale (`.prep`): il pallino 20 (vuoto, scelto, o verde con la spunta) e il testo. Le spunte di
/// «Conferma tutto» arrivano una dopo l'altra (0,15 + k·0,26 s, molla 0,35 s); con «Riduci movimento» tutte insieme
/// con la dissolvenza; nelle istantanee già messe.
struct VoceVerbaleCopilota: View {
    let testo: String
    let fatta: Bool
    let scelta: Bool
    let ordine: Int
    let attiva: Bool
    let alterna: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto

    private typealias V = Tema.Apple.Copilota.Verbale

    private var animazione: Animation? {
        if scatto { return nil }
        if calmo { return Tema.Moto.dissolvenzaCalma }
        return Tema.Apple.Moto.Copilota.spunta.delay(Tema.Apple.Moto.Copilota.ritardoSpunta(ordine))
    }

    var body: some View {
        let m = Tema.Apple.Misura.TiPreparo.self
        return Button(action: alterna) {
            HStack(spacing: m.spazio) {
                pallino
                Text(testo)
                    .carattereApple(V.voce)
                    .foregroundColor(scelta ? V.coloreVoce : V.coloreVoceFatta)
                    .strikethrough(!scelta, color: V.coloreVoceFatta)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, m.paddingRiga)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .disabled(!attiva)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Tema.Apple.Colore.separatore)
                .frame(height: Tema.Apple.Misura.bordo)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(testo))
        .accessibilityValue(Text(fatta ? "nel dossier" : (scelta ? "da confermare" : "non entra")))
    }

    private var pallino: some View {
        let m = Tema.Apple.Misura.TiPreparo.self
        let c = Tema.Apple.Colore.self
        return ZStack {
            Circle().fill(fatta ? c.verde : Color.clear)
            Circle().strokeBorder(fatta ? c.verde : (scelta ? c.binario : c.separatore), lineWidth: m.bordoCerchietto)
            SpuntaPiccolaApple()
                .stroke(c.spuntaSuVerde, style: StrokeStyle(lineWidth: m.spuntaTratto, lineCap: .butt, lineJoin: .miter))
                .opacity(fatta ? 1 : 0)
        }
        .frame(width: m.cerchietto, height: m.cerchietto)
        .scaleEffect(fatta && !calmo ? Tema.Apple.Moto.TiPreparo.scalaFatta : 1)
        .animation(animazione, value: fatta)
    }
}
