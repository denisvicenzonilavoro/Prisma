#if os(macOS)
import AppKit
#endif
import SwiftUI

/// App Vera nel tema Apple (Design/template-apple-specifica.md §4.7, PIE e01…e10): a sinistra la colonna di Vera
/// (la sfera grande che respira, «Ciao, sono Vera.», lo stato vero di Qwen, la card «Oggi», di chi si parla, cosa non
/// dimenticare e il quadro del cliente), a destra la chat con le bolle, i suggerimenti e il campo a capsula.
/// La testata della finestra ha il selettore «Lavoro / Conversazione» e «Nuova conversazione» (`AzioniVera`).
/// Vera risponde con Qwen sul Mac; i numeri li calcola sempre Prisma, Vera li legge e li racconta.
/// Sequenza di una domanda: la bolla dell'utente entra a molla, compaiono i puntini e la sfera pulsa, il testo arriva
/// parola per parola e alla fine entra la scheda dei calcoli.
struct AppVera: View {
    @Environment(StatoShell.self) var stato
    /// Il campo della domanda in primo piano: serve alla dettatura di macOS, che scrive dove c'è il cursore.
    @FocusState private var campoAttivo: Bool
    /// Da quale messaggio in poi le bolle sono nuove (arrivate con l'app aperta): entrano e si scrivono.
    @State private var nuoviDa: SegnoNuoviVera?

    private var cliente: Cliente? { stato.clienteAttivo }
    private var chiave: String { stato.veraPortafoglio ? VeraPortafoglio.chiave : stato.clienteAttivoId }
    // In modalità cliente senza i messaggi del sussurro (appunti del consulente)
    private var messaggi: [MessaggioVera] { stato.messaggiPerLoSchermo(stato.conversazione(chiave)) }

    /// Il punto in fondo alla chat: a ogni parola la chat scorre lì.
    private static let fondo = "fondo-chat-vera"

    private func invia(_ testo: String) {
        if stato.veraPortafoglio { stato.chiediVeraPortafoglio(testo) } else { stato.chiediVera(testo) }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let col = Tema.Apple.Vera.Colonna.self
        GeometryReader { geo in
            // Vera a metà schermo: la colonna si stringe e la chat resta sempre dentro la finestra
            let larghezza = geo.size.width < Tema.Misura.VeraChat.sogliaContestoStretto ? Tema.Misura.VeraChat.contestoStretto : col.larghezza
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
        // «Lascia cadere qui» e la pagina della memoria di Vera (fase 2, RilascioVera.swift)
        .rilascioDocumentiVera()
        .paginaMemoriaVera(stato.memoriaVera)
        // Fase 4: la pagina delle routine e la pagina del tagliando dei dati sopra la finestra di Vera
        // (VisteRoutineVera.swift, VisteTagliandoVera.swift)
        .paginaRoutineVera()
        .paginaTagliandoVera()
        // Parte sia alla nascita della vista (Vera era chiusa o ridotta) sia a ogni nuova richiesta
        .task(id: stato.richiestaDettatura) { await accendiDettatura() }
        // Il FocusState resta in pari con makeFirstResponder(nil), altrimenti il prossimo «true» non cambia niente
        .onChange(of: stato.dettaturaAttiva) { attiva in if !attiva { campoAttivo = false } }
        .onAppear { segnaNuovi() }
        .onChange(of: chiave) { _ in segnaNuovi() }
        .onChange(of: messaggi.count) { n in
            // «Nuova conversazione»: le bolle che arrivano dopo sono di nuovo nuove
            if let s = nuoviDa, s.chiave == chiave, n < s.indice { nuoviDa = SegnoNuoviVera(chiave: chiave, indice: n) }
        }
    }

    /// Le bolle già nella conversazione si vedono ferme; quelle che arrivano da adesso entrano.
    private func segnaNuovi() {
        nuoviDa = SegnoNuoviVera(chiave: chiave, indice: messaggi.count)
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
        let col = Tema.Apple.Vera.Colonna.self
        let interna = larghezza - col.padding.leading - col.padding.trailing
        // Senza barra di scorrimento; in fondo le card sfumano invece di finire tagliate
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                SferaVera(misura: Tema.Apple.Vera.Sfera.vera, viva: true, pensa: stato.veraInCorso)
                Text("Ciao, sono Vera.")
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
                    // Il tagliando dei dati (fase 4): salute dell'archivio e cose da sistemare, apre la pagina (fuori dalla modalità cliente)
                    SchedaTagliandoColonnaVera()
                    if let t = urgente { schedaAvviso(t) }
                    if let c = cliente, !stato.veraPortafoglio { quadro(c) }
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

    /// Lo stato vero di Qwen: pronto («I numeri li calcola Prisma, io li racconto.») o non pronto, e allora Vera non
    /// risponde e lo dice, con «Verifica».
    private var schedaMotore: some View {
        let col = Tema.Apple.Vera.Colonna.self
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
        let col = Tema.Apple.Vera.Colonna.self
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
        let col = Tema.Apple.Vera.Colonna.self
        let chi = stato.cliente(e.clienteId)?.nome ?? e.titolo
        let scelto = !stato.veraPortafoglio && e.clienteId == stato.clienteAttivoId
        return Text("\(Formati.ora.string(from: e.inizio)) · \(chi)")
            .carattereApple(col.oggi.tabellari)
            .foregroundColor(scelto ? col.coloreOggiScelto : col.coloreTesto)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: col.altezzaRigaOggi, alignment: .leading)
            .contentShape(Rectangle())
    }

    /// Di chi si parla: un cliente (scelto dalla tendina) o tutto il portafoglio.
    private func schedaAmbito(larghezza: CGFloat) -> some View {
        let col = Tema.Apple.Vera.Colonna.self
        return VStack(alignment: .leading, spacing: col.spazioAmbito) {
            Text("Parliamo di")
                .carattereApple(col.etichetta)
                .foregroundColor(col.coloreEtichetta)
            if !stato.inModoCliente {
                SegmentatoPillola(selezione: Bindable(stato).veraPortafoglio, voci: [(false, "Cliente"), (true, "Portafoglio")],
                                  larghezzaPiena: true)
                    .help("Vera parla di un cliente o di tutto il tuo portafoglio")
            }
            if stato.veraPortafoglio {
                Text("Tutti i clienti")
                    .carattereApple(col.oggi)
                    .foregroundColor(col.coloreTesto)
                    .lineLimit(1)
            } else {
                MenuTendina(selezione: Bindable(stato).clienteAttivoId, opzioni: stato.clienti.map { ($0.id, $0.nome) },
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
        let col = Tema.Apple.Vera.Colonna.self
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
        let col = Tema.Apple.Vera.Colonna.self
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
        let ch = Tema.Apple.Vera.Chat.self
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
        // Mentre Vera ascolta o parla: la capsula della voce in alto a destra, con i suoi comandi
        .overlay(alignment: .topTrailing) {
            conVoce { v in capsulaVoce(v) }
                .padding(.top, ch.margineAlto)
                .padding(.trailing, ch.margineLati)
        }
    }

    private var messaggiVista: some View {
        let ch = Tema.Apple.Vera.Chat.self
        let elenco = messaggi
        let portafoglio = stato.veraPortafoglio
        // La scheda dei calcoli va nell'ultima risposta di Vera: le cifre le calcola Prisma, mai Qwen
        let ultima = elenco.last.flatMap { $0.autore == .vera ? $0 : nil }
        let quadro = stato.veraInCorso ? nil : ultima.flatMap { stato.quadroVera(per: $0, in: elenco, portafoglio: portafoglio) }
        let primoNuovo = nuoviDa.flatMap { $0.chiave == chiave ? $0.indice : nil } ?? Int.max
        return ScrollViewReader { lettore in
            ScrollView {
                VStack(alignment: .leading, spacing: ch.spazioMessaggi) {
                    if elenco.isEmpty && !stato.veraInCorso { benvenuto }
                    ForEach(Array(elenco.enumerated()), id: \.element.id) { i, msg in
                        NuvolaVera(messaggio: msg, nomeUtente: stato.nomeUtente, azioniCliente: !portafoglio,
                                  creaAttivita: { stato.attivitaDaVera(msg) }, aggiungiNota: { stato.notaDaVera(msg) },
                                  attivitaProposta: { stato.attivitaDaProposta($0, messaggio: msg.id) },
                                  posizioneProposta: { stato.posizioneDaProposta($0, messaggio: msg.id) },
                                  apriAzione: { stato.apriAzioneVera($0) },
                                  annullaAzione: { stato.annullaAzioneVera($0, messaggio: msg.id) },
                                  quadro: msg.id == ultima?.id ? quadro : nil,
                                  nuova: i >= primoNuovo,
                                  avanza: { lettore.scrollTo(Self.fondo, anchor: .bottom) })
                            .id(msg.id)
                    }
                    if stato.veraInCorso {
                        // Puntini e sfera che pulsa, poi il testo che arriva da Qwen parola per parola
                        NuvolaInArrivo(flusso: stato.flussoVera, portafoglio: portafoglio,
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
            .onChange(of: stato.veraInCorso) { _ in
                withAnimation(Tema.Apple.Moto.uscita(Tema.Apple.Moto.SchedaCalcoli.durata)) { lettore.scrollTo(Self.fondo, anchor: .bottom) }
            }
        }
    }

    /// La conversazione vuota: Vera saluta per prima, come nel template, con i numeri veri della giornata.
    private var benvenuto: some View {
        let b = Tema.Apple.Vera.Bolla.self
        return VStack(alignment: .leading, spacing: 0) {
            Text("Vera")
                .carattereApple(b.intestazione)
                .foregroundColor(b.coloreIntestazione)
                .padding(.bottom, b.sottoIntestazione)
            Text(fraseBenvenuto)
                .carattereApple(b.messaggio)
                .foregroundColor(b.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(b.paddingVera)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaVera(mia: false)
        .frame(maxWidth: Tema.Apple.Vera.Chat.larghezzaMessaggio, alignment: .leading)
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
        let di = stato.veraPortafoglio ? "Parliamo di tutto il portafoglio" : "Sono sul dossier di \(cliente?.nome ?? "un cliente")"
        return "\(parola) \(stato.nomeUtente). \(giornata) \(di): da dove partiamo?"
    }

    /// Gli spunti (`.sugg`): restano visibili; quelli che non stanno nella riga sfumano sul bordo destro.
    private var suggerimenti: some View {
        let c = Tema.Apple.Vera.Campo.self
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: c.spazioSuggerimenti) {
                if stato.veraPortafoglio {
                    ForEach(SpuntoPortafoglio.allCases) { s in
                        Button { stato.chiediVeraPortafoglio(s.domanda, spunto: s) } label: { PillolaSpuntoVera(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                            .disabled(stato.veraInCorso)
                    }
                } else {
                    ForEach(SpuntoVera.allCases) { s in
                        Button { stato.chiediVera(s.domanda, spunto: s) } label: { PillolaSpuntoVera(simbolo: s.simbolo, testo: s.domanda) }
                            .buttonStyle(StileSemplice())
                            .disabled(stato.veraInCorso)
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

    /// Il campo a capsula (`cardPiena`, ombra `card`): il testo (o quello che Vera sta capendo), il microfono e l'invio.
    private func campoScrittura(_ v: StatoVoce) -> some View {
        let c = Tema.Apple.Vera.Campo.self
        let acceso = v.ascolta || stato.dettaturaAttiva
        let vuota = stato.domandaVera.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(alignment: .bottom, spacing: c.spazio) {
            Group {
                if v.ascolta {
                    // Mentre parli, al posto del campo c'è quello che Vera sta capendo
                    Text(v.trascritto.isEmpty ? (v.nota ?? "Ti ascolto…") : v.trascritto)
                        .carattereApple(c.testo)
                        .italic(v.trascritto.isEmpty)
                        .foregroundColor(v.trascritto.isEmpty ? c.fondoAscolto : c.coloreTesto)
                        .lineLimit(4)
                } else {
                    TextField(c.segnaposto, text: Bindable(stato).domandaVera, axis: .vertical)
                        .textFieldStyle(.plain)
                        .carattereApple(c.testo)
                        .foregroundColor(c.coloreTesto)
                        .lineLimit(1...4)
                        .focused($campoAttivo)
                        .onSubmit { invia(stato.domandaVera) }
                        .help("Invio per mandare, ⌥⌘E per parlare")
                }
            }
            .frame(maxWidth: .infinity, minHeight: c.tasto, alignment: .leading)
            Button { stato.alternaAscolto() } label: {
                Image(systemName: acceso ? "waveform" : "mic.fill")
            }
            .buttonStyle(StileTastoVera(aspetto: acceso ? .ascolto : .neutro))
            .disabled(stato.veraInCorso && !acceso)
            .help(v.prepara ? "Annulla" : (acceso ? "Ho finito di parlare" : "Parla con Vera (⌥⌘E)"))
            Button { invia(stato.domandaVera) } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(StileTastoVera(aspetto: .invio))
            .disabled(stato.veraInCorso || vuota)
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
        let ch = Tema.Apple.Vera.Chat.self
        let passaggio = stato.dati.impostazioni.vera.mostraPassaggiVoce ? stato.passaggioVoce : nil
        if let testo = v.errore ?? passaggio {
            Text(testo)
                .carattereApple(ch.notaVoce)
                .foregroundColor(v.errore == nil ? ch.coloreVoce : ch.ascolto)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, Tema.Apple.Vera.Chat.sopraCampo)
        }
    }

    /// Cosa fa la voce di Vera adesso (si prepara, ti ascolta, ti risponde) con «Interrompi» e la chiusura della
    /// conversazione a voce. A riposo non c'è.
    @ViewBuilder
    private func capsulaVoce(_ v: StatoVoce) -> some View {
        let ch = Tema.Apple.Vera.Chat.self
        let ascolta = v.ascolta || stato.dettaturaAttiva
        if ascolta || v.parla || v.prepara || stato.conversazioneAVoce {
            let scritta = v.prepara ? "Vera · si prepara" : (ascolta ? "Vera · ti ascolta" : (v.parla ? "Vera · ti risponde" : "Vera · a voce"))
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
                    Button { stato.voceVera.zitta() } label: { Label("Interrompi", systemImage: "speaker.slash") }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .help("Vera smette di parlare")
                }
                if stato.conversazioneAVoce {
                    Button { stato.fermaVoce() } label: { Label("Chiudi la voce", systemImage: "stop.fill") }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .help("Chiudi la conversazione a voce · oppure di' a Vera «basta così»")
                }
            }
        }
    }

    /// Il contenuto che segue la voce e l'ascolto di Vera (nelle istantanee, lo stato di prova).
    @ViewBuilder
    private func conVoce<C: View>(@ViewBuilder _ contenuto: @escaping (StatoVoce) -> C) -> some View {
        if stato.persistente {
            OsservaVoce(ascolto: stato.ascoltoVera, voce: stato.voceVera, contenuto: contenuto)
        } else {
            contenuto(stato.voceIstantanea ?? StatoVoce())
        }
    }
}

/// Da quale messaggio di quale conversazione le bolle sono nuove.
private struct SegnoNuoviVera: Equatable {
    let chiave: String
    let indice: Int
}

// MARK: - Testata

/// A destra nella testata dell'app Vera: «Lavoro / Conversazione» a pillola e «Nuova conversazione».
/// Lavoro: i numeri vengono solo da Prisma e dalla scheda (Vera/Istruzioni/chat.md); conversazione: uso generale
/// (conversazione.md). Finché non scegli, Vera decide dalla domanda e il selettore mostra cosa ha deciso.
struct AzioniVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        let vuota = stato.conversazione(stato.veraPortafoglio ? VeraPortafoglio.chiave : stato.clienteAttivoId).isEmpty
        let fermo = stato.veraPortafoglio || stato.veraInCorso
        return HStack(spacing: Tema.Apple.Vera.Testata.spazio) {
            SegmentatoPillola(selezione: modalita, voci: [(ModalitaVera.lavoro, "Lavoro"), (ModalitaVera.conversazione, "Conversazione")])
                .disabled(fermo)
                .opacity(fermo ? Tema.Apple.Vera.Campo.opacitaSpento : 1)
                .help(stato.veraPortafoglio ? "Sul portafoglio Vera lavora sempre con le cifre di Prisma"
                                           : "Lavoro: i numeri solo da Prisma · Conversazione: domande di ogni tipo")
            // «Le routine» (fase 4): apre la pagina delle routine
            PulsanteRoutineVera()
            Button { stato.nuovaConversazione() } label: {
                Label("Nuova conversazione", systemImage: "square.and.pencil")
            }
            .buttonStyle(StileVetro())
            .disabled(vuota && stato.modalitaVeraScelta == nil)
            .help("Comincia da capo: la conversazione di adesso si chiude")
        }
    }

    private var modalita: Binding<ModalitaVera> {
        Binding(get: { stato.modalitaVeraMostrata }, set: { stato.modalitaVeraScelta = $0 })
    }
}

// MARK: - Voce

/// Lo stato della voce di Vera in un momento: ascolta, parla, cosa ha capito, perché non può ascoltare.
struct StatoVoce {
    var ascolta = false
    /// Vera prepara il riconoscimento (il microfono non è ancora acceso).
    var prepara = false
    var parla = false
    var trascritto = ""
    var errore: String?
    /// Quanto suona il microfono (0…1) mentre Vera ascolta.
    var livello: Float = 0
    /// Cosa fa Vera prima di sentirti («Mi preparo ad ascoltarti…»).
    var nota: String?
}

/// Segue l'ascolto e la voce di Vera e ridisegna solo il pezzo che ne dipende.
private struct OsservaVoce<C: View>: View {
    @ObservedObject var ascolto: AscoltoVera
    @ObservedObject var voce: VoceVera
    let contenuto: (StatoVoce) -> C

    var body: some View {
        var errore: String?
        if case .nonDisponibile(let m) = ascolto.stato { errore = m }
        return contenuto(StatoVoce(ascolta: ascolto.ascolta, prepara: ascolto.siPrepara, parla: voce.parla, trascritto: ascolto.trascritto, errore: errore, livello: ascolto.livello, nota: ascolto.nota))
    }
}

// MARK: - Bolle

/// La risposta di Vera mentre arriva (streaming): prima i puntini «sta scrivendo», poi il testo che Qwen scrive,
/// parola per parola, nella bolla delle risposte. Osserva solo `FlussoVera`.
struct NuvolaInArrivo: View {
    let flusso: FlussoVera
    var portafoglio = false
    /// Chiamato quando arriva la prima parola.
    var iniziata: () -> Void = {}
    /// A ogni parola mostrata (la chat scorre in fondo).
    var avanza: (() -> Void)? = nil

    private var stato: String {
        if flusso.pensa { return "Vera ci sta pensando…" }
        if portafoglio || flusso.modalita == .lavoro { return "Vera sta leggendo il dossier…" }
        return "Vera sta scrivendo…"
    }

    var body: some View {
        let b = Tema.Apple.Vera.Bolla.self
        let calcoli = !flusso.testo.isEmpty && (portafoglio || flusso.modalita == .lavoro)
        VStack(alignment: .leading, spacing: 0) {
            Text(calcoli ? "Vera · Calcoli di Prisma" : "Vera")
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
        .padding(b.paddingVera)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaVera(mia: false)
        .frame(maxWidth: Tema.Apple.Vera.Chat.larghezzaMessaggio, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: flusso.testo.isEmpty) { vuoto in if !vuoto { iniziata() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(stato))
    }
}

/// Una bolla della conversazione. Vera: `chip`, larga fino a 640, con l'intestazione «Vera» o «Vera · Calcoli di
/// Prisma» (modalità lavoro, numeri dai motori), il testo, la scheda dei calcoli e le azioni. Tu: accento, a destra.
/// `nuova`: la bolla è appena arrivata (la tua entra a molla; quella di Vera si scrive parola per parola e poi
/// entrano la scheda dei calcoli e le azioni).
struct NuvolaVera: View {
    let messaggio: MessaggioVera
    /// Il tuo nome (le tue bolle, come nelle chat del Mac, non lo ripetono: sono a destra, nell'accento).
    let nomeUtente: String
    /// «Crea attività» e «Nota del cliente» solo nelle conversazioni di un cliente.
    var azioniCliente = true
    let creaAttivita: () -> Void
    let aggiungiNota: () -> Void
    var attivitaProposta: (PropostaVera) -> Void = { _ in }
    var posizioneProposta: (PropostaVera) -> Void = { _ in }
    var apriAzione: (AzioneVera) -> Void = { _ in }
    var annullaAzione: (AzioneVera) -> Void = { _ in }
    /// La scheda dei calcoli di Prisma sotto il testo (solo l'ultima risposta).
    var quadro: QuadroVera? = nil
    var nuova = false
    /// A ogni parola mostrata (la chat scorre in fondo).
    var avanza: (() -> Void)? = nil

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(StatoShell.self) private var stato
    @State private var testoScritto = false

    init(messaggio: MessaggioVera, nomeUtente: String, azioniCliente: Bool = true,
         creaAttivita: @escaping () -> Void, aggiungiNota: @escaping () -> Void,
         attivitaProposta: @escaping (PropostaVera) -> Void = { _ in },
         posizioneProposta: @escaping (PropostaVera) -> Void = { _ in },
         apriAzione: @escaping (AzioneVera) -> Void = { _ in },
         annullaAzione: @escaping (AzioneVera) -> Void = { _ in },
         quadro: QuadroVera? = nil, nuova: Bool = false, avanza: (() -> Void)? = nil) {
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

    /// L'elenco del mercato da mostrare: in modalità cliente solo la riga del cliente presente (gli altri clienti
    /// spariscono, anche dalle conversazioni già salvate) e niente «e altri N clienti».
    static func mercatoVisibile(_ esito: EsitoMercatoVera?, modoCliente: String?) -> EsitoMercatoVera? {
        guard var e = esito else { return nil }
        guard let id = modoCliente else { return e }
        e.toccati = e.toccati.filter { $0.clienteId == id }
        e.oltre = 0
        return e
    }

    var body: some View {
        if messaggio.autore == .utente {
            bollaUtente
        } else {
            bollaVeraVista
        }
    }

    private var bollaUtente: some View {
        let b = Tema.Apple.Vera.Bolla.self
        return HStack(spacing: 0) {
            Spacer(minLength: b.respiroUtente)
            Text(messaggio.testo)
                .carattereApple(b.messaggio)
                .foregroundColor(b.testoUtente)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(b.paddingUtente)
                .bollaVera(mia: true)
                .frame(maxWidth: Tema.Apple.Vera.Chat.larghezzaMessaggio, alignment: .trailing)
                .entrataBollaUtente(nuova)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var bollaVeraVista: some View {
        let b = Tema.Apple.Vera.Bolla.self
        let resto = !nuova || testoScritto || fermo
        return VStack(alignment: .leading, spacing: 0) {
            Text(QuadroVera.ammessa(messaggio) ? "Vera · Calcoli di Prisma" : "Vera")
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
            // «Mai a caso»: il rimando alla fonte dopo ogni cifra («20.800 €¹»)
            TestoProgressivo(testo: messaggio.fonti.map { FontiVera.conRimandi(messaggio.testo, fonti: $0) } ?? messaggio.testo, anima: nuova, staffetta: nuova ? .riceve : .nessuna,
                             avanza: avanza, finito: { testoScritto = true })
                .carattereApple(b.messaggio)
                .foregroundColor(b.testo)
                .textSelection(.enabled)
            if resto {
                VStack(alignment: .leading, spacing: 0) {
                    if let q = quadro {
                        QuadroVisivoVera(quadro: q)
                            .padding(.top, b.sopraScheda)
                    }
                    // Lo scenario «E se…?»: la tabella prima/dopo di Prisma con «Salva nel dossier» e «Apri in Simulazioni»
                    if let s = messaggio.scenario {
                        SchedaScenarioVeraVista(scheda: s, messaggio: messaggio.id, entra: false)
                    }
                    // «Chiedi alla tua clientela»: i filtri capiti e la tabella dei clienti
                    if let r = messaggio.clientela {
                        TabellaClientelaVista(risultato: r)
                    }
                    // Fase 4, sopra la scheda «Conferma» che ne raccoglie le azioni: i passi spuntati e il risultato della
                    // routine, la settimana con gli orari proposti e lo spostamento in blocco, il piano a passi
                    if let e = messaggio.esitoRoutine {
                        RoutineEsitoVista(esito: e, messaggio: messaggio.id, anima: nuova)
                    }
                    if let o = messaggio.agendaOrari, !o.proposte.isEmpty {
                        AgendaOrganizzaOrariVista(messaggio: messaggio.id, ricerca: o, scelto: messaggio.agendaOrariScelto)
                    }
                    // Annullato, lasciato stare o sostituito: la griglia mostra solo gli impegni di adesso (pillola neutra)
                    if let s = messaggio.agendaSpostamento, !s.mosse.isEmpty {
                        AgendaOrganizzaSpostamentoVista(spostamento: s, eseguito: messaggio.conferma?.stato == .eseguita, scheda: messaggio.conferma)
                    }
                    if let p = messaggio.pianoPassi {
                        PianoPassiVeraVista(piano: p, messaggio: messaggio.id)
                    }
                    // «Fallo tu»: la scheda di conferma, niente si esegue prima di «Conferma»
                    // In modalità cliente non si vedono le schede del sussurro e del mercato, né quelle di una routine,
                    // di un piano o di azioni su altri clienti (`schedaVisibileSulloSchermo`)
                    if let c = messaggio.conferma, stato.schedaVisibileSulloSchermo(messaggio) {
                        SchedaConfermaVeraVista(scheda: c, messaggio: messaggio.id)
                            .padding(.top, b.sopraScheda)
                    }
                    // «Mai a caso»: la fonte di ogni cifra
                    if let f = messaggio.fonti, !f.isEmpty {
                        FontiVeraVista(fonti: f)
                    }
                    // Fase 2: «Il cliente in 30 secondi» e gli articoli della biblioteca delle norme
                    if let t = messaggio.trenta {
                        TrentaSecondiVista(scheda: t)
                    }
                    if let n = messaggio.norme {
                        NormeVeraVista(risposta: n)
                    }
                    // Fase 3: promesse, seconda lettura, confronto, coperture e resoconto
                    if let p = messaggio.promesse, !p.isEmpty {
                        PromesseVeraVista(ids: p)
                    }
                    if let l = messaggio.lettura, !l.avvisi.isEmpty {
                        SecondaLetturaVeraVista(esito: l)
                    }
                    if let c = messaggio.confronto {
                        ConfrontoVeraVista(id: c)
                    }
                    if let c = messaggio.copertura {
                        CoperturaVeraVista(documentoId: c)
                    }
                    if let r = messaggio.resoconto {
                        ResocontoVeraVista(incontroId: r)
                    }
                    // Fase 4: il tagliando dei dati ("" = tutto l'archivio, altrimenti l'id del cliente), il mercato per i
                    // tuoi clienti, il tuo stile e i tre livelli
                    if let t = messaggio.tagliando {
                        TagliandoChatVista(clienteId: t)
                    }
                    if let e = Self.mercatoVisibile(messaggio.mercatoClienti, modoCliente: stato.modoCliente), !e.toccati.isEmpty {
                        SchedaMercatoClientiVeraVista(esito: e, messaggio: messaggio.id)
                    }
                    if let s = messaggio.stileVera {
                        SchedaStileVeraChat(scheda: s)
                    }
                    if let t = messaggio.treLivelli {
                        TreLivelliVeraVista(id: t, livello: messaggio.treLivelliLivello ?? .tecnico)
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
        .padding(b.paddingVera)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bollaVera(mia: false)
        .frame(maxWidth: Tema.Apple.Vera.Chat.larghezzaMessaggio, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le azioni proposte da Vera (calcolate da Prisma): una tile con le righe divise dal filo.
    private func elencoProposte(_ proposte: [PropostaVera]) -> some View {
        let b = Tema.Apple.Vera.Bolla.self
        let s = Tema.Apple.Vera.SchedaCalcoli.self
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(proposte.enumerated()), id: \.element.id) { i, p in
                HStack(spacing: b.spazioAzioni) {
                    Text("\(i + 1). \(p.titolo)")
                        .carattereApple(b.proposta)
                        .foregroundColor(b.testo)
                        .lineLimit(1)
                    Spacer(minLength: b.spazioAzioni)
                    if p.attivitaId != nil {
                        Text(NuvolaVera.segnoAttivitaCreata)
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
        let b = Tema.Apple.Vera.Bolla.self
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
            VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: b.spazioAzioni) {
                if azioniCliente && messaggio.motore != StatoShell.motoreAzioni && messaggio.conferma == nil {
                    azione("✓ Crea attività", creaAttivita)
                    azione("＋ Nota del cliente", aggiungiNota)
                }
                azione("Copia") {
                    Appunti.copia((messaggio.titolo.map { $0 + "\n\n" } ?? "") + messaggio.testo)
                }
            }
            // «Impara dalle correzioni»: 👍 e 👎 sotto le risposte scritte da Qwen
            if messaggio.motore != StatoShell.motoreAzioni, messaggio.motore != MotoriVera.sintesi.nome, messaggio.titolo != "Vera non ha potuto rispondere" {
                PolliciVera(messaggio: messaggio)
                    .padding(.top, b.spazioAzioni)
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

    private static func apri(_ a: AzioneVera) -> String {
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
struct OndaVera: View {
    let attiva: Bool
    /// Mentre Vera ascolta, l'onda segue il microfono: ferma vuol dire che il microfono non sente.
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

/// In modalità cliente l'elenco del mercato sotto una risposta di Vera mostra solo il cliente presente, senza
/// «e altri N clienti»; fuori dalla modalità cliente resta intero. Da chiamare in `Prisma --prova-vera`.
enum ProvaMercatoModoCliente {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        guard case .evento(let e) = MercatoClientiVera.riconosci("Le borse hanno perso l'8% in una settimana", oggi: Date(), cal: .current) else {
            return controlla(false, "Mercato in modalità cliente: evento borse non riconosciuto")
        }
        var esito = s.esitoMercatoClientiVera(e)
        esito.oltre = 2
        guard esito.toccati.count >= 2, let primo = esito.toccati.first?.clienteId else {
            return controlla(false, "Mercato in modalità cliente: servono almeno due clienti toccati dai dati di prova")
        }
        controlla(NuvolaVera.mercatoVisibile(esito, modoCliente: nil) == esito,
                  "Mercato in modalità cliente: fuori dalla modalità cliente l'elenco resta intero")
        let filtrato = NuvolaVera.mercatoVisibile(esito, modoCliente: primo)
        controlla(filtrato?.toccati.map(\.clienteId) == [primo] && filtrato?.oltre == 0,
                  "Mercato in modalità cliente: si vede solo il cliente presente, senza «e altri N clienti»")
        controlla(NuvolaVera.mercatoVisibile(esito, modoCliente: "nessuno-toccato")?.toccati.isEmpty == true,
                  "Mercato in modalità cliente: un cliente non toccato non vede nessuna riga")
    }
}
