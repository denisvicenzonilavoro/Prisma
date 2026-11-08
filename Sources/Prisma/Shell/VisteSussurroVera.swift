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

    var body: some View {
        let _ = ContaCorpi.segna()
        let voci = stato.vociSussurro(clienteId: cliente.id)
        if !voci.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                TestataSussurro(quante: voci.count, pensa: stato.veraInCorso)
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
        }
    }

    // MARK: Una voce

    private func riga(_ v: VoceSussurro) -> some View {
        // La scheda in attesa, altrimenti l'ultima della voce: così `onChange` vede anche il passaggio a «eseguita»
        let messaggio = stato.schedaSussurroAperta(v) ?? stato.ultimaSchedaSussurro(v)
        let scheda = messaggio.flatMap { stato.messaggioVera($0)?.conferma }
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
                    pulsante(v, aperta: scheda?.stato == .daConfermare)
                    menu(v)
                    Spacer(minLength: 0)
                }
                .padding(.top, A.sussurroSopraPulsante)
                if let messaggio, let scheda, scheda.stato == .daConfermare {
                    SchedaConfermaVeraVista(scheda: scheda, messaggio: messaggio)
                        .padding(.top, A.sussurroSopraScheda)
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
            guard stato.schedaSussurroAperta(v) == nil else { return }
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

    /// Confermata ed eseguita: la voce si chiude (l'esito resta nella conversazione del cliente). Lasciata stare,
    /// sostituita o annullata: torna il pulsante.
    private func cambiata(_ v: VoceSussurro, stato nuovo: SchedaConfermaVera.Stato?, scheda: SchedaConfermaVera?) {
        switch nuovo {
        case .eseguita?:
            let esito = scheda?.attive.compactMap(\.esito).first
            if esito?.fatta != false { stato.chiudiSussurro(v) }
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

    /// L'id del messaggio di Vera con la scheda «Conferma» ancora in attesa per la voce, cercato nella conversazione
    /// del cliente della voce (l'ultimo: origine sussurro, da confermare, stessa voce). nil se non ce n'è.
    func schedaSussurroAperta(_ v: VoceSussurro) -> String? {
        Self.cercaSchedaSussurro(v, in: conversazione(v.clienteId), soloInAttesa: true)
    }

    /// L'id dell'ultimo messaggio di Vera con una scheda «Conferma» della voce, in qualunque stato.
    func ultimaSchedaSussurro(_ v: VoceSussurro) -> String? {
        Self.cercaSchedaSussurro(v, in: conversazione(v.clienteId), soloInAttesa: false)
    }

    /// La ricerca pura. La voce si riconosce dalla chiave negli argomenti dell'azione («sussurro»), quando c'è, o
    /// dalla richiesta scritta da `schedaSussurro`.
    static func cercaSchedaSussurro(_ v: VoceSussurro, in messaggi: [MessaggioVera], soloInAttesa: Bool) -> String? {
        let richiesta = testoRichiestaSussurro(v)
        return messaggi.last { m in
            guard let s = m.conferma, s.origine == .sussurro else { return false }
            if soloInAttesa, s.stato != .daConfermare { return false }
            let chiavi = s.azioni.compactMap { $0.argomenti["sussurro"] }
            return chiavi.isEmpty ? s.richiesta == richiesta : chiavi.contains(v.chiave)
        }?.id
    }
}

/// «Vera ti sussurra · tre cose da sapere adesso», con la sfera viva (pulsa mentre Vera lavora).
private struct TestataSussurro: View {
    let quante: Int
    let pensa: Bool

    var body: some View {
        HStack(spacing: A.sussurroSpazioTestata) {
            SferaVera(misura: A.sussurroSfera, viva: true, pensa: pensa)
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
    }
}
