import Observation
import SwiftUI

// La nota vocale sul Mac (Design/template-luce-specifica.md §6.2.1 §1.4, «Luce» giro 13):
// - la scheda «Arriva sul Mac» (larga 470, in alto a destra sotto la barra, come le notifiche; non un velo): il cliente
//   riconosciuto (o «Di chi si parla?»), il testo dettato e le quattro voci proposte, ciascuna con «Conferma» e
//   «Scarta», più «Conferma tutto»; ✕ ed Esc la chiudono (la nota resta in Incontri › Oggi «da decidere»);
// - «Come funziona» (dal pulsante «Nota dall’iPhone» di Incontri e dal pannello Novità): la scena dimostrativa con il
//   telefono disegnato in ascolto (dati di prova del template) e la scheda «Aspetto la nota…» con le ultime note;
// - la voce «Nota dall’iPhone · 11:42» nella colonna «Oggi» di Incontri.

/// Lo stato della scheda in memoria (non si salva: le note stanno in `dati.noteInArrivo`).
@Observable final class StatoNotaVocaleMac {
    /// La nota mostrata nella scheda «Arriva sul Mac» (nil = nessuna).
    var mostrata: String?
    /// La voce in modifica (id della proposta).
    var inModifica: String?
}

/// La voce «Nota dall’iPhone · 11:42» nella colonna «Oggi» di Incontri, con il pallino delle note da guardare.
struct VoceOggiNotaVocale: View {
    @Environment(StatoShell.self) var stato
    let nota: NotaInArrivo

    private typealias C = Tema.Apple.Copilota.Colonna
    private typealias O = Tema.Apple.NotaVocale.Oggi

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: C.raggioVoce, style: .continuous)
        let cliente = nota.clienteId.flatMap { stato.cliente($0) }
        return Button { stato.mostraNotaVocale(nota.id) } label: {
            HStack(spacing: C.spazioAvatar) {
                if let c = cliente {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: C.avatar)
                } else {
                    GlifoLuceVista(glifo: .voce, lato: O.glifo, colore: O.coloreGlifo)
                        .frame(width: C.avatar, height: C.avatar)
                }
                VStack(alignment: .leading, spacing: C.spazioTitoli) {
                    Text("Nota dall’iPhone · \(Formati.ora.string(from: nota.quando))")
                        .carattereApple(C.nome)
                        .foregroundColor(C.coloreNome)
                        .lineLimit(1)
                    Text(cliente?.nome ?? "Di chi si parla?")
                        .carattereApple(C.sottotitolo)
                        .foregroundColor(C.coloreSottotitolo)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if nota.stato == .daGuardare {
                    Circle().fill(O.colorePallino).frame(width: O.pallino, height: O.pallino)
                }
            }
            .padding(C.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(forma.fill(C.fondoSopra))
        }
        .buttonStyle(StileSemplice())
        .accessibilityLabel(Text("Nota dall’iPhone delle \(Formati.ora.string(from: nota.quando)), \(cliente?.nome ?? "cliente da scegliere")"))
    }
}

#if os(macOS)

// MARK: - La scheda «Arriva sul Mac»

/// Lo strato della scheda: in alto a destra, sotto la barra; vuoto quando non c'è una nota da mostrare.
struct StratoNotaVocaleArrivo: View {
    @Environment(StatoShell.self) var stato
    let notaVocale: StatoNotaVocaleMac
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    private typealias S = Tema.Apple.NotaVocale.Scheda

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let id = notaVocale.mostrata, !stato.inModoCliente, !stato.bloccato,
               let n = stato.dati.noteInArrivo.first(where: { $0.id == id }) {
                SchedaNotaVocaleArrivo(nota: n, notaVocale: notaVocale)
                    .padding(.top, S.sottoBarra)
                    .padding(.trailing, S.margineDestro)
                    .transition(transizione)
                // Esc chiude la scheda, solo se non c'è una sovrapposizione aperta (due Esc si contenderebbero il tasto)
                if stato.sovrapposizione == nil, notaVocale.inModifica == nil {
                    Button("Chiudi la nota dall’iPhone") { notaVocale.mostrata = nil }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(StileSemplice())
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                }
            }
        }
        .animation(istantanea ? nil : (calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.NotaVocale.scheda), value: notaVocale.mostrata)
    }

    private var transizione: AnyTransition {
        guard !istantanea else { return .identity }
        if calmo { return .opacity }
        let m = Tema.Apple.Moto.NotaVocale.self
        return .opacity.combined(with: .offset(y: m.spostamentoScheda)).combined(with: .scale(scale: m.scalaScheda, anchor: .topTrailing))
    }
}

/// La scheda «Arriva sul Mac»: testata, cliente, testo dettato, voci proposte, «Conferma tutto».
struct SchedaNotaVocaleArrivo: View {
    @Environment(StatoShell.self) var stato
    let nota: NotaInArrivo
    let notaVocale: StatoNotaVocaleMac

    private typealias S = Tema.Apple.NotaVocale.Scheda
    private typealias L = Tema.Apple.NotaVocale.Cliente

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 0) {
            testa
            cliente
                .padding(.top, L.sopra)
                .padding(.bottom, L.sotto)
                .overlay(alignment: .bottom) { Rectangle().fill(L.filo).frame(height: Tema.Apple.Misura.bordo) }
            Text("«\(nota.testo)»")
                .carattereApple(S.testo)
                .foregroundColor(S.coloreTesto)
                .lineLimit(S.righeTesto)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, L.sotto)
            ForEach(Array(nota.proposte.enumerated()), id: \.element.id) { i, p in
                VoceNotaVocale(nota: nota, proposta: p, indice: i, notaVocale: notaVocale)
            }
            piede
        }
        .padding(S.padding)
        .frame(width: S.larghezza, alignment: .leading)
        .superficieApple(S.superficie)
    }

    private var testa: some View {
        HStack(spacing: S.spazioTesta) {
            SferaVera(misura: S.sfera, viva: true, pensa: false)
            Text("Arriva sul Mac")
                .carattereApple(S.etichetta)
                .foregroundColor(S.coloreEtichetta)
            Spacer(minLength: 0)
            Button { notaVocale.mostrata = nil } label: { Image(systemName: "xmark") }
                .buttonStyle(.apple)
                .help("Chiudi (Esc): la nota resta in Incontri › Oggi, da decidere")
                .accessibilityLabel(Text("Chiudi"))
        }
    }

    @ViewBuilder private var cliente: some View {
        if let id = nota.clienteId, let c = stato.cliente(id) {
            HStack(spacing: L.spazio) {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: L.avatar)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Prisma ha capito che si parla di")
                        .carattereApple(L.didascalia)
                        .foregroundColor(L.coloreDidascalia)
                    Button { apriDossier(c.id) } label: {
                        Text(c.nome)
                            .carattereApple(L.nome)
                            .foregroundColor(L.coloreNome)
                    }
                    .buttonStyle(StileSemplice())
                    .help("Apri il dossier di \(c.nome)")
                }
                Spacer(minLength: 0)
                sceltaCliente(titolo: "Cambia")
            }
        } else {
            VStack(alignment: .leading, spacing: L.spazioCandidati) {
                Text(nota.candidati.isEmpty ? "Non ho capito di chi si parla" : "Di chi si parla?")
                    .carattereApple(L.nome)
                    .foregroundColor(L.coloreNome)
                HStack(spacing: L.spazioCandidati) {
                    ForEach(nota.candidati, id: \.self) { id in
                        if let c = stato.cliente(id) {
                            Button(c.nome) { stato.scegliClienteNota(nota.id, clienteId: c.id) }
                                .buttonStyle(.apple)
                        }
                    }
                    sceltaCliente(titolo: "Scegli il cliente")
                }
            }
        }
    }

    private func sceltaCliente(titolo: String) -> some View {
        Menu {
            ForEach(stato.clienti) { c in
                Button(c.nome) { stato.scegliClienteNota(nota.id, clienteId: c.id) }
            }
        } label: {
            Text(titolo).carattereApple(Tema.Apple.Carattere.pulsante)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(nota.stato != .daGuardare)
    }

    private var piede: some View {
        VStack(alignment: .leading, spacing: 0) {
            if nota.stato == .daGuardare {
                HStack(spacing: S.spazioPulsanti) {
                    Button("Conferma tutto") { stato.confermaNota(nota.id, proposte: nil) }
                        .buttonStyle(.applePrimarioGrande)
                        .keyboardShortcut(.defaultAction)
                        .disabled(nota.clienteId == nil || nota.proposteAperte.isEmpty || stato.solaLettura)
                        .help(nota.clienteId == nil ? "Scegli prima il cliente di cui si parla" : "Conferma tutte le voci proposte")
                    Button("Scarta la nota") { stato.scartaNota(nota.id) }
                        .buttonStyle(.appleGrande)
                }
                .padding(.top, S.pulsantiSopra)
            }
            Text(nota.conQwen ? "Capito con Qwen" : "Capito con le regole di Prisma")
                .carattereApple(S.piede)
                .foregroundColor(S.colorePiede)
                .padding(.top, S.piedeSopra)
        }
    }

    private func apriDossier(_ id: String) {
        stato.apriCliente(id)
    }
}

/// Una voce proposta: filo colorato a sinistra, titolo, riga, «Conferma» e «Scarta»; l'attività si modifica sul posto
/// (testo e data), il messaggio apre Messaggi con la conferma, l'obiettivo apre il dossier su Obiettivi.
private struct VoceNotaVocale: View {
    @Environment(StatoShell.self) var stato
    let nota: NotaInArrivo
    let proposta: PropostaNota
    let indice: Int
    let notaVocale: StatoNotaVocaleMac

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto
    @Environment(\.modoIstantanea) private var istantanea
    @State private var entrata = false
    @State private var titolo = ""
    @State private var data = Date()

    private typealias V = Tema.Apple.NotaVocale.Voce

    private var inModifica: Bool { notaVocale.inModifica == proposta.id }

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: V.raggio, style: .continuous)
        let dentro = entrata || calmo || scatto || istantanea
        VStack(alignment: .leading, spacing: V.spazio) {
            Text(proposta.titoloVoce)
                .carattereApple(V.titolo)
                .foregroundColor(V.coloreTitolo)
            if inModifica {
                modifica
            } else {
                Text(riga)
                    .carattereApple(V.riga)
                    .foregroundColor(V.coloreRiga)
                    .fixedSize(horizontal: false, vertical: true)
                if proposta.stato == .proposta, nota.stato == .daGuardare {
                    pulsanti
                }
            }
        }
        .padding(V.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(forma.fill(V.fondo))
        .overlay(alignment: .leading) { Rectangle().fill(V.colore(proposta.tipo)).frame(width: V.filo) }
        .clipShape(forma)
        .opacity(proposta.stato == .scartata ? V.opacitaScartata : 1)
        .padding(.top, V.sopra)
        .offset(x: dentro ? 0 : Tema.Apple.Moto.NotaVocale.spostamento)
        .opacity(dentro ? 1 : 0)
        .onAppear {
            guard !dentro else { return }
            let m = Tema.Apple.Moto.NotaVocale.self
            withAnimation(m.voce.delay(Double(indice) * m.passo)) { entrata = true }
        }
        .accessibilityElement(children: .contain)
    }

    /// La riga della voce: la frase della nota fra virgolette basse, l'attività con il mese, il resto com'è.
    private var riga: String {
        switch proposta.tipo {
        case .nota: return "«\(proposta.titolo)»"
        case .attivita:
            guard let s = proposta.scadenza, !proposta.titolo.contains(" · ") else { return proposta.titolo }
            return proposta.titolo + " · " + Formati.dataEstesa.string(from: s)
        case .messaggio, .obiettivo: return proposta.titolo
        }
    }

    private var pulsanti: some View {
        HStack(spacing: V.spazioPulsanti) {
            Button("Conferma") { stato.confermaNota(nota.id, proposte: [proposta.id]) }
                .buttonStyle(.applePrimario)
                .disabled(nota.clienteId == nil || stato.solaLettura)
            Button("Scarta") { stato.scartaPropostaNota(nota.id, proposta: proposta.id) }
                .buttonStyle(.apple)
            switch proposta.tipo {
            case .attivita:
                Button("Modifica") { apriModifica() }
                    .buttonStyle(.appleSobrio)
            case .obiettivo:
                Button("Apri l’obiettivo") { apriObiettivo() }
                    .buttonStyle(.appleSobrio)
                    .disabled(nota.clienteId == nil)
            case .nota, .messaggio:
                EmptyView()
            }
        }
    }

    private var modifica: some View {
        VStack(alignment: .leading, spacing: V.spazio) {
            TextField("Attività", text: $titolo)
                .textFieldStyle(.roundedBorder)
                .onSubmit(salva)
                .onExitCommand { notaVocale.inModifica = nil }
            DatePicker("Scadenza", selection: $data, displayedComponents: .date)
                .datePickerStyle(.field)
            HStack(spacing: V.spazioPulsanti) {
                Button("Salva") { salva() }
                    .buttonStyle(.applePrimario)
                Button("Annulla") { notaVocale.inModifica = nil }
                    .buttonStyle(.apple)
            }
        }
    }

    private func apriModifica() {
        titolo = proposta.titolo
        data = proposta.scadenza ?? Calendar(identifier: .gregorian).startOfDay(for: Date())
        notaVocale.inModifica = proposta.id
    }

    private func salva() {
        let giorno = Calendar(identifier: .gregorian).startOfDay(for: data)
        stato.modificaPropostaNota(nota.id, proposta: proposta.id, titolo: titolo, scadenza: giorno)
        notaVocale.inModifica = nil
    }

    /// Il dossier su Obiettivi, con l'obiettivo da aggiornare (la modifica si conferma qui).
    private func apriObiettivo() {
        guard let c = nota.clienteId else { return }
        stato.apriCliente(c)
        stato.schedaCliente = .obiettivi
    }
}

// MARK: - «Come funziona»

/// Lo strato di «Come funziona» nella shell: vuoto quando la scena è chiusa.
struct StratoComeFunzionaNota: View {
    let aperta: Bool
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        ZStack {
            if aperta {
                ComeFunzionaNotaVocale()
                    .transition(transizione)
            }
        }
    }

    private var transizione: AnyTransition {
        guard !istantanea else { return .identity }
        let m = Tema.Apple.Moto.Inquadra.self
        return .asymmetric(insertion: AnyTransition.opacity.animation(calmo ? Tema.Moto.dissolvenzaCalma : m.velo),
                           removal: AnyTransition.opacity.animation(calmo ? Tema.Moto.dissolvenzaCalma : m.chiusura))
    }
}

/// La scena dimostrativa: il velo, il telefono disegnato in ascolto (la nota del template, dati di prova) e la scheda
/// «Aspetto la nota…» con le ultime note arrivate.
struct ComeFunzionaNotaVocale: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @Environment(\.prismaCalmo) private var calmo
    @State private var entrato = false

    private typealias D = Tema.Apple.NotaVocale.ComeFunziona
    private typealias S = Tema.Apple.NotaVocale.Scheda
    private typealias I = Tema.Apple.Inquadra.Disposizione
    private typealias A = Tema.Apple.Apparecchio

    var body: some View {
        let m = Tema.Apple.Moto.Inquadra.self
        let dentro = entrato || fermo || calmo
        return GeometryReader { geo in
            ZStack {
                VeloScena()
                HStack(alignment: .top, spacing: D.spazio) {
                    TelefonoDisegnato { SchermoNotaDimostrativo() }
                        .rotationEffect(.degrees(dentro ? 0 : m.rotazioneTelefono))
                        .offset(y: dentro ? 0 : m.spostamentoTelefono)
                        .opacity(dentro ? 1 : 0)
                        .accessibilityLabel(Text("iPhone in ascolto: esempio con i dati di prova"))
                    scheda
                        .padding(.top, D.scartoScheda)
                }
                .scaleEffect(scala(geo.size))
                Button("Chiudi Come funziona") { stato.chiudiSovrapposizione() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(StileSemplice())
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !entrato, !scatto else { return }
            if fermo || calmo { entrato = true } else { withAnimation(m.telefono) { entrato = true } }
        }
    }

    private var scheda: some View {
        let note = Array(stato.dati.noteInArrivo.sorted { $0.quando > $1.quando }.prefix(D.massimoNote))
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: S.spazioTesta) {
                SferaVera(misura: S.sfera, viva: true, pensa: false)
                Text("Arriva sul Mac")
                    .carattereApple(S.etichetta)
                    .foregroundColor(S.coloreEtichetta)
                Spacer(minLength: 0)
                Button { stato.chiudiSovrapposizione() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.apple)
                    .help("Chiudi (Esc)")
                    .accessibilityLabel(Text("Chiudi"))
            }
            Text("Aspetto la nota…")
                .carattereApple(S.fraseAttesa)
                .foregroundColor(S.coloreAttesa)
                .padding(.vertical, S.attesa)
            Text("Sull’iPhone apri Prisma › Incontri › Nota veloce e detta: la voce diventa testo sull’iPhone, l’audio non si registra. Il testo arriva qui, cifrato in rete locale, e Prisma propone cosa farne: confermi tu.")
                .carattereApple(D.frase)
                .foregroundColor(D.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            if !note.isEmpty, !stato.inModoCliente {
                Text("Le ultime note")
                    .carattereApple(D.titoloElenco)
                    .foregroundColor(D.coloreTitoloElenco)
                    .padding(.top, D.elencoSopra)
                ForEach(note) { n in
                    VoceOggiNotaVocale(nota: n)
                        .padding(.top, D.fraseSopra)
                }
            }
        }
        .padding(S.padding)
        .frame(width: S.larghezza, alignment: .leading)
        .superficieApple(S.superficie)
    }

    private func scala(_ misura: CGSize) -> CGFloat {
        let larghezza = A.larghezza + D.spazio + S.larghezza
        let altezza = A.altezza + D.scartoScheda
        let s = min(1, (misura.width - 2 * I.margine) / larghezza, (misura.height - 2 * I.margine) / altezza)
        return max(I.scalaMinima, s)
    }
}

/// Lo schermo del telefono disegnato in ascolto: l'ora e «Prisma» (mai «In macchina»), «Una nota veloce», «Dopo la
/// visita da Giulia», il testo che si scrive (dati di prova del template), l'onda, il pulsante e «Ascolto · sull’iPhone».
struct SchermoNotaDimostrativo: View {
    private typealias T = Tema.Apple.NotaVocale.Telefono
    private typealias R = Tema.Apple.NotaVocale.Registra
    private typealias A = Tema.Apple.Apparecchio

    /// L'ora della dimostrazione (dato di prova fisso: le istantanee restano uguali).
    static let oraDiProva = "11:42"

    var body: some View {
        let o = Tema.Apple.NotaVocale.onda
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: A.raggioSchermo, style: .continuous)
                .fill(LinearGradient(colors: T.fondo, startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(Self.oraDiProva)
                    Spacer(minLength: 0)
                    Text("Prisma")
                }
                .carattereApple(T.testa)
                .foregroundColor(T.inchiostro.opacity(T.opacitaTesta))
                Text("Una nota veloce")
                    .carattereApple(T.titolo)
                    .foregroundColor(T.inchiostro)
                    .padding(.top, T.titoloSopra)
                Text("Dopo la visita da Giulia")
                    .carattereApple(T.sottotitolo)
                    .foregroundColor(T.inchiostro.opacity(T.opacitaSottotitolo))
                    .padding(.top, T.sottotitoloSopra)
                TestoProgressivo(testo: NotaVocaleDiProva.testo)
                    .carattereApple(T.testo)
                    .foregroundColor(T.inchiostro)
                    .frame(minHeight: T.altezzaTesto, alignment: .topLeading)
                    .padding(.top, T.testoSopra)
                TelaAnimata(tempoFinale: o.tempoIstantanea) { c, misura, t in
                    SchermoNotaDimostrativo.onda(&c, misura, t)
                }
                .frame(width: o.larghezza, height: o.altezza)
                .padding(.top, T.ondaSopra)
                Spacer(minLength: 0)
            }
            .padding(.top, T.paddingSopra)
            .padding(.horizontal, T.paddingLati)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                FacciaPulsanteRegistra(ascolta: true, fatto: false)
                    .padding(.bottom, R.dalFondo - T.statoDalFondo)
                Text("Ascolto · sull’iPhone")
                    .carattereApple(T.stato)
                    .foregroundColor(T.inchiostro.opacity(T.opacitaStato))
                    .padding(.bottom, T.statoDalFondo)
            }
        }
    }

    /// L'onda del template della nota: a = 0,2 + 0,8·|sin(4t + 0,5i)·sin(1,7t + 0,2i)|, altezza max(3, a·44).
    static func onda(_ c: inout GraphicsContext, _ misura: CGSize, _ t: Double) {
        let o = Tema.Apple.NotaVocale.onda
        for i in 0..<o.barre {
            let x = Double(i)
            let a = 0.2 + 0.8 * abs(sin(4 * t + 0.5 * x) * sin(1.7 * t + 0.2 * x))
            let h = max(o.minima, CGFloat(a) * o.scala)
            let r = CGRect(x: CGFloat(i) * o.passo, y: (misura.height - h) / 2, width: o.larghezzaBarra, height: h)
            c.fill(Path(roundedRect: r, cornerRadius: o.raggioBarra), with: .color(o.coloreAscolto))
        }
    }
}
#endif
