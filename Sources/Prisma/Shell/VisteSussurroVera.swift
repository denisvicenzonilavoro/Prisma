import SwiftUI

// «Il sussurro» nel dossier (Vera/BRIEF.md, funzione 7; Design/template-vera.html, «Il sussurro»): la card «Vera ti
// sussurra · tre cose da sapere adesso» in cima alla colonna laterale della Panoramica, con la sfera di Vera e il filo
// color rubino. Ogni voce ha il pallino del tono (rosso: prima di tutto, arancio: presto, blu: da sapere), il testo, la
// fonte e il pulsante dell'azione; nel menu «…» il posto da aprire e «Non ora».
// - Il pulsante di un'azione che cambia qualcosa apre sotto la voce la scheda «Conferma» (la stessa della chat, che la
//   tiene anche nella conversazione del cliente): niente si segna prima di «Conferma». Confermata, la voce si chiude
//   per una settimana; lasciata stare o annullata, torna il pulsante.
// - Senza voci la card non c'è (il sussurro parla solo quando ha qualcosa da dire). Mai in modalità cliente.
// - Le voci entrano a cascata dentro la card; con «Riduci movimento» e nelle istantanee sono subito al loro posto
//   (`entrataCascata` legge `\.prismaCalmo` e `\.modoIstantanea`), la sfera è ferma al fotogramma 0.
// Valori in Tema.Apple+FaseQuattroVera.swift (prefisso `sussurro`) e nella Panoramica del dossier.

private typealias P = Tema.Apple.Clienti.Panoramica
private typealias A = Tema.Apple

/// La card del sussurro per un cliente (Panoramica del dossier).
struct SussurroDossierVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    // La scheda «Conferma» aperta sotto una voce si ricava dalla conversazione del cliente
    // (`StatoShell.schedaSussurroAperta`), mai da uno @State: cambiando scheda del dossier, cliente o chiudendo il
    // dossier la vista rinasce e la scheda in attesa deve restare sotto la voce, con il pulsante disattivato.
    /// La card è uscita del tutto dalla vista scorrendo la Panoramica: la sfera smette di respirare.
    @State private var fuoriVista = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let voci = vociInCache()
        if !voci.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                TestataSussurro(quante: voci.count, viva: !fuoriVista, pensa: stato.veraInCorso)
                VStack(alignment: .leading, spacing: A.sussurroSpazioVoci) {
                    ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                        riga(v)
                            .entrataCascata(i, base: A.Moto.Cascata.baseDentroApp, sfocatura: false)
                    }
                }
                .padding(.top, A.sussurroSopraVoci)
            }
            .padding(P.paddingLaterali)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .superficieApple(P.superficie)
            .overlay {
                RoundedRectangle(cornerRadius: P.raggio, style: .continuous)
                    .strokeBorder(A.sussurroBordo, lineWidth: A.sussurroFiloBordo)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Vera ti sussurra"))
            .fuoriDalloScorrimento { fuoriVista = $0 }
        }
    }

    /// Le voci del cliente, calcolate una volta finché non cambiano i dati dei calcoli, il giorno, l'ora, le voci chiuse del
    /// cliente o i ricordi di Vera su di lui (`ricavato`): la card si ridisegna anche quando Vera lavora, con un messaggio
    /// nella chat o un'impostazione qualsiasi (aspetto compreso), e lì non serve rifare la conformità e le regole. Voci
    /// chiuse e ricordi vanno nella chiave perché non sono dati dei calcoli; si leggono qui, fuori dal calcolo, così la
    /// card segue ancora le voci chiuse e le impostazioni di Vera come prima.
    private func vociInCache() -> [VoceSussurro] {
        guard stato.sussurroSiVede else { return [] }
        let id = cliente.id
        let oggi = Date()
        let chiuse = SussurroVera.chiuse(stato.dati.sussurriChiusi, clienteId: id, oggi: oggi).sorted().joined(separator: ",")
        let ricordi = stato.ricordiSussurro(id)
        let chiave = "sussurro|\(id)|\(DerivatiDati.ora(oggi))|\(chiuse)|\(ricordi.count)|\(ricordi.hashValue)"
        return stato.ricavato(chiave) { () -> [VoceSussurro] in
            stato.vociSussurro(clienteId: id, oggi: oggi)
        }
    }

    // MARK: Una voce

    private func riga(_ v: VoceSussurro) -> some View {
        // La scheda in attesa, altrimenti l'ultima della voce: così `onChange` vede anche il passaggio a «eseguita».
        // Solo le schede fatte tutte di azioni di questa voce: una scheda della chat con più voci resta nella chat e qui
        // compare solo il rimando (niente copie della stessa scheda sotto ogni voce)
        let messaggio = stato.schedaSussurroAperta(v) ?? stato.ultimaSchedaSussurro(v)
        let scheda = messaggio.flatMap { stato.messaggioVera($0)?.conferma }
        let inChat = scheda?.stato == .daConfermare ? nil : stato.schedaSussurroInChat(v)
        return HStack(alignment: .top, spacing: A.sussurroSpazioRiga) {
            Circle()
                .fill(Self.colore(v.tono))
                .frame(width: A.sussurroPallino, height: A.sussurroPallino)
                .padding(.top, A.sussurroSopraPallino)
                .accessibilityLabel(Text(Self.etichetta(v.tono)))
            VStack(alignment: .leading, spacing: 0) {
                Text(v.testo)
                    .carattereApple(A.sussurroTesto)
                    .foregroundColor(A.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                Text(v.fonte)
                    .carattereApple(A.sussurroFonte)
                    .foregroundColor(A.Colore.inchiostro3)
                    .lineLimit(1)
                    .padding(.top, A.sussurroSopraFonte)
                HStack(spacing: A.sussurroSpazioPulsanti) {
                    pulsante(v, aperta: scheda?.stato == .daConfermare || inChat != nil)
                    menu(v)
                    Spacer(minLength: 0)
                }
                .padding(.top, A.sussurroSopraPulsante)
                if let messaggio, let scheda, scheda.stato == .daConfermare {
                    SchedaConfermaVeraVista(scheda: scheda, messaggio: messaggio)
                        .padding(.top, A.sussurroSopraScheda)
                } else if let inChat {
                    Button("In attesa nella chat di Vera") { stato.apriSchedaSussurroInChat(inChat) }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .padding(.top, A.sussurroSopraScheda)
                        .help("La scheda «Conferma» con questa voce aspetta nella chat di Vera")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(A.sussurroPaddingVoce)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(A.Superficie.tile, raggio: A.Raggio.tile)
        .onChange(of: scheda?.stato) { nuovo in cambiata(v, stato: nuovo, scheda: scheda) }
        .accessibilityElement(children: .contain)
    }

    private func pulsante(_ v: VoceSussurro, aperta: Bool) -> some View {
        Button(v.azione.titolo) {
            // Una scheda già in attesa per la voce non se ne fa un'altra (niente doppioni né attività ripetute)
            guard stato.schedaSussurroAperta(v) == nil, stato.schedaSussurroInChat(v) == nil else { return }
            stato.eseguiSussurro(v)
        }
        .buttonStyle(.apple)
        .fixedSize()
        // Con la scheda aperta il pulsante aspetta «Conferma» o «Lascia stare»
        .disabled(aperta || (stato.solaLettura && (v.azione.cambia || v.azione.tipo == .tieniAMente)))
        .help(v.azione.cambia ? "Prepara l'attività: la segno solo con «Conferma»" : v.azione.titolo)
    }

    private func menu(_ v: VoceSussurro) -> some View {
        Menu {
            if let dove = stato.doveSussurro(v) {
                Button(dove) { stato.apriFonteSussurro(v) }
            }
            Button("Non ora: torna tra una settimana") {
                stato.chiudiSussurro(v)
            }
            .disabled(stato.solaLettura)
        } label: {
            Image(systemName: "ellipsis")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel(Text("Altro sulla voce"))
    }

    /// Confermata ed eseguita: la voce la chiude già `chiudiSussurriConfermati`, azione per azione (solo quelle attive e
    /// riuscite); qui resta l'avviso con l'esito dell'azione di questa voce. Solo le schede vecchie, senza la chiave della
    /// voce negli argomenti, si chiudono da qui. Lasciata stare, sostituita o annullata: torna il pulsante.
    private func cambiata(_ v: VoceSussurro, stato nuovo: SchedaConfermaVera.Stato?, scheda: SchedaConfermaVera?) {
        switch nuovo {
        case .eseguita?:
            guard let scheda else { return }
            let conChiave = scheda.azioni.contains { $0.argomenti[StatoShell.argomentoSussurro] != nil }
            let esito: EsitoAzioneVera?
            if conChiave {
                esito = scheda.attive.first { $0.argomenti[StatoShell.argomentoSussurro] == v.chiave }?.esito
            } else {
                esito = scheda.attive.compactMap(\.esito).first
                if esito?.fatta == true { stato.chiudiSussurro(v) }
            }
            if let testo = esito?.messaggio { stato.mostraAvviso(testo, daVera: true) }
        default:
            // In attesa, lasciata stare, sostituita o annullata: la scheda si ricava di nuovo dalla conversazione
            break
        }
    }

    // MARK: Toni

    static func colore(_ t: TonoSussurro) -> Color {
        switch t {
        case .rosso: return A.sussurroRosso
        case .arancio: return A.sussurroArancio
        case .blu: return A.sussurroBlu
        }
    }

    static func etichetta(_ t: TonoSussurro) -> String {
        switch t {
        case .rosso: return "Da fare prima di tutto"
        case .arancio: return "Presto"
        case .blu: return "Da sapere"
        }
    }
}

extension StatoShell {
    /// La richiesta con cui `schedaSussurro` scrive la scheda di una voce (serve per ritrovarla nella conversazione).
    static func testoRichiestaSussurro(_ v: VoceSussurro) -> String { "\(v.azione.titolo): \(v.testo)" }

    /// Dove cercare le schede di una voce: la conversazione del cliente e quella del portafoglio (una domanda fatta in
    /// chat dal portafoglio, «cosa devo sapere su Sofia?», mette lì la sua scheda).
    private func messaggiSussurro(_ v: VoceSussurro) -> [MessaggioVera] {
        conversazione(v.clienteId) + conversazione(VeraPortafoglio.chiave)
    }

    /// L'id del messaggio di Vera con la scheda «Conferma» ancora in attesa fatta tutta di azioni della voce (quella del
    /// pulsante del dossier, o una della chat con la sola voce), nella conversazione del cliente o del portafoglio.
    /// nil se non ce n'è.
    func schedaSussurroAperta(_ v: VoceSussurro) -> String? {
        Self.cercaSchedaSussurro(v, in: messaggiSussurro(v), soloInAttesa: true)
    }

    /// L'id dell'ultimo messaggio di Vera con una scheda «Conferma» fatta tutta di azioni della voce, in qualunque stato.
    func ultimaSchedaSussurro(_ v: VoceSussurro) -> String? {
        Self.cercaSchedaSussurro(v, in: messaggiSussurro(v), soloInAttesa: false)
    }

    /// Una scheda della chat con più voci, ancora in attesa, che ha fra le azioni attive quella della voce: nel dossier
    /// la voce mostra il rimando alla chat (la scheda è una sola: confermarla esegue anche le altre voci).
    func schedaSussurroInChat(_ v: VoceSussurro) -> String? {
        Self.cercaSchedaSussurro(v, in: messaggiSussurro(v), soloInAttesa: true, soloDellaVoce: false)
    }

    /// Apre Vera sulla conversazione che tiene la scheda (quella del cliente o il portafoglio).
    func apriSchedaSussurroInChat(_ id: String) {
        guard !inModoCliente else { return }
        let nelPortafoglio = conversazione(VeraPortafoglio.chiave).contains { $0.id == id }
        if nelPortafoglio {
            veraPortafoglio = true
        } else if let c = conversazioniConMessaggio(id) {
            clienteAttivoId = c
            veraPortafoglio = false
        }
        if !aperta(.vera) { apri(.vera) }
    }

    /// Il cliente della conversazione che contiene il messaggio (fra quelle dei clienti).
    private func conversazioniConMessaggio(_ id: String) -> String? {
        dati.clienti.first { c in conversazione(c.id).contains { $0.id == id } }?.id
    }

    /// La ricerca pura (il più recente). La voce si riconosce dalla chiave e dal cliente negli argomenti delle azioni
    /// («sussurro», «cliente»), quando ci sono, o dalla richiesta scritta da `schedaSussurro` (schede vecchie).
    /// `soloDellaVoce`: tutte le azioni della scheda sono della voce (si mostra sotto la voce); altrimenti basta
    /// un'azione attiva della voce (una scheda della chat con più voci: una voce tolta con ✕ non si lega più).
    static func cercaSchedaSussurro(_ v: VoceSussurro, in messaggi: [MessaggioVera], soloInAttesa: Bool, soloDellaVoce: Bool = true) -> String? {
        let richiesta = testoRichiestaSussurro(v)
        let chiaveSussurro = StatoShell.argomentoSussurro
        func dellaVoce(_ a: AzioneConferma) -> Bool {
            a.argomenti[chiaveSussurro] == v.chiave && (a.argomenti["cliente"].map { $0 == v.clienteId } ?? true)
        }
        var trovato: MessaggioVera?
        for m in messaggi {
            guard let s = m.conferma, s.origine == .sussurro else { continue }
            if soloInAttesa, s.stato != .daConfermare { continue }
            let conChiave = s.azioni.contains { $0.argomenti[chiaveSussurro] != nil }
            let vale: Bool
            if !conChiave {
                vale = soloDellaVoce && s.richiesta == richiesta
            } else if soloDellaVoce {
                // Contano le azioni attive: una riga tolta con ✕ non lega (né slega) la scheda alla voce
                vale = !s.attive.isEmpty && s.attive.allSatisfy(dellaVoce)
            } else {
                vale = !s.attive.allSatisfy(dellaVoce) && s.attive.contains(where: dellaVoce)
            }
            if vale, trovato.map({ m.data >= $0.data }) ?? true { trovato = m }
        }
        return trovato?.id
    }
}

/// «Vera ti sussurra · tre cose da sapere adesso», con la sfera viva (pulsa mentre Vera lavora).
private struct TestataSussurro: View {
    let quante: Int
    /// false con la card scrollata via (`fuoriDalloScorrimento`): la sfera non respira.
    var viva = true
    let pensa: Bool

    var body: some View {
        HStack(spacing: A.sussurroSpazioTestata) {
            SferaVera(misura: A.sussurroSfera, viva: viva, pensa: pensa)
            VStack(alignment: .leading, spacing: A.sussurroSpazioTitoli) {
                Text("Vera ti sussurra")
                    .carattereApple(A.sussurroTitolo)
                    .foregroundColor(A.sussurroRubino)
                Text(Self.sottotitolo(quante))
                    .carattereApple(A.sussurroSottotitolo)
                    .foregroundColor(A.Colore.inchiostro2)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    static func sottotitolo(_ n: Int) -> String {
        switch n {
        case 1: return "una cosa da sapere adesso"
        case 2: return "due cose da sapere adesso"
        default: return "\(SchedaConfermaVera.numero(n)) cose da sapere adesso"
        }
    }
}

/// La scheda «Conferma» di una voce si ritrova dalla conversazione del cliente (non da uno @State della vista): dopo
/// un cambio di scheda del dossier resta sotto la voce, il pulsante non ne crea una seconda, confermata non c'è più.
/// Da chiamare in `Prisma --prova-vera` (accanto a `ProvaCollegaSussurroVera`).
enum ProvaSchedaSussurroAperta {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        let oggi = Date()
        guard let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) else {
            return controlla(false, "Scheda del sussurro: manca Sofia tra i dati di prova")
        }
        s.dati.clienti[i].consensi = Consensi()
        guard let v = s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi).first(where: { $0.azione.cambia }) else {
            return controlla(false, "Scheda del sussurro: per Sofia senza consenso manca una voce da confermare")
        }
        controlla(s.schedaSussurroAperta(v) == nil, "Scheda del sussurro: prima del pulsante nessuna scheda in attesa")
        guard let mid = s.eseguiSussurro(v, oggi: oggi) else {
            return controlla(false, "Scheda del sussurro: il pulsante non prepara la scheda «Conferma»")
        }
        // La vista rinasce (nuova scheda del dossier): la scheda si ritrova dai dati
        controlla(s.schedaSussurroAperta(v) == mid, "Scheda del sussurro: la scheda in attesa si ritrova dalla conversazione del cliente")
        let altra = VoceSussurro(chiave: v.chiave + "-altra", clienteId: v.clienteId, categoria: v.categoria, tono: v.tono,
                                 testo: v.testo + " Altro.", azione: v.azione, fonte: v.fonte, rango: v.rango, data: v.data)
        controlla(s.schedaSussurroAperta(altra) == nil, "Scheda del sussurro: la scheda di una voce non vale per un'altra")
        let attivita = s.dati.attivita.count
        _ = s.confermaSchedaVera(messaggio: mid)
        controlla(s.schedaSussurroAperta(v) == nil && s.ultimaSchedaSussurro(v) == mid && s.dati.attivita.count == attivita + 1,
                  "Scheda del sussurro: confermata, la scheda non è più in attesa e l'attività è una sola")
        schedaDellaChat(controlla)
    }

    /// Una scheda della chat con più voci («Cosa devo sapere su Sofia?»): non si lega a nessuna voce del dossier (niente
    /// copie sotto ogni voce), la voce mostra il rimando; una voce tolta con ✕ non si lega più. Chiesta dal portafoglio,
    /// la scheda si ritrova lo stesso.
    private static func schedaDellaChat(_ controlla: (Bool, String) -> Void) {
        let oggi = Date()
        for chiave in ["sofia", VeraPortafoglio.chiave] {
            let s = StatoShell(persistente: false)
            s.rispostePreparate = true
            guard let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) else { return }
            s.dati.clienti[i].consensi = Consensi()
            if chiave == "sofia" { s.clienteAttivoId = "sofia"; s.veraPortafoglio = false } else { s.veraPortafoglio = true }
            let voci = s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi).filter { $0.azione.cambia }
            _ = s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: chiave)
            guard let m = s.conversazione(chiave).last(where: { $0.conferma?.origine == .sussurro }), let scheda = m.conferma else {
                controlla(voci.isEmpty, "Scheda del sussurro (\(chiave)): la domanda in chat prepara la scheda delle voci")
                continue
            }
            let legate = voci.filter { v in scheda.azioni.contains { $0.argomenti[StatoShell.argomentoSussurro] == v.chiave } }
            if scheda.azioni.count > 1 {
                controlla(legate.allSatisfy { s.schedaSussurroAperta($0) == nil && s.schedaSussurroInChat($0) == m.id },
                          "Scheda del sussurro (\(chiave)): la scheda della chat con più voci non si copia sotto ogni voce, la voce rimanda alla chat")
                // Una voce tolta con ✕ non si lega più alla scheda
                if let tolta = legate.first, let k = scheda.azioni.firstIndex(where: { $0.argomenti[StatoShell.argomentoSussurro] == tolta.chiave }) {
                    s.aggiornaSchedaVera(messaggio: m.id) { $0.azioni[k].tolta = true }
                    controlla(s.schedaSussurroInChat(tolta) == nil && s.schedaSussurroAperta(tolta) == nil,
                              "Scheda del sussurro (\(chiave)): la voce tolta con ✕ non è più legata alla scheda della chat")
                }
            } else if let v = legate.first {
                controlla(s.schedaSussurroAperta(v) == m.id, "Scheda del sussurro (\(chiave)): la scheda della chat con la sola voce si ritrova nel dossier")
            }
        }
    }
}
