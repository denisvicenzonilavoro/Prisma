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
    /// La scheda «Conferma» aperta sotto una voce: chiave della voce → id del messaggio di Vera che la contiene.
    @State private var schede: [String: String] = [:]

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
        let messaggio = schede[v.chiave]
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
            if let id = stato.eseguiSussurro(v) { schede[v.chiave] = id }
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
                schede[v.chiave] = nil
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
            schede[v.chiave] = nil
            let esito = scheda?.attive.compactMap(\.esito).first
            if esito?.fatta != false { stato.chiudiSussurro(v) }
            if let testo = esito?.messaggio { stato.mostraAvviso(testo, daVera: true) }
        case .daConfermare?:
            break
        default:
            schede[v.chiave] = nil
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
