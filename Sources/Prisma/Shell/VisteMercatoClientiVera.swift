import SwiftUI

// «Il mercato per i tuoi clienti» (Vera/BRIEF.md, funzione 14; Design/template-vera.html, «// 14 · IL MERCATO PER I
// TUOI CLIENTI»): sotto la risposta di Vera l'elenco dei clienti toccati (avatar, motivo con le cifre di Prisma, la
// pillola di cosa fare, il canale) e «Prepara N messaggi»; in Mercato la scena con il selettore dell'evento, la scheda
// dell'evento a sinistra (titolo, sintesi, fonte) e a destra «Tocca N dei tuoi clienti».
// Movimento: le righe entrano di lato una dopo l'altra (`entrataLaterale`), la scheda dell'evento a cascata; con
// «Riduci movimento» e nelle istantanee tutto è già fermo al suo posto (lo fanno i modificatori del tema).
// Gettoni in DesignSystem/Apple/Tema.Apple+FaseQuattroVera.swift (`Tema.Apple.MercatoClientiVera` e i colori `mercato…`).

private typealias K = Tema.Apple.MercatoClientiVera

// MARK: - Pezzi comuni

/// Il colore della pillola di cosa fare: rosso chiamare oggi, arancio le scadenze e le rate, grigio le due righe, blu il resto.
func coloreAzioneMercatoClientiVera(_ a: AzioneMercatoVera) -> Color {
    switch a {
    case .chiamaOggi: return Tema.Apple.mercatoRosso
    case .rivediBilancio, .decidiScadenza: return Tema.Apple.mercatoArancio
    case .dueRighe: return Tema.Apple.mercatoGrigio
    default: return Tema.Apple.mercatoBlu
    }
}

/// La pillola colorata («Chiama Marco oggi», «Esempio», «Bozze pronte ✓»).
struct PillolaMercatoClientiVera: View {
    let testo: String
    let colore: Color

    var body: some View {
        Text(testo)
            .carattereApple(K.pillola)
            .foregroundColor(colore)
            .lineLimit(1)
            .fixedSize()
            .padding(K.paddingPillola)
            .background { Capsule(style: .continuous).fill(colore.opacity(K.opacitaFondoPillola)) }
    }
}

/// Una riga dell'elenco: avatar (clic: il dossier), nome, motivo con le cifre di Prisma, il canale se è uno solo e la
/// pillola di cosa fare.
struct RigaMercatoClienteVera: View {
    @Environment(StatoShell.self) var stato
    let toccato: ClienteToccatoVera
    var lato: CGFloat = Tema.Apple.MercatoClientiVera.avatar
    var superficie: Tema.Apple.Superficie = Tema.Apple.Superficie.tile

    var body: some View {
        let t = toccato
        let c = stato.cliente(t.clienteId)
        HStack(alignment: .center, spacing: K.spazioRiga) {
            if let c {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: lato)
                    .contentShape(Circle())
                    .onTapGesture { stato.apriCliente(c.id) }
                    .help("Apri il dossier di \(c.nome)")
                    .accessibilityAddTraits(.isButton)
            }
            VStack(alignment: .leading, spacing: K.spazioNomeMotivo) {
                Text(c?.nome ?? t.nome)
                    .carattereApple(K.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                Text(t.motivo)
                    .carattereApple(K.motivo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let canale = t.canale {
                EtichettaCanaleApple(canale: canale, compatta: true)
            }
            PillolaMercatoClientiVera(testo: t.etichettaAzione, colore: coloreAzioneMercatoClientiVera(t.azione))
        }
        .padding(K.paddingRiga)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(superficie, raggio: Tema.Apple.Raggio.tile)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sotto la risposta di Vera

/// L'elenco dei clienti toccati sotto la bolla, con «Prepara N messaggi» (o «Bozze pronte ✓» quando la scheda
/// «Conferma» è già nella conversazione).
struct SchedaMercatoClientiVeraVista: View {
    @Environment(StatoShell.self) var stato
    let esito: EsitoMercatoVera
    /// L'id del messaggio di Vera che contiene l'elenco.
    let messaggio: String

    var body: some View {
        let _ = ContaCorpi.segna()
        let pronte = stato.messaggioVera(messaggio)?.mercatoBozze != nil
        VStack(alignment: .leading, spacing: K.spazioRighe) {
            ForEach(Array(esito.toccati.enumerated()), id: \.element.id) { i, t in
                RigaMercatoClienteVera(toccato: t, lato: K.avatarChat, superficie: Tema.Apple.Vera.SchedaCalcoli.superficie)
                    .entrataLaterale(i)
            }
            if esito.oltre > 0 {
                Text(esito.oltre == 1 ? "E un altro cliente, meno toccato." : "E altri \(esito.oltre) clienti, meno toccati.")
                    .carattereApple(K.nota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            if !esito.toccati.isEmpty, !stato.inModoCliente {
                HStack(spacing: K.spazioRiga) {
                    if pronte {
                        PillolaMercatoClientiVera(testo: "Bozze pronte ✓", colore: Tema.Apple.mercatoVerde)
                    } else {
                        Button(esito.etichettaBozze) { stato.preparaBozzeMercatoClienti(messaggio: messaggio) }
                            .buttonStyle(.applePrimario)
                            .disabled(stato.veraInCorso || stato.solaLettura || !stato.appConsentita(.messaggi))
                            .help("Vera scrive le bozze nel tuo stile; le apri e le spedisci tu, dopo «Conferma».")
                    }
                    Text("Le cifre sono di Prisma: Vera scrive solo le parole.")
                        .carattereApple(K.nota)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(2)
                }
                .padding(.top, K.sopraPiede)
            }
        }
        .padding(.top, K.sopraScheda)
    }
}

// MARK: - La scena in Mercato

/// La scena «Il mercato per i tuoi clienti»: il selettore degli eventi (quelli dei dati di Mercato, poi i tre esempi),
/// la scheda dell'evento e l'elenco dei clienti toccati con «Prepara N messaggi». Con un esempio le bozze no.
struct ScenaMercatoClientiVera: View {
    @Environment(StatoShell.self) var stato
    @State private var scelta: String

    init(sceltaIniziale: String) {
        _scelta = State(initialValue: sceltaIniziale)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let oggi = Date()
        let scelte = stato.scelteMercatoClientiVera(oggi: oggi)
        let attiva = scelte.first { $0.id == scelta } ?? scelte[0]
        let esito = stato.esitoMercatoClientiVera(attiva.evento, oggi: oggi)
        VStack(alignment: .leading, spacing: K.spazioScena) {
            intestazione
            ScrollView(.horizontal, showsIndicators: false) {
                SegmentatoPillola(selezione: Binding(get: { attiva.id }, set: { scelta = $0 }),
                                  voci: scelte.map { ($0.id, $0.etichetta) })
            }
            HStack(alignment: .top, spacing: K.spazioColonne) {
                SchedaEventoMercatoClientiVera(scelta: attiva)
                    .frame(width: K.larghezzaEvento)
                    .id("evento-\(attiva.id)")
                    .entrataCascata(0, base: 0)
                ElencoMercatoClientiVera(esito: esito, esempio: attiva.esempio)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .id("elenco-\(attiva.id)")
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(K.paddingScena)
        .frame(width: K.larghezzaScena, height: K.altezzaScena, alignment: .topLeading)
    }

    private var intestazione: some View {
        HStack(alignment: .firstTextBaseline, spacing: K.spazioRiga) {
            VStack(alignment: .leading, spacing: K.spazioNomeMotivo) {
                Text("Il mercato per i tuoi clienti")
                    .carattereApple(K.titoloScena)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .accessibilityAddTraits(.isHeader)
                Text("Quando succede qualcosa sui mercati, Prisma ti dice quali clienti tocca, perché e cosa conviene fare con ciascuno.")
                    .carattereApple(K.nota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: K.spazioRiga)
            Button("Chiudi") { stato.chiudiMercatoClientiVera() }
                .buttonStyle(.apple)
                .keyboardShortcut(.cancelAction)
        }
    }
}

/// La scheda dell'evento: «Esempio» se lo è, titolo, sintesi e fonte.
private struct SchedaEventoMercatoClientiVera: View {
    let scelta: SceltaMercatoClientiVera

    var body: some View {
        let e = scelta.evento
        VStack(alignment: .leading, spacing: 0) {
            if scelta.esempio {
                PillolaMercatoClientiVera(testo: "Esempio", colore: Tema.Apple.mercatoArancio)
                    .padding(.bottom, K.sopraTitoloEvento)
            }
            Text(e.titolo)
                .carattereApple(K.titoloEvento)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiMercatoClienti.sintesi(e))
                .carattereApple(K.sintesi)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, K.sopraSintesi)
            HStack(spacing: K.spazioFonte) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: K.iconaFonte, weight: .semibold))
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .accessibilityHidden(true)
                Text(scelta.esempio ? "Un esempio per vedere chi toccherebbe" : e.fonte)
                    .carattereApple(K.nota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(2)
            }
            .padding(.top, K.sopraFonte)
        }
        .padding(K.paddingEvento)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.card, raggio: Tema.Apple.Raggio.card)
    }
}

/// «Tocca N dei tuoi clienti» con «Prepara N messaggi» e le righe.
private struct ElencoMercatoClientiVera: View {
    @Environment(StatoShell.self) var stato
    let esito: EsitoMercatoVera
    let esempio: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: K.spazioRiga) {
                Text(esito.intestazione)
                    .carattereApple(K.intestazioneElenco)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                Spacer(minLength: K.spazioRiga)
                if !esito.toccati.isEmpty {
                    Button(esito.etichettaBozze) { stato.preparaBozzeMercatoDaScena(esito) }
                        .buttonStyle(.applePrimario)
                        .disabled(esempio || stato.veraInCorso || stato.solaLettura || !stato.appConsentita(.messaggi))
                        .help(esempio ? "È un esempio: per le bozze dimmi in chat l'evento vero."
                              : "Vera scrive le bozze nel tuo stile; le apri e le spedisci tu, dopo «Conferma».")
                }
            }
            if esito.toccati.isEmpty {
                Text("Nessuna posizione in essere dei tuoi clienti è esposta a questo evento.")
                    .carattereApple(K.sintesi)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: K.spazioRighe) {
                        ForEach(Array(esito.toccati.enumerated()), id: \.element.id) { i, t in
                            RigaMercatoClienteVera(toccato: t)
                                .entrataLaterale(i)
                        }
                        if esito.oltre > 0 {
                            Text(esito.oltre == 1 ? "E un altro cliente, meno toccato." : "E altri \(esito.oltre) clienti, meno toccati.")
                                .carattereApple(K.nota)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                        Text(esempio ? "Le cifre sono calcolate da Prisma sulle posizioni vere dei clienti; l'evento è un esempio."
                             : "Le cifre sono calcolate da Prisma sulle posizioni vere dei clienti.")
                            .carattereApple(K.nota)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, K.sopraElenco)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(K.paddingElenco)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(Tema.Apple.Superficie.card, raggio: Tema.Apple.Raggio.card)
    }
}

// MARK: - Montaggio

/// Il pulsante «Per i tuoi clienti» nella testata di Mercato (mai in modalità cliente).
struct PulsanteMercatoClientiVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        if !stato.inModoCliente {
            Button { stato.apriMercatoClientiVera() } label: {
                Label("Per i tuoi clienti", systemImage: "person.2.wave.2")
            }
            .buttonStyle(.apple)
            .help("Un evento di mercato e i clienti che tocca, con il motivo e cosa fare")
        }
    }
}

/// Presenta la scena come foglio (nelle istantanee disegnata sopra la finestra: i fogli di sistema non entrano
/// nell'immagine). Si monta sul corpo di Mercato con `.scenaMercatoClientiVera()`.
private struct ModificatoreScenaMercatoClientiVera: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaScatto) private var scatto

    func body(content: Content) -> some View {
        let scena = stato.scenaMercatoClientiVera
        let aperta = Binding<Bool>(get: { scena != nil && !scatto }, set: { if !$0 { stato.chiudiMercatoClientiVera() } })
        return content
            .overlay {
                if scatto, let s = scena, !stato.inModoCliente {
                    ZStack {
                        Tema.Apple.Colore.velo
                        ScenaMercatoClientiVera(sceltaIniziale: s)
                            .superficieApple(Tema.Apple.Superficie.dettaglio)
                    }
                }
            }
            .sheet(isPresented: aperta) {
                ScenaMercatoClientiVera(sceltaIniziale: scena ?? "")
                    .environment(stato)
            }
    }
}

extension View {
    /// La scena «Il mercato per i tuoi clienti» sopra Mercato, quando `StatoShell.scenaMercatoClientiVera` non è nil.
    func scenaMercatoClientiVera() -> some View {
        modifier(ModificatoreScenaMercatoClientiVera())
    }
}
