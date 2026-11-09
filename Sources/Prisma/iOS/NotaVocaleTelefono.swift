#if os(iOS)
import SwiftUI
import UIKit

// La nota vocale sull'iPhone e sull'iPad (Design/template-luce-specifica.md §6.2.1 §1.3, §6.2.4, «Luce» giro 13):
// - Incontri sull'iPhone: in alto il pulsante grande «Nota veloce», sotto le «Note in partenza» (cifrate sul telefono
//   finché il Mac non le riceve) e la riga sul copilota (che è sull'iPad e sul Mac);
// - la schermata «Una nota veloce» (a tutto schermo, nel tema dell'iPhone): l'ora e «Prisma» (mai «In macchina»), il
//   titolo, «Dopo la visita da ‹Nome›» o «Di chi parli? Dillo nella nota», il testo che si scrive mentre parli, l'onda
//   dal livello vero del microfono, il pulsante (tocca per iniziare e per fermare, o tieni premuto per parlare), la riga
//   di stato, l'avviso «Detta solo tu: se il cliente è con te, usa il copilota» (decisione 55) e lo scaricamento
//   dell'italiano quando serve (decisione 32). A nota fermata il testo si corregge, poi «Manda al Mac» (✓).
// - Consegna: una nota alla volta sul ponte; «accettata» la toglie dalla coda, il Mac non trovato la lascia (con un solo
//   nuovo tentativo dopo aver dimenticato l'indirizzo vecchio). All'apertura, al ritorno in primo piano, dopo ogni nota
//   e da «Riprova adesso». Nessuna ricerca continua del Mac (niente Timer).

// MARK: - Incontri sull'iPhone

struct IncontriTelefono: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.istantaneaSchermo) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    private typealias M = Tema.Apple.NotaVocale.Mobile

    var body: some View {
        let _ = ContaCorpi.segna()
        let nota = stato.notaTelefono
        FondoTelefono {
            Button { stato.notaVeloceAperta = true } label: {
                HStack(spacing: M.spazio) {
                    GlifoLuceVista(glifo: .voce, lato: M.glifo, colore: Tema.Colore.Componenti.testoSuColore)
                    Text("Nota veloce").carattereApple(M.pulsante)
                }
                .frame(maxWidth: .infinity, minHeight: M.altezzaPulsante)
            }
            .buttonStyle(.applePrimarioGrande)
            .accessibilityHint(Text("Detta una nota dopo una visita: diventa testo qui sull’iPhone e va al Mac"))
            NoteInPartenza(nota: nota)
            VuotoTelefono(testo: "Il copilota dell’incontro è sull’iPad e sul Mac. Qui detti le note tra una visita e l’altra.")
        }
        .fullScreenCover(isPresented: Bindable(stato).notaVeloceAperta) {
            // Il foglio a tutto schermo riceve lo stato delle istantanee e «Riduci movimento» (come Inquadra)
            NotaVocaleTelefono(nota: nota)
                .environment(stato)
                .environment(\.istantaneaSchermo, istantanea)
                .prismaCalmo(calmo)
        }
        .onAppear { stato.leggiNoteInPartenza() }
    }
}

/// L'elenco «Note in partenza»: le note che il Mac non ha ancora ricevuto, cancellabili, con «Riprova adesso».
struct NoteInPartenza: View {
    @Environment(StatoShell.self) var stato
    let nota: StatoNotaVocaleTelefono

    private typealias M = Tema.Apple.NotaVocale.Mobile

    var body: some View {
        if !nota.coda.isEmpty {
            VStack(alignment: .leading, spacing: M.spazio) {
                HStack {
                    Text("Note in partenza")
                        .carattereApple(M.titoloCoda)
                        .foregroundColor(M.coloreVoceCoda)
                    Spacer(minLength: 0)
                    Button("Riprova adesso") { stato.consegnaNoteInPartenza() }
                        .buttonStyle(.apple)
                }
                ForEach(nota.coda) { v in
                    HStack(alignment: .top, spacing: M.spazio) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(v.nota.testo)
                                .carattereApple(M.voceCoda)
                                .foregroundColor(M.coloreVoceCoda)
                                .lineLimit(Tema.Apple.NotaVocale.Telefono.massimoRigheVoceCoda)
                            Text(Formati.dataOra.string(from: v.nota.quando) + (v.ultimoMotivo == nil ? "" : " · non ancora arrivata"))
                                .carattereApple(M.dettaglioCoda)
                                .foregroundColor(M.coloreDettaglioCoda)
                        }
                        Spacer(minLength: 0)
                        Button { stato.cancellaNotaInPartenza(v.id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.apple)
                            .accessibilityLabel(Text("Cancella la nota"))
                    }
                    .padding(M.paddingCoda)
                    .superficieApple(M.superficieCoda)
                }
            }
        }
    }
}

// MARK: - La schermata «Una nota veloce»

struct NotaVocaleTelefono: View {
    @Environment(StatoShell.self) var stato
    let nota: StatoNotaVocaleTelefono
    @Environment(\.istantaneaSchermo) private var istantanea

    private typealias M = Tema.Apple.NotaVocale.Mobile

    var body: some View {
        let _ = ContaCorpi.segna()
        ZStack(alignment: .topLeading) {
            M.fondo.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: M.spazio) {
                    HStack {
                        // Solo l'ora: Prisma non sa dove sei (mai «In macchina»)
                        Text(istantanea ? SchermoNotaOra.diProva : Formati.ora.string(from: Date()))
                        Spacer(minLength: 0)
                        Text("Prisma")
                    }
                    .carattereApple(M.testa)
                    .foregroundColor(M.coloreTesta)
                    Text("Una nota veloce")
                        .carattereApple(M.titolo)
                        .foregroundColor(M.coloreTitolo)
                    Text(sottotitolo)
                        .carattereApple(M.sottotitolo)
                        .foregroundColor(M.coloreSottotitolo)
                    testo
                    OndaNastroApple(livelli: nota.livelli, ascolta: nota.ascolta, parametri: Tema.Apple.NotaVocale.onda)
                        .frame(maxWidth: .infinity)
                    PulsanteRegistra(nota: nota)
                        .frame(maxWidth: .infinity)
                    if !nota.riga.isEmpty {
                        Text(nota.riga)
                            .carattereApple(M.stato)
                            .foregroundColor(M.coloreStato)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let a = nota.avviso {
                        Text(a)
                            .carattereApple(M.stato)
                            .foregroundColor(M.coloreStato)
                            .frame(maxWidth: .infinity)
                    }
                    pulsanti
                    Text("Detta solo tu: se il cliente è con te, usa il copilota")
                        .carattereApple(M.avviso)
                        .foregroundColor(M.coloreAvviso)
                        .fixedSize(horizontal: false, vertical: true)
                    NoteInPartenza(nota: nota)
                }
                .padding(M.margine)
                .padding(.top, M.margine)
            }
            Button {
                nota.chiudi()
                stato.notaVeloceAperta = false
            } label: { Image(systemName: "xmark") }
                .buttonStyle(.appleVetro)
                .accessibilityLabel(Text("Chiudi"))
                .padding(M.margine)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            guard !istantanea else { return }
            stato.preparaNotaTelefono()
        }
    }

    /// «Dopo la visita da Giulia» (appuntamento concluso da meno di 3 ore) o «Di chi parli? Dillo nella nota».
    private var sottotitolo: String {
        if let id = nota.clienteSuggerito, let c = stato.cliente(id) {
            return "Dopo la visita da \(c.nome.split(separator: " ").first.map(String.init) ?? c.nome)"
        }
        return "Di chi parli? Dillo nella nota"
    }

    @ViewBuilder private var testo: some View {
        if nota.fase == .fermata {
            TextEditor(text: Bindable(nota).testo)
                .font(M.testo.font)
                .foregroundColor(M.coloreTesto)
                .scrollContentBackground(.hidden)
                .frame(minHeight: M.altezzaTesto)
                .padding(M.paddingTesto)
                .superficieApple(M.superficieTesto)
                .accessibilityLabel(Text("Il testo della nota: correggilo prima di mandarlo"))
        } else {
            Text(nota.testoMostrato.isEmpty ? (nota.ascolta ? "…" : "Tocca il pulsante e parla") : nota.testoMostrato)
                .carattereApple(M.testo)
                .foregroundColor(nota.testoMostrato.isEmpty ? M.coloreTestoInCorso : M.coloreTesto)
                .frame(maxWidth: .infinity, minHeight: M.altezzaTesto, alignment: .topLeading)
                .padding(M.paddingTesto)
                .superficieApple(M.superficieTesto)
        }
    }

    @ViewBuilder private var pulsanti: some View {
        switch nota.fase {
        case .fermata:
            HStack(spacing: M.spazio) {
                Button { stato.mandaNotaAlMac() } label: {
                    Label("Manda al Mac", systemImage: "checkmark")
                }
                .buttonStyle(.applePrimarioGrande)
                .disabled(nota.testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Ricomincia") { nota.nuova() }
                    .buttonStyle(.appleGrande)
            }
        case .mandata, .inCoda:
            Button("Un’altra nota") { nota.nuova() }
                .buttonStyle(.appleGrande)
        case .pronta, .ascolto:
            EmptyView()
        }
    }
}

/// L'ora delle istantanee della schermata (dato di prova fisso).
enum SchermoNotaOra {
    static let diProva = "11:42"
}

/// Il pulsante tondo: tocca per iniziare e per fermare; tieni premuto per parlare (si ferma al rilascio).
struct PulsanteRegistra: View {
    let nota: StatoNotaVocaleTelefono
    /// La nota è partita tenendo premuto: si ferma al rilascio.
    @State private var tenuto = false

    /// Quanto tenere premuto perché valga «tieni premuto per parlare».
    static let tenutaMinima = 0.5

    var body: some View {
        FacciaPulsanteRegistra(ascolta: nota.ascolta, fatto: nota.fase == .fermata || nota.fase == .mandata,
                               bordo: Tema.Apple.NotaVocale.Registra.coloreBordoChiaro)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: Self.tenutaMinima, perform: {
                guard nota.fase != .ascolto else { return }
                tenuto = true
                nota.avvia()
            }, onPressingChanged: { premendo in
                guard !premendo, tenuto else { return }
                tenuto = false
                nota.ferma()
            })
            .onTapGesture { nota.alterna() }
            .accessibilityElement()
            .accessibilityLabel(Text(nota.ascolta ? "Ferma la nota" : "Detta una nota"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { nota.alterna() }
    }
}

// MARK: - Coda e consegna

extension StatoShell {
    /// La coda cifrata delle note in partenza (nil se il Portachiavi non dà la chiave).
    static func codaNoteVocali() -> CodaNoteVocali? {
        guard let cartella = CodaNoteVocali.cartellaPredefinita(), let chiave = PortachiaviNoteVocali.chiave() else { return nil }
        return CodaNoteVocali(cartella: cartella, chiave: chiave)
    }

    /// Rilegge le note in partenza dal file cifrato.
    func leggiNoteInPartenza() {
        guard persistente, let coda = Self.codaNoteVocali() else { return }
        let voci = coda.leggi()
        if voci != notaTelefono.coda { notaTelefono.coda = voci }
    }

    /// All'apertura della schermata: il cliente dell'appuntamento appena concluso (solo come indizio) e la coda.
    func preparaNotaTelefono() {
        if let a = MotoreNotaVocale.appuntamentoVicino(dati.appuntamenti, clienti: clienti, quando: Date()) {
            notaTelefono.clienteSuggerito = a.clienteId
            notaTelefono.appuntamentoSuggerito = a.id
        } else {
            notaTelefono.clienteSuggerito = nil
            notaTelefono.appuntamentoSuggerito = nil
        }
        leggiNoteInPartenza()
    }

    func cancellaNotaInPartenza(_ id: String) {
        let voci = notaTelefono.coda.filter { $0.id != id }
        notaTelefono.coda = voci
        guard persistente, let coda = Self.codaNoteVocali() else { return }
        try? coda.scrivi(voci)
    }

    /// «Manda al Mac» (✓): la nota entra nella coda cifrata, poi parte la consegna.
    @MainActor
    func mandaNotaAlMac() {
        guard let n = notaTelefono.notaPonte(dispositivo: UIDevice.current.name) else { return }
        let aggiunta = CodaNoteVocali.aggiungi(n, a: notaTelefono.coda)
        guard !aggiunta.tolta else {
            notaTelefono.codaPiena()
            return
        }
        notaTelefono.coda = aggiunta.voci
        if persistente, let coda = Self.codaNoteVocali() { try? coda.scrivi(aggiunta.voci) }
        consegnaNoteInPartenza(nota: n.id)
    }

    /// Manda al Mac le note in partenza, una alla volta. `nota`: quella appena dettata, per la riga di stato.
    @MainActor
    func consegnaNoteInPartenza(nota: String? = nil) {
        guard persistente, !StatoShell.consegnaNoteInCorso else { return }
        let vera = dati.impostazioni.vera
        guard vera.ponte.abbinato else {
            if nota != nil {
                notaTelefono.esito(.rifiutata("Collega il dispositivo al Mac: sul Mac, in Impostazioni › Vera, attiva «iPhone e iPad» e scrivi qui il codice che compare."), inCoda: true)
            }
            return
        }
        StatoShell.consegnaNoteInCorso = true
        Task { @MainActor [weak self] in
            defer { StatoShell.consegnaNoteInCorso = false }
            guard let self else { return }
            var voci = self.notaTelefono.coda
            var ritentato = false
            var ultima: RicevutaPonte?
            for v in voci {
                var r = await PonteVera.manda(.notaVocale(v.nota), vera: vera)
                // L'indirizzo ricordato può essere vecchio (altra rete): lo si dimentica e si cerca il Mac una volta
                if r.macIrraggiungibile, !ritentato {
                    ritentato = true
                    PonteVera.indirizzo = nil
                    r = await PonteVera.manda(.notaVocale(v.nota), vera: vera)
                }
                voci = CodaNoteVocali.dopoRicevuta(r, id: v.id, voci: voci)
                if v.id == nota { ultima = r }
                if r.macIrraggiungibile { break }
            }
            self.notaTelefono.coda = voci
            if let coda = Self.codaNoteVocali() { try? coda.scrivi(voci) }
            if let nota {
                self.notaTelefono.esito(ultima, inCoda: voci.contains { $0.id == nota })
            }
        }
    }

    /// Una consegna alla volta.
    nonisolated(unsafe) static var consegnaNoteInCorso = false
}

extension StatoMobile {
    /// L'azione rapida «Nota veloce» (o il pulsante): Incontri e la schermata della nota.
    func apriNotaVeloce() {
        apri(.incontri)
        stato.notaVeloceAperta = true
    }
}
#endif
