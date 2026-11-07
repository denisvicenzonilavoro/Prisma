#if os(macOS)
import AppKit
#endif
import SwiftUI

/// App Ruby nel tema Apple (Design/template-apple-specifica.md §4.7, PIE e01…e10): a sinistra la colonna di Ruby
/// (la sfera grande che respira, «Ciao, sono Ruby.», lo stato vero di Qwen, la card «Oggi», di chi si parla, cosa non
/// dimenticare e il quadro del cliente), a destra la chat con le bolle, i suggerimenti e il campo a capsula.
/// La testata della finestra ha il selettore «Lavoro / Conversazione» e «Nuova conversazione» (`AzioniRuby`).
/// Ruby risponde con Qwen sul Mac; i numeri li calcola sempre Prisma, Ruby li legge e li racconta.
/// Sequenza di una domanda: la bolla dell'utente entra a molla, compaiono i puntini e la sfera pulsa, il testo arriva
/// parola per parola e alla fine entra la scheda dei calcoli.
struct AppRuby: View {
    @EnvironmentObject var stato: StatoShell
    /// Il campo della domanda in primo piano: serve alla dettatura di macOS, che scrive dove c'è il cursore.
    @FocusState private var campoAttivo: Bool
    /// Da quale messaggio in poi le bolle sono nuove (arrivate con l'app aperta): entrano e si scrivono.
    @State private var nuoviDa: SegnoNuoviRuby?

    private var cliente: Cliente? { stato.clienteAttivo }
    private var chiave: String { stato.rubyPortafoglio ? RubyPortafoglio.chiave : stato.clienteAttivoId }
    private var messaggi: [MessaggioRuby] { stato.conversazione(chiave) }

    /// Il punto in fondo alla chat: a ogni parola la chat scorre lì.
    private static let fondo = "fondo-chat-ruby"

    private func invia(_ testo: String) {
        if stato.rubyPortafoglio { stato.chiediRubyPortafoglio(testo) } else { stato.chiediRuby(testo) }
    }

    var body: some View {
        let col = Tema.Apple.Ruby.Colonna.self
        GeometryReader { geo in
            // Ruby a metà schermo: la colonna si stringe e la chat resta sempre dentro la finestra
            let larghezza = geo.size.width < Tema.Misura.RubyChat.sogliaContestoStretto ? Tema.Misura.RubyChat.contestoStretto : col.larghezza
            HStack(spacing: col.spazioChat) {
                colonna(larghezza: larghezza)
                    .frame(width: larghezza)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .pannelloAltreAppApple()
                chat
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .altreAppApple()
        // Parte sia alla nascita della vista (Ruby era chiusa o ridotta) sia a ogni nuova richiesta
        .task(id: stato.richiestaDettatura) { await accendiDettatura() }
        // Il FocusState resta in pari con makeFirstResponder(nil), altrimenti il prossimo «true» non cambia niente
        .onChange(of: stato.dettaturaAttiva) { attiva in if !attiva { campoAttivo = false } }
        .onAppear { segnaNuovi() }
        .onChange(of: chiave) { _ in segnaNuovi() }
        .onChange(of: messaggi.count) { n in
            // «Nuova conversazione»: le bolle che arrivano dopo sono di nuovo nuove
            if let s = nuoviDa, s.chiave == chiave, n < s.indice { nuoviDa = SegnoNuoviRuby(chiave: chiave, indice: n) }
        }
    }

    /// Le bolle già nella conversazione si vedono ferme; quelle che arrivano da adesso entrano.
    private func segnaNuovi() {
        nuoviDa = SegnoNuoviRuby(chiave: chiave, indice: messaggi.count)
    }

    /// La dettatura di macOS scrive dove c'è il cursore: prima il campo (riaffermato, con qualche tentativo),
    /// poi «Avvia dettatura». `sendAction` risponde sempre true (lo gestisce NSApplication): l'esito si legge
    /// dal contesto di testo in primo piano.
    private func accendiDettatura() async {
        guard stato.richiestaDettatura > 0, stato.dettaturaAttiva else { return }
        #if os(macOS)
        campoAttivo = false
        for tentativo in 1...4 {
            try? await Task.sleep(nanoseconds: tentativo == 1 ? 100_000_000 : 300_000_000)
            guard !Task.isCancelled, stato.dettaturaAttiva else { return }
            campoAttivo = true
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled, stato.dettaturaAttiva else { return }
            if NSTextInputContext.current != nil {
                DiagnosticaVoce.annota("Dettatura di macOS: campo pronto al tentativo \(tentativo), mando «Avvia dettatura»")
                NSApp.sendAction(Selector(("startDictation:")), to: nil, from: nil)
                return
            }
            let primo = NSApp.keyWindow?.firstResponder.map { String(describing: type(of: $0)) } ?? "nessuno"
            DiagnosticaVoce.annota("Dettatura di macOS: il campo non ha il cursore (tentativo \(tentativo), primo risponditore \(primo))")
        }
        stato.dettaturaNonPartita()
        #elseif os(iOS)
        // Su iPhone e iPad la dettatura è il tasto microfono della tastiera: basta il cursore nel campo
        campoAttivo = true
        DiagnosticaVoce.annota("iPhone e iPad: cursore nel campo, la dettatura è il microfono della tastiera")
        #endif
    }

    // MARK: - Colonna di sinistra

    private func colonna(larghezza: CGFloat) -> some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let interna = larghezza - col.padding.leading - col.padding.trailing
        // Senza barra di scorrimento; in fondo le card sfumano invece di finire tagliate
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                SferaRuby(misura: Tema.Apple.Ruby.Sfera.ruby, viva: true, pensa: stato.rubyInCorso)
                Text("Ciao, sono Ruby.")
                    .carattereApple(col.saluto)
                    .foregroundColor(col.coloreSaluto)
                    .padding(.top, col.salutoSopra)
                Text("Mettiamo in ordine le idee.")
                    .carattereApple(col.motto)
                    .foregroundColor(col.coloreMotto)
                VStack(spacing: col.fraSchede) {
                    schedaMotore
                    schedaOggi
                    schedaAmbito(larghezza: interna - col.paddingScheda.leading - col.paddingScheda.trailing)
                    if let t = urgente { schedaAvviso(t) }
                    if let c = cliente, !stato.rubyPortafoglio { quadro(c) }
                }
                .padding(.top, col.primaScheda)
            }
            .multilineTextAlignment(.center)
            .padding(col.padding)
            .padding(.bottom, col.sfumatura / 2)
            .frame(maxWidth: .infinity)
        }
        .sfumaturaBordiScorrimento(sotto: col.sfumatura)
    }

    /// Lo stato vero di Qwen: pronto («I numeri li calcola Prisma, io li racconto.») o non pronto, e allora Ruby non
    /// risponde e lo dice, con «Verifica».
    private var schedaMotore: some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let q = stato.qwen
        let pronto = q.disponibilita.pronto
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: col.spazioSpia) {
                Circle()
                    .fill(pronto ? col.pronto : col.nonPronto)
                    .frame(width: col.spia, height: col.spia)
                Text("\(q.nome) · \(pronto ? "pronto" : "non pronto")")
                    .carattereApple(col.statoMotore)
                    .foregroundColor(col.coloreTesto)
                    .lineLimit(1)
            }
            Text(pronto ? "I numeri li calcola Prisma, io li racconto." : (q.disponibilita.motivo ?? q.descrizione))
                .carattereApple(col.notaMotore)
                .foregroundColor(col.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, col.notaSopra)
            if !pronto {
                Button { stato.verificaMotoreLocale() } label: { Label("Verifica", systemImage: "arrow.clockwise") }
                    .buttonStyle(.apple)
                    .fixedSize()
                    .help("Chiede di nuovo a Ollama se Qwen è pronto")
                    .padding(.top, col.verificaSopra)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(col.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(col.superficieScheda, raggio: col.raggioScheda)
    }

    /// Gli impegni di oggi, come nel template: «09:30 · Giulia Rossi». Un clic apre l'impegno in Agenda.
    private var schedaOggi: some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let oggi = stato.appuntamenti
            .filter { $0.stato == .pianificato && Calendar.current.isDateInToday($0.inizio) }
            .sorted { $0.inizio < $1.inizio }
        let mostrati = Array(oggi.prefix(col.massimoOggi))
        return VStack(alignment: .leading, spacing: 0) {
            Text("Oggi")
                .carattereApple(col.etichetta)
                .foregroundColor(col.coloreEtichetta)
            VStack(alignment: .leading, spacing: 0) {
                if mostrati.isEmpty {
                    Text("Nessun impegno in agenda.")
                        .carattereApple(col.oggi)
                        .foregroundColor(col.coloreNota)
                        .frame(minHeight: col.altezzaRigaOggi, alignment: .leading)
                }
                ForEach(mostrati) { e in
                    Button { stato.mostraInAgenda(e) } label: { rigaOggi(e) }
                        .buttonStyle(StileSemplice())
                        .help("\(e.titolo) · apri in Agenda")
                }
                if oggi.count > mostrati.count {
                    Text("e altri \(oggi.count - mostrati.count)")
                        .carattereApple(col.oggi)
                        .foregroundColor(col.coloreOggiSecondario)
                        .frame(minHeight: col.altezzaRigaOggi, alignment: .leading)
                }
            }
            .padding(.top, col.oggiSopra)
        }
        .multilineTextAlignment(.leading)
        .padding(col.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(col.superficieScheda, raggio: col.raggioScheda)
    }

    private func rigaOggi(_ e: Appuntamento) -> some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let chi = stato.cliente(e.clienteId)?.nome ?? e.titolo
        let scelto = !stato.rubyPortafoglio && e.clienteId == stato.clienteAttivoId
        return Text("\(Formati.ora.string(from: e.inizio)) · \(chi)")
            .carattereApple(col.oggi.tabellari)
            .foregroundColor(scelto ? col.coloreOggiScelto : col.coloreTesto)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: col.altezzaRigaOggi, alignment: .leading)
            .contentShape(Rectangle())
    }

    /// Di chi si parla: un cliente (scelto dalla tendina) o tutto il portafoglio.
    private func schedaAmbito(larghezza: CGFloat) -> some View {
        let col = Tema.Apple.Ruby.Colonna.self
        return VStack(alignment: .leading, spacing: col.spazioAmbito) {
            Text("Parliamo di")
                .carattereApple(col.etichetta)
                .foregroundColor(col.coloreEtichetta)
            if !stato.inModoCliente {
                SegmentatoPillola(selezione: $stato.rubyPortafoglio, voci: [(false, "Cliente"), (true, "Portafoglio")],
                                  larghezzaPiena: true)
                    .help("Ruby parla di un cliente o di tutto il tuo portafoglio")
            }
            if stato.rubyPortafoglio {
                Text("Tutti i clienti")
                    .carattereApple(col.oggi)
                    .foregroundColor(col.coloreTesto)
                    .lineLimit(1)
            } else {
                MenuTendina(selezione: $stato.clienteAttivoId, opzioni: stato.clienti.map { ($0.id, $0.nome) },
                            stile: .vetro, larghezza: max(0, larghezza))
            }
        }
        .multilineTextAlignment(.leading)
        .padding(col.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(col.superficieScheda, raggio: col.raggioScheda)
    }

    /// L'attività più urgente: la card d'avviso «Da non dimenticare».
    private var urgente: Attivita? {
        stato.attivitaAperte.sorted {
            $0.priorita.ordine != $1.priorita.ordine ? $0.priorita.ordine < $1.priorita.ordine : $0.scadenza < $1.scadenza
        }.first
    }

    private func schedaAvviso(_ t: Attivita) -> some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let forma = RoundedRectangle(cornerRadius: col.raggioScheda, style: .continuous)
        // Sul Mac l'attività si apre nell'Agenda, nel giorno della scadenza (Attività è accorpata)
        return Button {
            stato.attivitaSelezionata = t.id
            stato.apri(.attivita)
        } label: {
            VStack(alignment: .leading, spacing: col.spazioAvviso) {
                Text("Da non dimenticare")
                    .carattereApple(col.etichetta)
                    .foregroundColor(col.etichettaAvviso)
                Text(t.titolo)
                    .carattereApple(col.testoAvviso)
                    .foregroundColor(col.coloreTesto)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(stato.cliente(t.clienteId)?.nome ?? "") · \(Formati.giornoMese.string(from: t.scadenza))")
                    .carattereApple(col.notaAvviso)
                    .foregroundColor(col.coloreNota)
            }
            .multilineTextAlignment(.leading)
            .padding(col.paddingScheda)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { forma.fill(col.fondoAvviso) }
            .overlay { forma.strokeBorder(col.bordoAvviso, lineWidth: Tema.Apple.Misura.bordo).allowsHitTesting(false) }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
    }

    /// Il quadro del cliente: posizioni, proposte, attività aperte e simulazioni, in tile 2×2.
    private func quadro(_ c: Cliente) -> some View {
        let col = Tema.Apple.Ruby.Colonna.self
        let posizioni = stato.posizioniCliente(c.id)
        let voci: [(Int, String, AppPrisma)] = [
            (posizioni.filter { $0.stato == .inEssere }.count, "posizioni", .posizioni),
            (posizioni.filter { $0.stato == .proposta }.count, "proposte", .posizioni),
            (stato.attivitaCliente(c.id).filter { !$0.completata }.count, "attività aperte", .attivita),
            (stato.simulazioniCliente(c.id).count, "simulazioni", .simulazioni),
        ]
        return VStack(alignment: .leading, spacing: col.spazioAmbito) {
            Text("Il quadro di \(c.nome)")
                .carattereApple(col.etichetta)
                .foregroundColor(col.coloreEtichetta)
                .lineLimit(1)
                .padding(.horizontal, col.paddingScheda.leading)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: col.spazioTessere), GridItem(.flexible(), spacing: col.spazioTessere)],
                      spacing: col.spazioTessere) {
                ForEach(Array(voci.enumerated()), id: \.offset) { _, v in
                    Button { stato.apri(v.2) } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(v.0)")
                                .carattereApple(col.numeroTessera)
                                .foregroundColor(col.coloreTesto)
                            Text(v.1)
                                .carattereApple(col.voceTessera)
                                .foregroundColor(col.coloreNota)
                                .lineLimit(1)
                        }
                        .padding(col.paddingTessera)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .superficieApple(col.superficieTessera, raggio: col.raggioTessera)
                        .contentShape(RoundedRectangle(cornerRadius: col.raggioTessera, style: .continuous))
                    }
                    .buttonStyle(StileSemplice())
                }
            }
        }
        .multilineTextAlignment(.leading)
        .padding(.top, col.fraSchede)
    }

    // MARK: - Chat

    private var chat: some View {
        let ch = Tema.Apple.Ruby.Chat.self
        return VStack(spacing: 0) {
            messaggiVista
                .frame(maxHeight: .infinity)
            conVoce { v in notaVoce(v) }
            suggerimenti
                .padding(.top, ch.sopraSuggerimenti)
            conVoce { v in campoScrittura(v) }
                .padding(.top, ch.sopraCampo)
                .padding(.bottom, ch.sottoCampo)
        }
        .padding(.horizontal, ch.margineLati)
        .padding(.top, ch.margineAlto)
        // Mentre Ruby ascolta o parla: la capsula della voce in alto a destra, con i suoi comandi
        .overlay(alignment: .topTrailing) {
            conVoce { v in capsulaVoce(v) }
                .padding(.top, ch.margineAlto)
                .padding(.trailing, ch.margineLati)
        }
    }

    private var messaggiVista: some View {
        let ch = Tema.Apple.Ruby.Chat.self
        let elenco = messaggi
        let portafoglio = stato.rubyPortafoglio
        // La scheda dei calcoli va nell'ultima risposta di Ruby: le cifre le calcola Prisma, mai Qwen
        let ultima = elenco.last.flatMap { $0.autore == .ruby ? $0 : nil }
        let quadro = stato.rubyInCorso ? nil : ultima.flatMap { stato.quadroRuby(per: $0, in: elenco, portafoglio: portafoglio) }
        let primoNuovo = nuoviDa.flatMap { $0.chiave == chiave ? $0.indice : nil } ?? Int.max
        return ScrollViewReader { lettore in
            ScrollView {
                VStack(alignment: .leading, spacing: ch.spazioMessaggi) {
                    if elenco.isEmpty && !stato.rubyInCorso { benvenuto }
                    ForEach(Array(elenco.enumerated()), id: \.element.id) { i, msg in
                        NuvolaRuby(messaggio: msg, nomeUtente: stato.nomeUtente, azioniCliente: !portafoglio,
                                  creaAttivita: { stato.attivitaDaRuby(msg) }, aggiungiNota: { stato.notaDaRuby(msg) },
                                  attivitaProposta: { stato.attivitaDaProposta($0, messaggio: msg.id) },
                                  posizioneProposta: { stato.posizioneDaProposta($0, messaggio: msg.id) },
                                  apriAzione: { stato.apriAzioneRuby($0) },
                                  annullaAzione: { stato.annullaAzioneRuby($0, messaggio: msg.id) },
                                  quadro: msg.id == ultima?.id ? quadro : nil,
                                  nuova: i >= primoNuovo,
                                  avanza: { lettore.scrollTo(Self.fondo, anchor: .bottom) })
                            .id(msg.id)
                    }
                    if stato.rubyInCorso {
                        // Puntini e sfera che pulsa, poi il testo che arriva da Qwen parola per parola
                        NuvolaInArrivo(flusso: stato.flussoRuby, portafoglio: portafoglio,
                                       avanza: { lettore.scrollTo(Self.fondo, anchor: .bottom) })
                            .id("pensa")
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(Self.fondo)
                }
                .padding(ch.paddingInterno)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // L'ultima risposta sfuma sopra i suggerimenti invece di scorrerci sotto senza stacco
            .sfumaturaBordiScorrimento(sotto: ch.sfumatura)
            .onAppear { lettore.scrollTo(Self.fondo, anchor: .bottom) }
            .onChange(of: elenco.count) { _ in
                withAnimation(Tema.Apple.Moto.uscita(Tema.Apple.Moto.SchedaCalcoli.durata)) { lettore.scrollTo(Self.fondo, anchor: .bottom) }
            }
            .onChange(of: stato.rubyInCorso) { _ in
                withAnimation(Tema.Apple.Moto.uscita(Tema.Apple.Moto.SchedaCalcoli.durata)) { lettore.scrollTo(Self.fondo, anchor: .bottom) }
            }
        }
    }

    /// La conversazione vuota: Ruby saluta per prima, come nel template, con i numeri veri della giornata.
    private var benvenuto: some View {
        let b = Tema.Apple.Ruby.Bolla.self
        return VStack(alignment: .leading, spacing: 0) {
            Text("Ruby")
                .carattereApple(b.intestazione)
                .foregroundColor(b.coloreIntestazione)
                .padding(.bottom, b.sottoIntestazione)
            Text(fraseBenvenuto)
                .carattereApple(b.messaggio)
                .foregroundColor(b.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(b.paddingRuby)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaRuby(mia: false)
        .frame(maxWidth: Tema.Apple.Ruby.Chat.larghezzaMessaggio, alignment: .leading)
    }

    private var fraseBenvenuto: String {
        let s = Tema.Apple.Scrivania.Saluto.self
        let ora = Calendar.current.component(.hour, from: Date())
        let parola = ora < s.oraPomeriggio ? "Buongiorno" : ora < s.oraSera ? "Buon pomeriggio" : "Buonasera"
        let oggi = stato.appuntamenti.filter { $0.stato == .pianificato && Calendar.current.isDateInToday($0.inizio) }
        let conClienti = oggi.filter { stato.cliente($0.clienteId) != nil }.count
        let giornata: String
        switch conClienti {
        case 0: giornata = oggi.isEmpty ? "Oggi l'agenda è libera." : "Oggi non hai appuntamenti con i clienti."
        case 1: giornata = "Oggi hai un appuntamento con un cliente."
        default: giornata = "Oggi hai \(conClienti) appuntamenti con i clienti."
        }
        let di = stato.rubyPortafoglio ? "Parliamo di tutto il portafoglio" : "Sono sul dossier di \(cliente?.nome ?? "un cliente")"
        return "\(parola) \(stato.nomeUtente). \(giornata) \(di): da dove partiamo?"
    }

    /// Gli spunti (`.sugg`): restano visibili; quelli che non stanno nella riga sfumano sul bordo destro.
    private var suggerimenti: some View {
        let c = Tema.Apple.Ruby.Campo.self
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: c.spazioSuggerimenti) {
                if stato.rubyPortafoglio {
                    ForEach(SpuntoPortafoglio.allCases) { s in
                        Button { stato.chiediRubyPortafoglio(s.domanda, spunto: s) } label: { PillolaSpuntoRuby(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                            .disabled(stato.rubyInCorso)
                    }
                } else {
                    ForEach(SpuntoRuby.allCases) { s in
                        Button { stato.chiediRuby(s.domanda, spunto: s) } label: { PillolaSpuntoRuby(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                            .disabled(stato.rubyInCorso)
                    }
                }
            }
            // Spazio per la molla del passaggio (sale di 2) e per la sfumatura in fondo alla riga
            .padding(.vertical, abs(Tema.Apple.Moto.SuggerimentoSopra.spostamento))
            .padding(.trailing, c.sfumaturaSuggerimenti)
        }
        .mask {
            HStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: c.sfumaturaSuggerimenti)
            }
        }
    }

    /// Il campo a capsula (`cardPiena`, ombra `card`): il testo (o quello che Ruby sta capendo), il microfono e l'invio.
    private func campoScrittura(_ v: StatoVoce) -> some View {
        let c = Tema.Apple.Ruby.Campo.self
        let acceso = v.ascolta || stato.dettaturaAttiva
        let vuota = stato.domandaRuby.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(alignment: .bottom, spacing: c.spazio) {
            Group {
                if v.ascolta {
                    // Mentre parli, al posto del campo c'è quello che Ruby sta capendo
                    Text(v.trascritto.isEmpty ? (v.nota ?? "Ti ascolto…") : v.trascritto)
                        .carattereApple(c.testo)
                        .italic(v.trascritto.isEmpty)
                        .foregroundColor(v.trascritto.isEmpty ? c.fondoAscolto : c.coloreTesto)
                        .lineLimit(4)
                } else {
                    TextField(c.segnaposto, text: $stato.domandaRuby, axis: .vertical)
                        .textFieldStyle(.plain)
                        .carattereApple(c.testo)
                        .foregroundColor(c.coloreTesto)
                        .lineLimit(1...4)
                        .focused($campoAttivo)
                        .onSubmit { invia(stato.domandaRuby) }
                        .help("Invio per mandare, ⌥⌘E per parlare")
                }
            }
            .frame(maxWidth: .infinity, minHeight: c.tasto, alignment: .leading)
            Button { stato.alternaAscolto() } label: {
                Image(systemName: acceso ? "waveform" : "mic.fill")
            }
            .buttonStyle(StileTastoRuby(aspetto: acceso ? .ascolto : .neutro))
            .disabled(stato.rubyInCorso && !acceso)
            .help(v.prepara ? "Annulla" : (acceso ? "Ho finito di parlare" : "Parla con Ruby (⌥⌘E)"))
            Button { invia(stato.domandaRuby) } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(StileTastoRuby(aspetto: .invio))
            .disabled(stato.rubyInCorso || vuota)
            .keyboardShortcut(.return, modifiers: .command)
            .help("Invia (⌘↩)")
        }
        .padding(c.padding)
        .background {
            Capsule(style: .continuous)
                .fill(c.fondo)
                .ombraApple(c.ombra)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(acceso ? c.fondoAscolto : c.bordo, lineWidth: acceso ? c.filoAscolto : Tema.Apple.Misura.bordo)
                .allowsHitTesting(false)
        }
    }

    /// Gli errori della voce e, in modalità diagnostica, l'ultimo passaggio dell'ascolto (solo quando ci sono).
    @ViewBuilder
    private func notaVoce(_ v: StatoVoce) -> some View {
        let ch = Tema.Apple.Ruby.Chat.self
        let passaggio = stato.dati.impostazioni.ruby.mostraPassaggiVoce ? stato.passaggioVoce : nil
        if let testo = v.errore ?? passaggio {
            Text(testo)
                .carattereApple(ch.notaVoce)
                .foregroundColor(v.errore == nil ? ch.coloreVoce : ch.ascolto)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, Tema.Apple.Ruby.Chat.sopraCampo)
        }
    }

    /// Cosa fa la voce di Ruby adesso (si prepara, ti ascolta, ti risponde) con «Interrompi» e la chiusura della
    /// conversazione a voce. A riposo non c'è.
    @ViewBuilder
    private func capsulaVoce(_ v: StatoVoce) -> some View {
        let ch = Tema.Apple.Ruby.Chat.self
        let ascolta = v.ascolta || stato.dettaturaAttiva
        if ascolta || v.parla || v.prepara || stato.conversazioneAVoce {
            let scritta = v.prepara ? "Ruby · si prepara" : (ascolta ? "Ruby · ti ascolta" : (v.parla ? "Ruby · ti risponde" : "Ruby · a voce"))
            HStack(spacing: ch.spazioVoce) {
                HStack(spacing: ch.spazioVoce) {
                    Circle()
                        .fill(ascolta ? ch.ascolto : ch.parla)
                        .frame(width: ch.spiaVoce, height: ch.spiaVoce)
                    Text(scritta)
                        .carattereApple(ch.carattereVoce)
                        .foregroundColor(ch.coloreVoce)
                        .fixedSize()
                }
                .padding(ch.paddingVoce)
                .background { Capsule(style: .continuous).fill(ch.fondoVoce) }
                if v.parla {
                    Button { stato.voceRuby.zitta() } label: { Label("Interrompi", systemImage: "speaker.slash") }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .help("Ruby smette di parlare")
                }
                if stato.conversazioneAVoce {
                    Button { stato.fermaVoce() } label: { Label("Chiudi la voce", systemImage: "stop.fill") }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .help("Chiudi la conversazione a voce · oppure di' a Ruby «basta così»")
                }
            }
        }
    }

    /// Il contenuto che segue la voce e l'ascolto di Ruby (nelle istantanee, lo stato di prova).
    @ViewBuilder
    private func conVoce<C: View>(@ViewBuilder _ contenuto: @escaping (StatoVoce) -> C) -> some View {
        if stato.persistente {
            OsservaVoce(ascolto: stato.ascoltoRuby, voce: stato.voceRuby, contenuto: contenuto)
        } else {
            contenuto(stato.voceIstantanea ?? StatoVoce())
        }
    }
}

/// Da quale messaggio di quale conversazione le bolle sono nuove.
private struct SegnoNuoviRuby: Equatable {
    let chiave: String
    let indice: Int
}

// MARK: - Testata

/// A destra nella testata dell'app Ruby: «Lavoro / Conversazione» a pillola e «Nuova conversazione».
/// Lavoro: i numeri vengono solo da Prisma e dalla scheda (Ruby/Istruzioni/chat.md); conversazione: uso generale
/// (conversazione.md). Finché non scegli, Ruby decide dalla domanda e il selettore mostra cosa ha deciso.
struct AzioniRuby: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let vuota = stato.conversazione(stato.rubyPortafoglio ? RubyPortafoglio.chiave : stato.clienteAttivoId).isEmpty
        let fermo = stato.rubyPortafoglio || stato.rubyInCorso
        return HStack(spacing: Tema.Apple.Ruby.Testata.spazio) {
            SegmentatoPillola(selezione: modalita, voci: [(ModalitaRuby.lavoro, "Lavoro"), (ModalitaRuby.conversazione, "Conversazione")])
                .disabled(fermo)
                .opacity(fermo ? Tema.Apple.Ruby.Campo.opacitaSpento : 1)
                .help(stato.rubyPortafoglio ? "Sul portafoglio Ruby lavora sempre con le cifre di Prisma"
                                           : "Lavoro: i numeri solo da Prisma · Conversazione: domande di ogni tipo")
            Button { stato.nuovaConversazione() } label: {
                Label("Nuova conversazione", systemImage: "square.and.pencil")
            }
            .buttonStyle(StileVetro())
            .disabled(vuota && stato.modalitaRubyScelta == nil)
            .help("Comincia da capo: la conversazione di adesso si chiude")
        }
    }

    private var modalita: Binding<ModalitaRuby> {
        Binding(get: { stato.modalitaRubyMostrata }, set: { stato.modalitaRubyScelta = $0 })
    }
}

// MARK: - Voce

/// Lo stato della voce di Ruby in un momento: ascolta, parla, cosa ha capito, perché non può ascoltare.
struct StatoVoce {
    var ascolta = false
    /// Ruby prepara il riconoscimento (il microfono non è ancora acceso).
    var prepara = false
    var parla = false
    var trascritto = ""
    var errore: String?
    /// Quanto suona il microfono (0…1) mentre Ruby ascolta.
    var livello: Float = 0
    /// Cosa fa Ruby prima di sentirti («Mi preparo ad ascoltarti…»).
    var nota: String?
}

/// Segue l'ascolto e la voce di Ruby e ridisegna solo il pezzo che ne dipende.
private struct OsservaVoce<C: View>: View {
    @ObservedObject var ascolto: AscoltoRuby
    @ObservedObject var voce: VoceRuby
    let contenuto: (StatoVoce) -> C

    var body: some View {
        var errore: String?
        if case .nonDisponibile(let m) = ascolto.stato { errore = m }
        return contenuto(StatoVoce(ascolta: ascolto.ascolta, prepara: ascolto.siPrepara, parla: voce.parla, trascritto: ascolto.trascritto, errore: errore, livello: ascolto.livello, nota: ascolto.nota))
    }
}

// MARK: - Bolle

/// La risposta di Ruby mentre arriva (streaming): prima i puntini «sta scrivendo», poi il testo che Qwen scrive,
/// parola per parola, nella bolla delle risposte. Osserva solo `FlussoRuby`.
struct NuvolaInArrivo: View {
    @ObservedObject var flusso: FlussoRuby
    var portafoglio = false
    /// Chiamato quando arriva la prima parola.
    var iniziata: () -> Void = {}
    /// A ogni parola mostrata (la chat scorre in fondo).
    var avanza: (() -> Void)? = nil

    private var stato: String {
        if flusso.pensa { return "Ruby ci sta pensando…" }
        if portafoglio || flusso.modalita == .lavoro { return "Ruby sta leggendo il dossier…" }
        return "Ruby sta scrivendo…"
    }

    var body: some View {
        let b = Tema.Apple.Ruby.Bolla.self
        let calcoli = !flusso.testo.isEmpty && (portafoglio || flusso.modalita == .lavoro)
        VStack(alignment: .leading, spacing: 0) {
            Text(calcoli ? "Ruby · Calcoli di Prisma" : "Ruby")
                .carattereApple(b.intestazione)
                .foregroundColor(b.coloreIntestazione)
                .lineLimit(1)
                .padding(.bottom, b.sottoIntestazione)
            if flusso.testo.isEmpty {
                HStack(spacing: b.spazioPuntini) {
                    PuntiniScrittura()
                    if flusso.pensa {
                        Text("Ci sto pensando con calma…")
                            .carattereApple(b.nota)
                            .foregroundColor(b.coloreNota)
                    }
                }
            } else {
                TestoProgressivo(testo: flusso.testo, staffetta: .consegna, avanza: avanza)
                    .carattereApple(b.messaggio)
                    .foregroundColor(b.testo)
            }
        }
        .padding(b.paddingRuby)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaRuby(mia: false)
        .frame(maxWidth: Tema.Apple.Ruby.Chat.larghezzaMessaggio, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: flusso.testo.isEmpty) { vuoto in if !vuoto { iniziata() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(stato))
    }
}

/// Una bolla della conversazione. Ruby: `chip`, larga fino a 640, con l'intestazione «Ruby» o «Ruby · Calcoli di
/// Prisma» (modalità lavoro, numeri dai motori), il testo, la scheda dei calcoli e le azioni. Tu: accento, a destra.
/// `nuova`: la bolla è appena arrivata (la tua entra a molla; quella di Ruby si scrive parola per parola e poi
/// entrano la scheda dei calcoli e le azioni).
struct NuvolaRuby: View {
    let messaggio: MessaggioRuby
    /// Il tuo nome (le tue bolle, come nelle chat del Mac, non lo ripetono: sono a destra, nell'accento).
    let nomeUtente: String
    /// «Crea attività» e «Nota del cliente» solo nelle conversazioni di un cliente.
    var azioniCliente = true
    let creaAttivita: () -> Void
    let aggiungiNota: () -> Void
    var attivitaProposta: (PropostaRuby) -> Void = { _ in }
    var posizioneProposta: (PropostaRuby) -> Void = { _ in }
    var apriAzione: (AzioneRuby) -> Void = { _ in }
    var annullaAzione: (AzioneRuby) -> Void = { _ in }
    /// La scheda dei calcoli di Prisma sotto il testo (solo l'ultima risposta).
    var quadro: QuadroRuby? = nil
    var nuova = false
    /// A ogni parola mostrata (la chat scorre in fondo).
    var avanza: (() -> Void)? = nil

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var testoScritto = false

    init(messaggio: MessaggioRuby, nomeUtente: String, azioniCliente: Bool = true,
         creaAttivita: @escaping () -> Void, aggiungiNota: @escaping () -> Void,
         attivitaProposta: @escaping (PropostaRuby) -> Void = { _ in },
         posizioneProposta: @escaping (PropostaRuby) -> Void = { _ in },
         apriAzione: @escaping (AzioneRuby) -> Void = { _ in },
         annullaAzione: @escaping (AzioneRuby) -> Void = { _ in },
         quadro: QuadroRuby? = nil, nuova: Bool = false, avanza: (() -> Void)? = nil) {
        self.messaggio = messaggio
        self.nomeUtente = nomeUtente
        self.azioniCliente = azioniCliente
        self.creaAttivita = creaAttivita
        self.aggiungiNota = aggiungiNota
        self.attivitaProposta = attivitaProposta
        self.posizioneProposta = posizioneProposta
        self.apriAzione = apriAzione
        self.annullaAzione = annullaAzione
        self.quadro = quadro
        self.nuova = nuova
        self.avanza = avanza
    }

    var body: some View {
        if messaggio.autore == .utente {
            bollaUtente
        } else {
            bollaRubyVista
        }
    }

    private var bollaUtente: some View {
        let b = Tema.Apple.Ruby.Bolla.self
        return HStack(spacing: 0) {
            Spacer(minLength: b.respiroUtente)
            Text(messaggio.testo)
                .carattereApple(b.messaggio)
                .foregroundColor(b.testoUtente)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(b.paddingUtente)
                .bollaRuby(mia: true)
                .frame(maxWidth: Tema.Apple.Ruby.Chat.larghezzaMessaggio, alignment: .trailing)
                .entrataBollaUtente(nuova)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var bollaRubyVista: some View {
        let b = Tema.Apple.Ruby.Bolla.self
        let resto = !nuova || testoScritto || fermo
        return VStack(alignment: .leading, spacing: 0) {
            Text(QuadroRuby.ammessa(messaggio) ? "Ruby · Calcoli di Prisma" : "Ruby")
                .carattereApple(b.intestazione)
                .foregroundColor(b.coloreIntestazione)
                .lineLimit(1)
                .padding(.bottom, b.sottoIntestazione)
            if let t = messaggio.titolo {
                Text(t)
                    .carattereApple(b.titolo)
                    .foregroundColor(b.testo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, b.sottoIntestazione)
            }
            TestoProgressivo(testo: messaggio.testo, anima: nuova, staffetta: nuova ? .riceve : .nessuna,
                             avanza: avanza, finito: { testoScritto = true })
                .carattereApple(b.messaggio)
                .foregroundColor(b.testo)
                .textSelection(.enabled)
            if resto {
                VStack(alignment: .leading, spacing: 0) {
                    if let q = quadro {
                        QuadroVisivoRuby(quadro: q)
                            .padding(.top, b.sopraScheda)
                    }
                    // Lo scenario «E se…?»: la tabella prima/dopo di Prisma con «Salva nel dossier» e «Apri in Simulazioni»
                    if let s = messaggio.scenario {
                        SchedaScenarioRubyVista(scheda: s, messaggio: messaggio.id, entra: false)
                    }
                    if let proposte = messaggio.proposte, !proposte.isEmpty {
                        elencoProposte(proposte)
                            .padding(.top, b.sopraScheda)
                    }
                    azioni
                        .padding(.top, b.sopraAzioni)
                }
                .entrataSchedaCalcoli(nuova)
            }
        }
        .padding(b.paddingRuby)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaRuby(mia: false)
        .frame(maxWidth: Tema.Apple.Ruby.Chat.larghezzaMessaggio, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le azioni proposte da Ruby (calcolate da Prisma): una tile con le righe divise dal filo.
    private func elencoProposte(_ proposte: [PropostaRuby]) -> some View {
        let b = Tema.Apple.Ruby.Bolla.self
        let s = Tema.Apple.Ruby.SchedaCalcoli.self
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(proposte.enumerated()), id: \.element.id) { i, p in
                HStack(spacing: b.spazioAzioni) {
                    Text("\(i + 1). \(p.titolo)")
                        .carattereApple(b.proposta)
                        .foregroundColor(b.testo)
                        .lineLimit(1)
                    Spacer(minLength: b.spazioAzioni)
                    if p.attivitaId != nil {
                        Text(NuvolaRuby.segnoAttivitaCreata)
                            .carattereApple(b.nota)
                            .foregroundColor(b.coloreNota)
                    } else {
                        azione("✓ Attività") { attivitaProposta(p) }
                    }
                    if p.area != nil {
                        azione(p.posizioneId == nil ? "＋ Prepara la proposta" : "Apri la proposta ↗", primaria: p.posizioneId == nil) {
                            posizioneProposta(p)
                        }
                    }
                }
                .padding(b.paddingProposta)
                .overlay(alignment: .top) {
                    if i > 0 {
                        Rectangle()
                            .fill(Tema.Apple.Colore.separatore)
                            .frame(height: Tema.Apple.Misura.bordo)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: s.raggio, style: .continuous))
        .superficieApple(s.superficie, raggio: s.raggio)
    }

    @ViewBuilder
    private var azioni: some View {
        let b = Tema.Apple.Ruby.Bolla.self
        if let a = messaggio.azione {
            HStack(spacing: b.spazioAzioni) {
                if a.annullata {
                    Text("Annullato")
                        .carattereApple(b.nota)
                        .foregroundColor(b.coloreNota)
                } else {
                    azione(Self.apri(a), primaria: true) { apriAzione(a) }
                    azione("Annulla") { annullaAzione(a) }
                }
            }
        } else {
            HStack(spacing: b.spazioAzioni) {
                if azioniCliente && messaggio.motore != StatoShell.motoreAzioni {
                    azione("✓ Crea attività", creaAttivita)
                    azione("＋ Nota del cliente", aggiungiNota)
                }
                azione("Copia") {
                    Appunti.copia((messaggio.titolo.map { $0 + "\n\n" } ?? "") + messaggio.testo)
                }
            }
        }
    }

    /// L'attività già creata da una proposta: sul Mac sta nell'Agenda (Attività è accorpata).
    private static var segnoAttivitaCreata: String {
        #if os(macOS)
        return "✓ in Agenda"
        #else
        return "✓ in Attività"
        #endif
    }

    private static func apri(_ a: AzioneRuby) -> String {
        switch a.tipo {
        case .appuntamento: return "Apri in Agenda ↗"
        #if os(macOS)
        case .attivita: return "Apri in Agenda ↗"
        #else
        case .attivita: return "Apri in Attività ↗"
        #endif
        case .nota: return "Apri la nota ↗"
        }
    }

    /// Un pulsante del template (`.btn`, o `.btn.pri` per l'azione principale).
    private func azione(_ titolo: String, primaria: Bool = false, _ fai: @escaping () -> Void) -> some View {
        Button(action: fai) {
            Text(titolo).lineLimit(1)
        }
        .buttonStyle(StilePulsanteApple(primaria ? .principale : .secondaria))
        .fixedSize()
    }
}

// MARK: - Onda

/// Onda sonora fissa (nessuna animazione continua: niente consumi inutili sul Mac).
struct OndaRuby: View {
    let attiva: Bool
    /// Mentre Ruby ascolta, l'onda segue il microfono: ferma vuol dire che il microfono non sente.
    var livello: Float? = nil
    /// Altezza delle barre rispetto all'onda piena (la capsula della barra la vuole più bassa).
    var scala: CGFloat = 1
    /// Quante barre disegnare (al massimo tutte).
    var barre = Int.max
    private static let altezze: [CGFloat] = [4, 7, 12, 18, 10, 22, 14, 24, 16, 20, 9, 13, 6, 10, 4, 8, 14, 19, 11, 6, 9, 15, 7, 4]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(Self.altezze.prefix(barre).enumerated()), id: \.offset) { i, h in
                Capsule()
                    .fill(Gradienti.onda)
                    .frame(width: 3, height: altezza(h) * scala)
                    .opacity(attiva ? 1 : 0.6 + Double(i % 3) * 0.1)
            }
        }
        .frame(height: (Self.altezze.max() ?? 0) * scala)
        .fixedSize()
    }

    private func altezza(_ h: CGFloat) -> CGFloat {
        if let livello { return max(3, h * (0.15 + 0.85 * CGFloat(livello))) }
        return attiva ? h : max(3, h * 0.35)
    }
}
