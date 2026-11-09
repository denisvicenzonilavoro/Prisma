#if os(macOS)
import AppKit
#endif
import SwiftUI

// Impostazioni › iPhone e iPad, «Prisma ovunque» (Design/template-novita-specifica.md §13, template
// `ovunqueHTML()`/`montaOvunque()`; prova di fattibilità Design/ovunque-fattibilita.md). La stessa pagina sul Mac,
// sull'iPad (nelle Impostazioni del tema Apple) e sull'iPhone (`compatta`, in ImpostazioniTelefono).
//
//   iPhone e iPad
//   ┌─ card 720 ─────────────────────────────────────────────┐   ┌─ telefono d'esempio ─┐
//   │  [Mac] · ─ ● ─ ·  [☁︎🔒]  · ─ ● ─ ·  [iPhone]             │   │ 10:41  Senza Mac ·…  │
//   │  Sincronizzato · 2 minuti fa            [Sincronizza ora]│   │ Giulia Rossi         │
//   │  Cifrato con la tua chiave: senza, …                     │   │ Patrimonio netto …   │
//   └──────────────────────────────────────────────────────────┘   └──────────────────────┘
//   [modulo: cartella, passphrase, conferma, avviso]  (solo mentre si accende o si riapre)
//   Copia cifrata su iPhone e iPad ……………………… (●  )
//   Lavora anche con il Mac spento ………………… (●  )
//   Modifiche in attesa · 3 dall’iPhone di stamattina … [Vedi]
//   [Da decidere: le due versioni affiancate e la scelta · In arrivo · Arrivate di recente]
//   Cartella · Passphrase (a copia accesa)
//
// - Spenta finché l'utente non la accende: l'interruttore apre il modulo con la cartella e la passphrase (con
//   conferma e l'avviso che senza non si legge). Spegnendo, Prisma chiede conferma e cancella la copia da iCloud Drive.
// - Movimento: la cascata dei blocchi (base 0, con la sfocatura), i pallini dello schema, il rimbalzo del lucchetto.
//   «Riduci movimento» e istantanee: tutto fermo nello stato finale (pallini fermi, nessuna cascata).
// - Il telefono d'esempio (solo sul Mac) mostra il cliente dell'ultima modifica arrivata con il suo patrimonio netto
//   e due aree di Analisi 360 calcolati dai motori; senza clienti, i dati di prova dichiarati.
// Valori in DesignSystem/Apple/Tema.Apple+Ovunque.swift, testi in Motori/TestiOvunque.swift.

struct PaginaImpostazioniOvunque: View {
    @Environment(StatoShell.self) var stato
    /// iPhone: senza telefono d'esempio, in una colonna sola.
    var compatta = false

    init(compatta: Bool = false) {
        self.compatta = compatta
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoImpostazioniOvunque(ovunque: stato.ovunque, compatta: compatta)
            .impostazioniApple()
    }
}

private struct CorpoImpostazioniOvunque: View {
    @Environment(StatoShell.self) var stato
    @Bindable var ovunque: StatoOvunque
    let compatta: Bool

    @State private var confermaSpegni = false
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias P = Tema.Apple.Ovunque.Pagina
    private typealias C = Tema.Apple.Ovunque.Card

    private var o: ImpostazioniOvunque { stato.dati.impostazioni.ovunque }
    private var suMac: Bool { StatoOvunque.ruoloApparecchio == .mac }
    private var vista: StatoVistaOvunque { stato.statoVistaOvunque }
    private var base: Double { Tema.Apple.Moto.Cascata.baseDentroApp }

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(alignment: .top, spacing: P.spazioTelefono) {
            colonna
                .frame(maxWidth: compatta ? .infinity : P.colonna, alignment: .leading)
            if !compatta && suMac {
                TelefonoEsempioOvunque(esempio: stato.esempioTelefonoOvunque)
                    .entrataCascata(5, base: base)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("Spegnere la copia per iPhone e iPad?", isPresented: $confermaSpegni) {
            Button("Annulla", role: .cancel) {}
            Button("Spegni", role: .destructive) { stato.spegniOvunque() }
        } message: {
            Text(suMac ? TestiOvunque.confermaSpegniMac : TestiOvunque.confermaSpegniDispositivo)
        }
        #if os(iOS)
        .sceltaCartellaOvunque($ovunque.sceltaCartella) { esito in stato.cartellaSceltaOvunque(esito) }
        #endif
        .onAppear { stato.controllaOvunque() }
    }

    // MARK: Colonna

    private var colonna: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardSchema
                .padding(.bottom, P.sottoCard)
                .entrataCascata(1, base: base)
            if let m = ovunque.modulo {
                ModuloOvunqueVista(tipo: m, ovunque: ovunque, compatta: compatta)
                    .padding(.bottom, P.sottoCard)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            VStack(alignment: .leading, spacing: P.fraRighe) {
                rigaCopia
                    .entrataCascata(2, base: base)
                rigaModificheDaiDispositivi
                    .entrataCascata(3, base: base)
                rigaPotenziali
                    .entrataCascata(3, base: base)
                rigaInAttesa
                    .entrataCascata(4, base: base)
                if ovunque.modificheAperte {
                    PannelloModificheOvunque(ovunque: ovunque)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                if o.acceso {
                    rigaCartella
                        .entrataCascata(6, base: base)
                    if suMac {
                        rigaPassphrase
                            .entrataCascata(7, base: base)
                    }
                }
            }
            NotaImpostazioni(suMac
                ? "In iCloud Drive c’è solo un file cifrato con la tua passphrase: nessun server, nessun contenitore di Prisma in iCloud. Documenti, conversazioni con Vera e trascrizioni restano sul Mac."
                : "La copia arriva dal Mac in un file cifrato. Le modifiche di qui tornano al Mac nel giornale cifrato di questo dispositivo.")
                .padding(.top, P.fraRighe)
                .entrataCascata(8, base: base)
        }
        .animation(Tema.Apple.Moto.animazione(Tema.Apple.Ovunque.Moto.apertura, calmo: calmo, istantanea: istantanea),
                   value: ovunque.modulo)
        .animation(Tema.Apple.Moto.animazione(Tema.Apple.Ovunque.Moto.apertura, calmo: calmo, istantanea: istantanea),
                   value: ovunque.modificheAperte)
    }

    // MARK: Card dello schema

    private var aspettoSchema: AspettoSchemaOvunque {
        let v = vista
        return AspettoSchemaOvunque(attivo: v.attivo, veloce: v == .inCorso, spento: v.spento,
                                    nuvolaSpenta: v == .iCloud, rimbalzo: ovunque.giri)
    }

    private var cardSchema: some View {
        let v = vista
        return VStack(alignment: .leading, spacing: 0) {
            SchemaConPausaOvunque(sistema: stato.sistema, aspetto: aspettoSchema)
            HStack(alignment: .center, spacing: C.spazioStato) {
                VStack(alignment: .leading, spacing: C.sottoTitolo) {
                    TimelineView(.everyMinute) { contesto in
                        Text(TestiOvunque.titolo(v, adesso: contesto.date))
                            .carattereApple(C.titolo)
                            .foregroundColor(C.coloreTitolo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(TestiOvunque.frase(v, mac: suMac))
                        .carattereApple(C.frase)
                        .foregroundColor(isErrore(v) ? C.coloreErrore : C.coloreFrase)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(Tema.Apple.Moto.animazione(Tema.Apple.Ovunque.Moto.testo, calmo: calmo, istantanea: istantanea),
                           value: v)
                pulsanteStato(v)
            }
            .padding(.top, C.sopraStato)
        }
        .padding(C.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(C.superficie, raggio: C.raggio)
    }

    private func isErrore(_ v: StatoVistaOvunque) -> Bool {
        if case .errore = v { return true }
        return false
    }

    /// Il pulsante della card per ogni stato (nascosto con la copia spenta).
    @ViewBuilder private func pulsanteStato(_ v: StatoVistaOvunque) -> some View {
        switch v {
        case .spenta:
            EmptyView()
        case .passphrase:
            principale("Scrivi la passphrase…") { apriModulo(.passphrase) }
        case .cartella:
            principale("Scegli la cartella…") { apriModulo(.accendi) }
        case .iCloud, .errore:
            principale("Riprova") { riprova() }
        case .maiFatta(let mac):
            principale(mac ? "Crea la copia" : "Controlla ora") { stato.sincronizzaOvunque(forza: mac) }
        case .inCorso:
            principale("Sincronizza ora") {}
                .disabled(true)
        case .attesaICloud, .conflitti, .riuscita:
            principale("Sincronizza ora") { stato.sincronizzaOvunque(forza: false) }
        }
    }

    private func principale(_ titolo: String, _ azione: @escaping () -> Void) -> some View {
        Button(titolo, action: azione)
            .buttonStyle(StilePulsanteApple(.principale, grande: true))
            .fixedSize()
    }

    private func apriModulo(_ m: ModuloOvunque) {
        ovunque.erroreModulo = nil
        if m == .accendi, ovunque.cartellaScelta == nil { ovunque.cartellaScelta = stato.cartellaPropostaOvunque }
        ovunque.modulo = m
    }

    private func riprova() {
        ovunque.problema = nil
        ovunque.cartella = nil
        if ovunque.chiave == nil {
            stato.apriSpazioOvunque(sincronizza: true)
        } else {
            stato.sincronizzaOvunque()
        }
    }

    // MARK: Righe

    private var rigaCopia: some View {
        let acceso = Binding<Bool>(
            get: { o.acceso || ovunque.modulo == .accendi },
            set: { nuovo in
                if nuovo {
                    stato.chiediAccensioneOvunque()
                } else if o.acceso {
                    confermaSpegni = true
                } else {
                    ovunque.modulo = nil
                }
            })
        return RigaImpostazione(titolo: "Copia cifrata su iPhone e iPad",
                                sottotitolo: suMac ? "I dati viaggiano solo come file cifrato in iCloud Drive."
                                                   : "Questo dispositivo legge la copia cifrata che il Mac scrive in iCloud Drive.") {
            Toggle(isOn: acceso) { EmptyView() }
                .toggleStyle(.appleSenzaEtichetta)
                .accessibilityLabel("Copia cifrata su iPhone e iPad")
                .disabled(ovunque.inCorso)
        }
    }

    @ViewBuilder private var rigaModificheDaiDispositivi: some View {
        if suMac {
            let ammesse = Binding<Bool>(get: { o.modificheDaiDispositivi },
                                        set: { stato.impostaModificheDaiDispositiviOvunque($0) })
            RigaImpostazione(titolo: "Lavora anche con il Mac spento",
                             sottotitolo: o.modificheDaiDispositivi
                                ? "Dal cliente, in treno, ovunque: al ritorno le modifiche si uniscono da sole."
                                : "Spento: su iPhone e iPad la copia è di sola lettura.") {
                Toggle(isOn: ammesse) { EmptyView() }
                    .toggleStyle(.appleSenzaEtichetta)
                    .accessibilityLabel("Lavora anche con il Mac spento")
            }
        } else {
            RigaImpostazione(titolo: "Lavora anche con il Mac spento",
                             sottotitolo: o.modificheDaiDispositivi
                                ? "Note, attività, appuntamenti e dati raccolti qui si uniscono al Mac quando legge la cartella."
                                : "Copia di sola lettura: lo ha scelto il Mac. Le modifiche fatte qui non arrivano al Mac.") {
                StatoRigaApple(testo: o.modificheDaiDispositivi ? "Ammesse" : "Sola lettura",
                               tono: o.modificheDaiDispositivi ? .ok : .neutro)
            }
        }
    }

    /// «Luce» giro 12 (decisione 44): i potenziali clienti nello spazio solo se l'utente lo sceglie (spento di base).
    @ViewBuilder private var rigaPotenziali: some View {
        if suMac {
            let si = Binding<Bool>(get: { o.potenzialiNelloSpazio },
                                   set: { stato.impostaPotenzialiOvunque($0) })
            RigaImpostazione(titolo: "Porta anche i potenziali clienti",
                             sottotitolo: o.potenzialiNelloSpazio
                                ? "I potenziali clienti (persone che non sono ancora clienti) vanno su iPhone e iPad, cifrati."
                                : "Spento: i potenziali clienti restano sul Mac.") {
                Toggle(isOn: si) { EmptyView() }
                    .toggleStyle(.appleSenzaEtichetta)
                    .accessibilityLabel("Porta anche i potenziali clienti")
            }
        }
    }

    private var rigaInAttesa: some View {
        let attesa = stato.modificheInAttesaOvunque
        let conflitti = suMac ? stato.dati.conflittiOvunque.count : 0
        let testo: String
        if suMac {
            if let t = TestiOvunque.inAttesa(attesa, nomi: ovunque.nomiDispositivi) {
                testo = t
            } else if conflitti > 0 {
                testo = conflitti == 1 ? "1 da decidere: lo stesso dato è cambiato in due posti."
                                       : "\(conflitti) da decidere: lo stesso dato è cambiato in due posti."
            } else {
                testo = TestiOvunque.nessunaInAttesa
            }
        } else {
            testo = attesa.isEmpty ? TestiOvunque.nessunaInAttesa : TestiOvunque.daUnire(attesa)
        }
        let pillola: Pillola? = conflitti > 0 ? Pillola(testo: conflitti == 1 ? "1 da decidere" : "\(conflitti) da decidere",
                                                        tono: .attenzione) : nil
        return RigaImpostazione(titolo: "Modifiche in attesa", sottotitolo: testo, stato: pillola) {
            if !attesa.isEmpty || conflitti > 0 {
                ValoreRiga(testo: ovunque.modificheAperte ? "Nascondi" : "Vedi") {
                    ovunque.modificheAperte.toggle()
                }
            }
        }
    }

    private var rigaCartella: some View {
        // Sul dispositivo anche l'ora della copia del Mac letta per ultima
        var testo = TestiOvunque.percorso(o.percorso)
        if !suMac, let u = o.ultimaIstantanea { testo += " · copia del Mac " + TestiOvunque.quando(u) }
        return RigaImpostazione(titolo: "Cartella", sottotitolo: testo) {
            #if os(macOS)
            ValoreRiga(testo: "Mostra nel Finder") {
                if let p = o.percorso { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: p, isDirectory: true)]) }
            }
            #else
            EmptyView()
            #endif
        }
    }

    private var rigaPassphrase: some View {
        RigaImpostazione(titolo: "Passphrase",
                         sottotitolo: "Solo tua: Prisma non la conserva. Su questo Mac la chiave sta nel Portachiavi.") {
            ValoreRiga(testo: "Cambia…") { apriModulo(.cambia) }
                .disabled(ovunque.inCorso || ovunque.chiave == nil)
        }
    }
}

/// Lo schema con i pallini in pausa quando la finestra non si vede (Prisma bloccato, Impostazioni coperte da una
/// finestra ingrandita). Solo questa vista osserva le finestre: la pagina non si ridisegna quando si spostano.
private struct SchemaConPausaOvunque: View {
    let sistema: StatoFinestre
    let aspetto: AspettoSchemaOvunque

    var body: some View {
        var a = aspetto
        a.inPausa = sistema.bloccato || sistema.coperte.contains(.impostazioni)
        return SchemaOvunqueApple(aspetto: a)
    }
}

// MARK: - Modulo: cartella e passphrase

/// Il modulo in linea sotto la card: accendere (cartella, passphrase e conferma sul Mac; cartella e passphrase su
/// iPhone e iPad), riaprire con la passphrase, cambiarla (Mac). La passphrase vive solo nei campi: dopo il pulsante si
/// cancella, la chiave va nel Portachiavi.
private struct ModuloOvunqueVista: View {
    let tipo: ModuloOvunque
    @Bindable var ovunque: StatoOvunque
    let compatta: Bool

    @Environment(StatoShell.self) var stato
    @State private var passphrase = ""
    @State private var conferma = ""

    private typealias M = Tema.Apple.Ovunque.Modulo

    private var suMac: Bool { StatoOvunque.ruoloApparecchio == .mac }
    /// Una passphrase nuova (si scrive due volte): creare lo spazio sul Mac o cambiarla.
    private var nuova: Bool { tipo == .cambia || (tipo == .accendi && suMac) }

    private var titolo: String {
        switch tipo {
        case .accendi: return suMac ? "Crea la copia cifrata" : "Apri la copia del Mac"
        case .passphrase: return "Scrivi la passphrase"
        case .cambia: return "Cambia la passphrase"
        }
    }

    private var spiegazione: String {
        switch tipo {
        case .accendi:
            return suMac
                ? "Scegli la cartella in iCloud Drive e una passphrase: solo con lei la copia si apre, sul Mac, sull’iPhone e sull’iPad."
                : "Scegli in File la cartella di Prisma ovunque creata dal Mac (iCloud Drive › Prisma ovunque) e scrivi la sua passphrase. I dati di questo dispositivo vengono sostituiti dalla copia del Mac."
        case .passphrase:
            return "La passphrase con cui hai creato la copia sul Mac. Se l’hai cambiata sul Mac, scrivi quella nuova."
        case .cambia:
            return "Prima Prisma unisce le modifiche arrivate, poi riscrive la copia con la passphrase nuova: iPhone e iPad te la chiederanno."
        }
    }

    private var pulsante: String {
        switch tipo {
        case .accendi: return suMac ? "Crea la copia" : "Apri la copia"
        case .passphrase: return "Apri"
        case .cambia: return "Cambia passphrase"
        }
    }

    /// Perché il pulsante non si può ancora premere (nil = si può).
    private var ostacolo: String? {
        if tipo == .accendi, ovunque.cartellaScelta == nil { return "Scegli prima la cartella." }
        if passphrase.count < ErroreOvunque.lunghezzaMinimaPassphrase {
            return "Almeno \(ErroreOvunque.lunghezzaMinimaPassphrase) caratteri."
        }
        if nuova, conferma != passphrase { return "Scrivi la stessa passphrase nei due campi." }
        return nil
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: M.spazio) {
            VStack(alignment: .leading, spacing: Tema.Apple.Ovunque.Card.sottoTitolo) {
                Text(titolo)
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
                Text(spiegazione)
                    .carattereApple(M.testo)
                    .foregroundColor(M.coloreTesto)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if tipo == .accendi { cartella }
            campo("Passphrase", testo: $passphrase)
            if nuova { campo("Ripeti la passphrase", testo: $conferma) }
            if nuova {
                Text(TestiOvunque.avvisoPassphrase)
                    .carattereApple(M.testoAvviso)
                    .foregroundColor(M.coloreAvviso)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(M.paddingAvviso)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: M.raggioAvviso, style: .continuous)
                            .fill(M.fondoAvviso)
                            .overlay(RoundedRectangle(cornerRadius: M.raggioAvviso, style: .continuous)
                                .strokeBorder(M.bordoAvviso, lineWidth: Tema.Apple.Misura.bordo))
                    )
            }
            if let e = ovunque.erroreModulo {
                Text(e)
                    .carattereApple(M.testo)
                    .foregroundColor(M.coloreErrore)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let ostacolo, !passphrase.isEmpty {
                Text(ostacolo)
                    .carattereApple(M.testo)
                    .foregroundColor(M.coloreTesto)
            }
            HStack(spacing: M.spazio) {
                Spacer(minLength: 0)
                Button("Annulla") {
                    passphrase = ""
                    conferma = ""
                    ovunque.erroreModulo = nil
                    ovunque.modulo = nil
                }
                .buttonStyle(.apple)
                .disabled(ovunque.inCorso)
                Button(ovunque.inCorso ? "Un momento…" : pulsante, action: azione(tipo))
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                    .disabled(ostacolo != nil || ovunque.inCorso)
            }
        }
        .padding(M.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.superficie, raggio: M.raggio)
    }

    private var cartella: some View {
        HStack(spacing: M.spazio) {
            Image(systemName: "folder")
                .foregroundColor(M.colorePercorso)
            Text(TestiOvunque.percorso(ovunque.cartellaScelta?.path))
                .carattereApple(M.percorso)
                .foregroundColor(M.colorePercorso)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button("Scegli…") {
                #if os(macOS)
                stato.scegliCartellaOvunque()
                #else
                ovunque.sceltaCartella = true
                #endif
            }
            .buttonStyle(.apple)
            .disabled(ovunque.inCorso)
        }
    }

    private func campo(_ etichetta: String, testo: Binding<String>) -> some View {
        SecureField(etichetta, text: testo)
            .textFieldStyle(.plain)
            .font(M.campo.font)
            .padding(.horizontal, M.paddingCampo)
            .frame(height: altezzaCampo)
            .background(RoundedRectangle(cornerRadius: M.raggioCampo, style: .continuous).fill(M.fondoCampo))
            .disabled(ovunque.inCorso)
            .onSubmit { if ostacolo == nil { azione(tipo)() } }
    }

    /// Sul tocco (iPhone e iPad) i campi sono alti 44, sul Mac 34.
    private var altezzaCampo: CGFloat {
        #if os(iOS)
        return M.altezzaCampoTocco
        #else
        return M.altezzaCampo
        #endif
    }

    /// L'azione del pulsante: la passphrase esce dai campi subito.
    private func azione(_ t: ModuloOvunque) -> () -> Void {
        return {
            guard ostacolo == nil else { return }
            let scritta = passphrase
            passphrase = ""
            conferma = ""
            switch t {
            case .accendi:
                guard let url = ovunque.cartellaScelta else { return }
                stato.accendiOvunque(cartella: url, passphrase: scritta)
            case .passphrase:
                stato.sbloccaOvunque(passphrase: scritta)
            case .cambia:
                stato.cambiaPassphraseOvunque(nuova: scritta)
            }
        }
    }
}

// MARK: - Modifiche in attesa e «Da decidere»

/// «Vedi»: sopra i conflitti con le due versioni affiancate e la scelta, poi le modifiche ancora in attesa raggruppate
/// per dispositivo e ora («iPhone · stamattina alle 09:12 · Nota nuova per Giulia Rossi») con «Unisci ora», poi (sul
/// Mac) le cose arrivate di recente.
private struct PannelloModificheOvunque: View {
    @Bindable var ovunque: StatoOvunque
    @Environment(StatoShell.self) var stato

    private typealias M = Tema.Apple.Ovunque.Modifiche

    private var suMac: Bool { StatoOvunque.ruoloApparecchio == .mac }

    private struct Gruppo: Identifiable {
        let id: String
        let titolo: String
        var operazioni: [OperazioneOvunque]
    }

    /// Le operazioni per dispositivo e minuto, nell'ordine in cui sono arrivate.
    private var gruppi: [Gruppo] {
        var r: [Gruppo] = []
        for op in stato.modificheInAttesaOvunque {
            let minuto = Int(op.data.timeIntervalSinceReferenceDate / 60)
            let chiave = "\(op.dispositivo)-\(minuto)"
            if let i = r.firstIndex(where: { $0.id == chiave }) {
                r[i].operazioni.append(op)
            } else {
                r.append(Gruppo(id: chiave, titolo: TestiOvunque.gruppo(nome: stato.nomeDispositivoOvunque(op.dispositivo), data: op.data),
                                operazioni: [op]))
            }
        }
        return r
    }

    var body: some View {
        let conflitti = suMac ? stato.dati.conflittiOvunque : []
        let arrivi = suMac ? Array(stato.dati.arriviOvunque.suffix(M.massimoArrivi).reversed()) : []
        let elenco = gruppi
        VStack(alignment: .leading, spacing: M.spazio) {
            if !conflitti.isEmpty {
                sezione("Da decidere")
                ForEach(conflitti) { c in ConflittoOvunqueVista(conflitto: c) }
            }
            if !elenco.isEmpty {
                sezione(suMac ? "In arrivo" : "Da unire al Mac")
                ForEach(elenco) { g in
                    VStack(alignment: .leading, spacing: M.fraVoci) {
                        Text(g.titolo)
                            .carattereApple(M.gruppo)
                            .foregroundColor(M.coloreGruppo)
                        ForEach(g.operazioni) { op in voce(descrizione(op), colore: M.colorePallino) }
                    }
                }
                if suMac {
                    Button("Unisci ora") { stato.sincronizzaOvunque() }
                        .buttonStyle(StilePulsanteApple(.principale))
                        .disabled(ovunque.inCorso)
                }
            }
            if !arrivi.isEmpty {
                sezione("Arrivate di recente")
                VStack(alignment: .leading, spacing: M.fraVoci) {
                    ForEach(Array(arrivi.enumerated()), id: \.offset) { _, a in
                        voce(descrizione(a), colore: M.colorePallino)
                    }
                }
            }
        }
        .padding(M.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.superficie, raggio: M.raggio)
    }

    private func sezione(_ t: String) -> some View {
        Text(t)
            .carattereApple(M.sezione)
            .foregroundColor(M.coloreSezione)
    }

    private func voce(_ t: String, colore: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: M.spazioPallino) {
            Circle()
                .fill(colore)
                .frame(width: M.pallino, height: M.pallino)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + M.pallino }
            Text(t)
                .carattereApple(M.voce)
                .foregroundColor(M.coloreVoce)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func descrizione(_ op: OperazioneOvunque) -> String {
        let base = TestiOvunque.operazione(op)
        guard let c = stato.clienteOperazioneOvunque(op) else { return base }
        return "\(base) per \(c.nome)"
    }

    private func descrizione(_ a: ArrivoOvunque) -> String {
        let (nome, femminile) = TestiOvunque.nomeEntita(a.entita)
        var t = "\(nome) \(femminile ? "nuova" : "nuovo")"
        if let id = stato.clienteIdOvunque(a.entita, id: a.entitaId), let c = stato.dati.clienti.first(where: { $0.id == id }) {
            t += " per \(c.nome)"
        }
        return t + " · " + TestiOvunque.gruppo(nome: a.nomeDispositivo, data: a.il)
    }
}

/// Un conflitto: da dove arriva, perché, le due versioni affiancate e la scelta. Finché non si sceglie vale il Mac.
private struct ConflittoOvunqueVista: View {
    let conflitto: ConflittoOvunque
    @Environment(StatoShell.self) var stato

    private typealias M = Tema.Apple.Ovunque.Modifiche

    var body: some View {
        let _ = ContaCorpi.segna()
        let op = conflitto.operazione
        let nome = conflitto.nomeDispositivo
        let cliente = stato.clienteOperazioneOvunque(op).map { " per \($0.nome)" } ?? ""
        VStack(alignment: .leading, spacing: M.fraVoci) {
            Text(TestiOvunque.gruppo(nome: nome, data: op.data) + " · " + TestiOvunque.operazione(op) + cliente)
                .carattereApple(M.gruppo)
                .foregroundColor(M.coloreGruppo)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiOvunque.motivo(conflitto.motivo, dispositivo: nome))
                .carattereApple(M.motivo)
                .foregroundColor(M.coloreMotivo)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: M.spazioVersioni) {
                versione("Sul Mac", valoreMac)
                versione(TestiOvunque.maiuscola(TestiOvunque.sul(nome)), valoreDispositivo)
            }
            HStack(spacing: M.spazioVersioni) {
                Button("Tieni quella del Mac") { stato.decidiOvunque(conflitto.id, scelta: .tieniMac) }
                    .buttonStyle(.apple)
                Button("Tieni quella \(TestiOvunque.di(nome))") { stato.decidiOvunque(conflitto.id, scelta: .tieniDispositivo) }
                    .buttonStyle(.apple)
                    .disabled(conflitto.motivo == .clienteMancante)
            }
        }
        .padding(M.paddingConflitto)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: M.raggioConflitto, style: .continuous)
                .fill(M.fondoConflitto)
                .overlay(RoundedRectangle(cornerRadius: M.raggioConflitto, style: .continuous)
                    .strokeBorder(M.bordoConflitto, lineWidth: Tema.Apple.Misura.bordo))
        )
    }

    private var valoreMac: String {
        let op = conflitto.operazione
        switch conflitto.motivo {
        case .stessoCampo: return TestiOvunque.leggibile(conflitto.valoreMac, campo: op.campo)
        case .eliminataSulMac: return "Non c’è più"
        case .eliminataSulDispositivo: return TestiOvunque.leggibile(conflitto.valoreMac, campo: nil)
        case .clienteMancante: return "Il cliente non c’è più"
        }
    }

    private var valoreDispositivo: String {
        let op = conflitto.operazione
        switch op.tipo {
        case .elimina: return "Eliminata"
        case .crea: return TestiOvunque.leggibile(op.dopo, campo: nil)
        case .modificaCampo: return TestiOvunque.leggibile(op.dopo, campo: op.campo)
        }
    }

    private func versione(_ etichetta: String, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: Tema.Apple.Ovunque.Card.sottoTitolo) {
            Text(etichetta)
                .carattereApple(M.etichettaVersione)
                .foregroundColor(M.coloreEtichettaVersione)
                .lineLimit(1)
            Text(valore)
                .carattereApple(M.valoreVersione)
                .foregroundColor(M.coloreValoreVersione)
                .lineLimit(M.righeValore)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(M.paddingVersione)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: M.raggioVersione, style: .continuous).fill(M.fondoVersione))
    }
}

// MARK: - Il telefono d'esempio

extension StatoShell {
    /// Il cliente dell'ultima modifica arrivata (o in arrivo), il suo patrimonio netto e due aree di Analisi 360 dai
    /// motori, la nota nuova e quante modifiche si uniranno al Mac. Senza clienti: i dati di prova, dichiarati.
    var esempioTelefonoOvunque: EsempioTelefonoOvunque {
        let attesa = modificheInAttesaOvunque
        let piede = TestiOvunque.piedeTelefono(attesa.count)
        let daOperazione = attesa.reversed().lazy.compactMap { self.clienteOperazioneOvunque($0) }.first
        let daArrivo = dati.arriviOvunque.reversed().lazy.compactMap { a -> Cliente? in
            guard let id = self.clienteIdOvunque(a.entita, id: a.entitaId) else { return nil }
            return self.dati.clienti.first { $0.id == id }
        }.first
        guard let cliente = daOperazione ?? daArrivo ?? dati.clienti.first(where: { $0.id == clienteAttivoId }) ?? dati.clienti.first else {
            return EsempioTelefonoOvunque(nome: "Cliente di prova", sottotitolo: "dati di prova", patrimonio: "—", aree: [],
                                          titoloNota: "Nota nuova", nota: nil, piede: piede)
        }
        let patrimonio = Formati.euro(riepilogoPosizioniCliente(cliente.id).patrimonioNetto)
        let aree = aree360(cliente.id)
        let scelte: [AreaAnalisi] = [.investimenti, .protezione]
        let valori = scelte.compactMap { a -> EsempioTelefonoOvunque.Area? in
            guard let s = aree.sintesi(a), let v = s.valore else { return nil }
            let testo = s.unita == .percentuale ? "\(Int(v.rounded()))%" : "\(Formati.numeroFormatter.string(from: NSNumber(value: v)) ?? "\(v)") mesi"
            return EsempioTelefonoOvunque.Area(nome: a.nome, valore: testo)
        }
        // La nota nuova in arrivo per il cliente, altrimenti la sua nota più recente
        let notaNuova = attesa.reversed().first { $0.entita == .nota && $0.tipo == .crea && self.clienteOperazioneOvunque($0)?.id == cliente.id }
            .flatMap { JSONOvunque.oggetto($0.dopo) }
        let ultima = dati.note.filter { $0.clienteId == cliente.id }.max { $0.aggiornataIl < $1.aggiornataIl }
        let testoNota = (notaNuova?["testo"] as? String) ?? (notaNuova?["titolo"] as? String) ?? ultima.map { $0.testo.isEmpty ? $0.titolo : $0.testo }
        let luogo = dati.appuntamenti.filter { $0.clienteId == cliente.id && !$0.luogo.isEmpty }
            .min { abs($0.inizio.timeIntervalSinceNow) < abs($1.inizio.timeIntervalSinceNow) }?.luogo
        return EsempioTelefonoOvunque(nome: cliente.nome, sottotitolo: luogo.map { "Dal cliente · \($0)" }, patrimonio: patrimonio,
                                      aree: valori, titoloNota: notaNuova != nil ? "Nota nuova" : "Ultima nota",
                                      nota: testoNota.map { String($0.prefix(140)) }, piede: piede)
    }
}
