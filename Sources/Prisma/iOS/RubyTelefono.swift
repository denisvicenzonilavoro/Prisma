#if os(iOS)
import SwiftUI

/// Ruby sull'iPhone nel tema Apple (Design/iphone.html, schermata 5): la conversazione dell'app Ruby del Mac a tutta
/// larghezza, con le stesse bolle (`NuvolaRuby`) e la sfera come unico simbolo. Il contesto (di chi si parla e lo stato
/// di Qwen) sta in una riga in alto, gli spunti a capsula e il campo in basso. Risponde Qwen del Mac in Wi‑Fi (PonteRuby):
/// se il Mac non c'è, Ruby lo dice e non risponde. Le cifre le prepara Prisma, qui sul telefono.
struct RubyTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile
    @FocusState private var campoAttivo: Bool

    private typealias M = Tema.Apple.Telefono.Ruby
    private typealias C = Tema.Apple.Ruby.Campo

    private var chiave: String { stato.rubyPortafoglio ? RubyPortafoglio.chiave : stato.clienteAttivoId }
    private var messaggi: [MessaggioRuby] { stato.conversazione(chiave) }

    var body: some View {
        VStack(spacing: 0) {
            testata
            if !stato.disponibilitaLocale.pronto { avviso }
            messaggiVista
                .frame(maxHeight: .infinity)
            spunti
            scrittura
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { stato.nuovaConversazione() } label: { Image(systemName: "square.and.pencil") }
                    .disabled(messaggi.isEmpty && !stato.rubyInCorso)
                    .accessibilityLabel("Nuova conversazione")
            }
        }
        .onAppear { if !stato.disponibilitaLocale.pronto { stato.verificaMotoreLocale() } }
    }

    // MARK: - In alto

    /// Di chi si parla (un cliente o tutto il portafoglio) e lo stato di Qwen sul Mac.
    private var testata: some View {
        let pronto = stato.disponibilitaLocale.pronto
        return HStack(spacing: M.spazio) {
            Menu {
                // In modalità cliente si vede solo il suo dossier: niente portafoglio né altri clienti
                if !stato.inModoCliente {
                    Button { stato.rubyPortafoglio = true } label: { Label("Tutto il portafoglio", systemImage: "square.grid.2x2") }
                }
                Section("Clienti") {
                    ForEach(stato.clienti.sorted { $0.nome < $1.nome }) { c in
                        Button {
                            stato.rubyPortafoglio = false
                            stato.clienteAttivoId = c.id
                        } label: { Text(c.nome) }
                    }
                }
            } label: {
                HStack(spacing: M.spazio) {
                    Text(stato.rubyPortafoglio ? "Tutto il portafoglio" : (stato.clienteAttivo?.nome ?? "Scegli un cliente"))
                        .lineLimit(1)
                    Image(systemName: "chevron.down").imageScale(.small)
                }
                .carattereApple(M.carattereGettone)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .padding(.horizontal, M.paddingGettone)
                .frame(height: M.gettone)
                .background(Capsule(style: .continuous).fill(M.fondoGettone))
                .frame(minHeight: Tema.Apple.Telefono.tocco)
                .contentShape(Rectangle())
            }
            Spacer(minLength: M.spazio)
            HStack(spacing: M.spazio) {
                Circle()
                    .fill(pronto ? M.pronto : M.nonPronto)
                    .frame(width: M.pallino, height: M.pallino)
                Text(pronto ? "Qwen sul Mac" : "Mac non collegato")
                    .carattereApple(M.stato)
                    .foregroundColor(M.coloreStato)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, M.margine)
        .frame(minHeight: M.testata)
    }

    /// Il Mac non risponde: perché e cosa fare, senza rispondere a caso (la card d'avviso arancio del tema).
    private var avviso: some View {
        let forma = RoundedRectangle(cornerRadius: M.raggioAvviso, style: .continuous)
        return VStack(alignment: .leading, spacing: M.spazio) {
            Text("Ruby usa Qwen del tuo Mac")
                .carattereApple(M.titoloAvviso)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Text(stato.disponibilitaLocale.motivo ?? "Cerco il Mac in rete…")
                .carattereApple(M.testoAvviso)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: M.spazio) {
                Button { stato.verificaMotoreLocale() } label: { Label("Riprova", systemImage: "arrow.clockwise") }
                    .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                Button {
                    stato.schedaImpostazioni = .ruby
                    mobile.apri(.impostazioni)
                } label: { Label("Codice del Mac", systemImage: "key") }
                    .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
            }
            .padding(.top, M.spazio / 2)
        }
        .padding(M.paddingAvviso)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(forma.fill(M.fondoAvviso))
        .overlay(forma.strokeBorder(M.bordoAvviso, lineWidth: Tema.Apple.Misura.bordo))
        .padding(.horizontal, M.margine)
        .padding(.bottom, M.spazio)
    }

    // MARK: - Conversazione

    private var messaggiVista: some View {
        ScrollViewReader { lettore in
            ScrollView {
                LazyVStack(spacing: M.spazioMessaggi) {
                    if messaggi.isEmpty && !stato.rubyInCorso { benvenuto }
                    ForEach(messaggi) { msg in
                        NuvolaRuby(messaggio: msg, nomeUtente: stato.nomeUtente, azioniCliente: !stato.rubyPortafoglio,
                                  creaAttivita: { stato.attivitaDaRuby(msg) }, aggiungiNota: { stato.notaDaRuby(msg) },
                                  attivitaProposta: { stato.attivitaDaProposta($0, messaggio: msg.id) },
                                  posizioneProposta: { stato.posizioneDaProposta($0, messaggio: msg.id) },
                                  apriAzione: { stato.apriAzioneRuby($0) },
                                  annullaAzione: { stato.annullaAzioneRuby($0, messaggio: msg.id) })
                            .id(msg.id)
                    }
                    if stato.rubyInCorso {
                        NuvolaInArrivo(flusso: stato.flussoRuby, portafoglio: stato.rubyPortafoglio) {
                            withAnimation { lettore.scrollTo("pensa", anchor: .top) }
                        }
                        .id("pensa")
                    }
                }
                .padding(.horizontal, M.margine)
                .padding(.vertical, M.spazioMessaggi)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messaggi.count) { _ in
                guard let ultimo = messaggi.last else { return }
                withAnimation { lettore.scrollTo(ultimo.id, anchor: ultimo.autore == .utente ? .bottom : .top) }
            }
            .onChange(of: stato.rubyInCorso) { pensa in
                if pensa { withAnimation { lettore.scrollTo("pensa", anchor: .bottom) } }
            }
        }
    }

    /// La conversazione vuota: la sfera viva, la frase e cosa si può chiedere.
    private var benvenuto: some View {
        let ch = Tema.Apple.Ruby.Chat.self
        return VStack(spacing: M.spazioBenvenuto) {
            SferaRuby(misura: M.sferaBenvenuto, viva: stato.disponibilitaLocale.pronto)
                .padding(.bottom, M.spazioBenvenuto)
            Text("Le informazioni ci sono.\nTroviamo il filo.")
                .carattereApple(ch.benvenuto)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Text(stato.rubyPortafoglio
                 ? "Chiedimi del portafoglio: chi ricontattare, cosa scade, la settimana. Le cifre sono quelle di Prisma."
                 : "Chiedimi di \(stato.clienteAttivo?.nome ?? "un cliente"): un riassunto, il check-up, cosa scade, come preparare l'incontro.")
                .carattereApple(ch.benvenutoTesto)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, M.benvenutoSopra)
        .frame(maxWidth: .infinity)
    }

    // MARK: - In basso

    private var spunti: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: C.spazioSuggerimenti) {
                if stato.rubyPortafoglio {
                    ForEach(SpuntoPortafoglio.allCases) { s in
                        Button { invia(s.domanda, portafoglio: s) } label: { PillolaSpuntoRuby(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                    }
                } else {
                    ForEach(SpuntoRuby.allCases) { s in
                        Button { invia(s.domanda, spunto: s) } label: { PillolaSpuntoRuby(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                    }
                }
            }
            .padding(.horizontal, M.margine)
        }
        .disabled(stato.rubyInCorso)
        .padding(.top, M.spazio)
    }

    /// Il campo del tema Apple: capsula `cardPiena` col filo e l'ombra `card`, testo 14,5, l'invio tondo accento.
    private var scrittura: some View {
        let forma = Capsule(style: .continuous)
        let vuota = stato.domandaRuby.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(alignment: .bottom, spacing: C.spazio) {
            TextField("Chiedi a Ruby…", text: $stato.domandaRuby, axis: .vertical)
                .carattereApple(C.testo)
                .foregroundColor(C.coloreTesto)
                .lineLimit(1...5)
                .focused($campoAttivo)
                .submitLabel(.send)
                .onSubmit { invia(stato.domandaRuby) }
                .frame(maxWidth: .infinity, minHeight: C.tasto, alignment: .leading)
            Button { invia(stato.domandaRuby) } label: { Image(systemName: "arrow.up") }
                .buttonStyle(StileTastoRuby(aspetto: .invio))
                .disabled(stato.rubyInCorso || vuota)
                .accessibilityLabel("Invia")
        }
        .padding(C.padding)
        .frame(minHeight: M.campoMinimo)
        .background {
            forma.fill(C.fondo)
                .ombraApple(C.ombra)
        }
        .overlay { forma.strokeBorder(C.bordo, lineWidth: Tema.Apple.Misura.bordo).allowsHitTesting(false) }
        .padding(M.margineCampo)
    }

    private func invia(_ testo: String, spunto: SpuntoRuby? = nil, portafoglio: SpuntoPortafoglio? = nil) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !stato.rubyInCorso else { return }
        campoAttivo = false
        if stato.rubyPortafoglio { stato.chiediRubyPortafoglio(t, spunto: portafoglio) } else { stato.chiediRuby(t, spunto: spunto) }
    }
}
#endif
