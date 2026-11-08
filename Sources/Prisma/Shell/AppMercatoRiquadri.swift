import SwiftUI

// I due riquadri di Mercato (§12.1.5, §12.1.6, §12.1.7), il dettaglio della tessera (§12.4) e i pezzi che li
// compongono: le schede di «Chi è toccato oggi» con il filo del tono e gli avatar sovrapposti, le righe degli avvisi
// con il pallino e l'interruttore, il risultato della ricerca per ISIN. Valori in Tema.Apple+Mercato.swift.

// MARK: - Chi è toccato

/// «Chi è toccato oggi» (o «dall'ultimo aggiornamento» con i dati vecchi): una scheda per evento, dal più toccato.
/// Senza soglie, senza dati o senza clienti toccati la frase onesta al centro.
struct RiquadroToccati: View {
    @Environment(StatoShell.self) var stato
    let eventi: [EventoMercato]
    let vecchi: Bool
    let senzaDati: Bool

    private typealias R = Tema.Apple.Mercato.Riquadro
    private typealias K = Tema.Apple.Mercato.Toccati

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiAppMercato.titoloToccati(vecchi: vecchi))
                .carattereApple(R.etichetta)
                .foregroundColor(R.coloreEtichetta)
                .lineLimit(1)
                .padding(.bottom, R.sottoEtichetta)
                .accessibilityAddTraits(.isHeader)
            if eventi.isEmpty {
                FraseVuotaMercato(testo: vuoto)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: K.fraSchede) {
                        ForEach(eventi) { e in
                            SchedaToccatiMercato(evento: e)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(R.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(R.superficie, raggio: R.raggio)
    }

    private var vuoto: String {
        if senzaDati { return TestiAppMercato.toccatiSenzaDati }
        if stato.dati.impostazioni.mercato.senzaSoglie { return TestiAppMercato.toccatiSenzaSoglie }
        return TestiAppMercato.nessunoToccato
    }
}

/// La frase al centro di un riquadro vuoto.
struct FraseVuotaMercato: View {
    let testo: String

    var body: some View {
        let r = Tema.Apple.Mercato.Riquadro.self
        Text(testo)
            .carattereApple(r.vuoto)
            .foregroundColor(r.coloreVuoto)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: r.larghezzaVuoto)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Una scheda `.tile` con il filo del tono a sinistra: titolo, frase con il più toccato e i canali separati, la fonte
/// e la data, gli avatar sovrapposti (al massimo 3, poi «+N») e «Prepara un messaggio» per il più toccato (gli altri
/// dal menu del pulsante).
struct SchedaToccatiMercato: View {
    @Environment(StatoShell.self) var stato
    let evento: EventoMercato

    private typealias K = Tema.Apple.Mercato.Toccati

    var body: some View {
        let _ = ContaCorpi.segna()
        let e = evento
        let forma = RoundedRectangle(cornerRadius: K.raggio, style: .continuous)
        let nomi = Dictionary(stato.clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { primo, _ in primo })
        let tipoSerie = e.serieId.flatMap { stato.dati.mercato.serie($0)?.tipo }
        let primo = e.toccati.first.flatMap { stato.cliente($0.clienteId) }
        return VStack(alignment: .leading, spacing: 0) {
            Text(e.titolo)
                .carattereApple(K.titolo)
                .foregroundColor(K.coloreTitolo)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiAppMercato.fraseToccati(e, tipoSerie: tipoSerie, nomi: nomi))
                .carattereApple(K.frase)
                .foregroundColor(K.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, K.sottoTitolo)
            Text(e.fonte)
                .carattereApple(K.fonte)
                .foregroundColor(K.coloreFonte)
                .lineLimit(1)
                .padding(.top, K.sottoTitolo)
            HStack(spacing: K.spazioPiede) {
                GruppoAvatarMercato(clienti: e.toccati.compactMap { stato.cliente($0.clienteId) })
                if let c = e.toccati.first?.canaleUnico {
                    EtichettaCanaleApple(canale: c, compatta: true)
                }
                Spacer(minLength: 0)
                if let primo {
                    Button(TestiAppMercato.preparaMessaggioA(primo.nome)) {
                        stato.preparaMessaggioMercato(e, clienteId: primo.id)
                    }
                    .buttonStyle(.apple)
                    .disabled(!stato.appConsentita(.messaggi))
                    .contextMenu {
                        ForEach(e.toccati.dropFirst().compactMap { stato.cliente($0.clienteId) }) { c in
                            Button(TestiAppMercato.preparaMessaggioA(c.nome)) {
                                stato.preparaMessaggioMercato(e, clienteId: c.id)
                            }
                        }
                    }
                }
            }
            .padding(.top, K.sottoFrase)
        }
        .padding(K.padding)
        .padding(.leading, K.filo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { forma.fill(K.superficie.riempimento) }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(ColoriMercato.avviso(stato.tonoEventoMercato(e)))
                .frame(width: K.filo)
        }
        .clipShape(forma)
        .overlay { forma.strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo) }
    }
}

/// Gli avatar sovrapposti (30, −8, bordo 2 `cardPiena`), al massimo 3 e poi «+N»; clic: il dossier del cliente.
struct GruppoAvatarMercato: View {
    @Environment(StatoShell.self) var stato
    let clienti: [Cliente]

    private typealias K = Tema.Apple.Mercato.Toccati

    var body: some View {
        let _ = ContaCorpi.segna()
        let mostrati = Array(clienti.prefix(RegoleTessereMercato.avatarMassimi))
        let altri = clienti.count - mostrati.count
        HStack(spacing: K.sovrapposizione) {
            ForEach(mostrati) { c in
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: K.avatar)
                    .overlay { Circle().strokeBorder(K.coloreBordoAvatar, lineWidth: K.bordoAvatar) }
                    .contentShape(Circle())
                    .onTapGesture { stato.apriCliente(c.id) }
                    .help(c.nome)
                    .accessibilityLabel(c.nome)
                    .accessibilityAddTraits(.isButton)
            }
            if altri > 0 {
                Text(TestiAppMercato.altri(altri))
                    .carattereApple(K.altri)
                    .foregroundColor(K.coloreAltri)
                    .frame(width: K.avatar, height: K.avatar)
                    .background { Circle().fill(K.fondoAltri) }
                    .overlay { Circle().strokeBorder(K.coloreBordoAvatar, lineWidth: K.bordoAvatar) }
                    .help(clienti.dropFirst(mostrati.count).map(\.nome).joined(separator: ", "))
            }
        }
    }
}

// MARK: - Avvisi

/// «Avvisi»: in testa il risultato della ricerca per ISIN (un posto fisso, mai tagliato), poi le righe degli avvisi.
struct RiquadroAvvisi: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var sessione: SessioneMercato

    private typealias R = Tema.Apple.Mercato.Riquadro

    var body: some View {
        let _ = ContaCorpi.segna()
        let avvisi = stato.avvisiMercato
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiAppMercato.avvisi)
                .carattereApple(R.etichetta)
                .foregroundColor(R.coloreEtichetta)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.bottom, R.sottoEtichetta)
                .accessibilityAddTraits(.isHeader)
            if let r = sessione.risultatoISIN {
                RisultatoISINMercato(risultato: r)
                    .id(sessione.giroRicerca)
                    .padding(.bottom, Tema.Apple.Mercato.ISIN.sottoRisultato)
            }
            if avvisi.isEmpty {
                FraseVuotaMercato(testo: stato.dati.impostazioni.mercato.senzaSoglie
                                  ? TestiAppMercato.nessunAvviso : TestiAppMercato.nessunAvvisoConSoglie)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(avvisi) { a in
                            RigaAvvisoMercato(avviso: a)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(R.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(R.superficie, raggio: R.raggio)
    }
}

/// Una riga `.row` (§12.1.6): pallino del tono (il rosso nuovo pulsa), avatar 30, il cliente con il canale, il titolo
/// dell'avviso e la fonte; a destra l'interruttore «Da guardare» (spento = visto, pallino grigio). Clic sul testo:
/// la posizione o il dossier; clic secondario: messaggio, apertura, visto.
struct RigaAvvisoMercato: View {
    @Environment(StatoShell.self) var stato
    let avviso: AvvisoMercato

    private typealias A = Tema.Apple.Mercato.Avviso

    var body: some View {
        let _ = ContaCorpi.segna()
        let a = avviso
        let cliente = stato.cliente(a.clienteId)
        let tono = stato.tonoAvvisoMercato(a)
        return HStack(alignment: .center, spacing: A.spazio) {
            PallinoAvvisoMercato(colore: ColoriMercato.avviso(tono), pulsa: tono == .rosso)
            if let c = cliente {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: A.avatar)
            }
            VStack(alignment: .leading, spacing: A.spazioTesti) {
                HStack(spacing: A.spazioNome) {
                    Text(cliente?.nome ?? "")
                        .carattereApple(A.titolo)
                        .foregroundColor(A.coloreTitolo)
                        .lineLimit(1)
                    if let k = a.canale {
                        EtichettaCanaleApple(canale: k, compatta: true)
                    }
                }
                Text(a.titolo)
                    .carattereApple(A.descrizione)
                    .foregroundColor(A.coloreDescrizione)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(a.fonte)
                    .carattereApple(A.fonte)
                    .foregroundColor(A.coloreFonte)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { stato.apriAvvisoMercato(a) }
            .help(a.dettaglio)
            Toggle(isOn: Binding(get: { a.stato == .nuovo }, set: { stato.segnaAvvisoMercato(a.id, visto: !$0) })) { EmptyView() }
                .toggleStyle(.appleSenzaEtichetta)
                .disabled(!stato.mercatoModificabile)
                .accessibilityLabel(TestiAppMercato.daGuardare)
        }
        .padding(.vertical, A.paddingVerticale)
        .overlay(alignment: .bottom) {
            Rectangle().fill(A.filo).frame(height: A.spessoreFilo)
        }
        .contextMenu {
            if stato.appConsentita(.messaggi) {
                Button(TestiAppMercato.preparaMessaggio) { stato.preparaMessaggioAvviso(a) }
            }
            Button(a.posizioni.count == 1 ? TestiAppMercato.apriPosizione : TestiAppMercato.apriDossier) { stato.apriAvvisoMercato(a) }
            Button(a.stato == .nuovo ? TestiAppMercato.segnaVisto : TestiAppMercato.segnaNuovo) {
                stato.segnaAvvisoMercato(a.id, visto: a.stato == .nuovo)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(TestiAppMercato.voceAvviso(a, cliente: cliente?.nome ?? ""))
    }
}

/// Il pallino 10 del tono; il rosso nuovo pulsa (alone 6 al 18%, 1,6 s senza fine). Con «Riduci movimento» e nelle
/// istantanee resta pieno, senza alone.
struct PallinoAvvisoMercato: View {
    let colore: Color
    let pulsa: Bool

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var acceso = false

    private typealias A = Tema.Apple.Mercato.Avviso

    var body: some View {
        Circle()
            .fill(colore)
            .frame(width: A.pallino, height: A.pallino)
            .background {
                if pulsa && !fermo {
                    Circle()
                        .fill(A.coloreAlone)
                        .frame(width: A.pallino + 2 * A.alone, height: A.pallino + 2 * A.alone)
                        .scaleEffect(acceso ? 1 : A.pallino / (A.pallino + 2 * A.alone))
                        .opacity(acceso ? 1 : 0)
                }
            }
            .frame(width: A.pallino, height: A.pallino)
            .onAppear {
                guard pulsa, !fermo else { return }
                withAnimation(Tema.Apple.Mercato.Moto.pulsazione) { acceso = true }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Risultato della ricerca per ISIN

/// La scheda del risultato (§12.1.7): il nome e l'ISIN, poi «Quota», «Da inizio anno» e «Nei portafogli» (con
/// l'elenco dei clienti a un clic); senza quote «Nessuna quota per …» e «Importa le quote»; un codice sbagliato la
/// frase rossa. Entra da y +10 in 0,42 s (ferma con «Riduci movimento» e nelle istantanee).
struct RisultatoISINMercato: View {
    @Environment(StatoShell.self) var stato
    let risultato: RisultatoISIN

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var entrato = false
    @State private var elencoClienti = false

    private typealias I = Tema.Apple.Mercato.ISIN

    var body: some View {
        let _ = ContaCorpi.segna()
        let visibile = fermo || entrato
        return contenuto
            .opacity(visibile ? 1 : 0)
            .offset(y: visibile ? 0 : Tema.Apple.Mercato.Moto.spostamentoRisultato)
            .onAppear {
                guard !fermo else { return }
                withAnimation(Tema.Apple.Mercato.Moto.animazioneRisultato) { entrato = true }
            }
    }

    @ViewBuilder private var contenuto: some View {
        switch risultato {
        case .nonValido:
            Text(TestiMercato.isinNonValido)
                .carattereApple(I.errore)
                .foregroundColor(I.coloreErrore)
                .fixedSize(horizontal: false, vertical: true)
        case .trovato(let r):
            trovato(r)
        }
    }

    private func trovato(_ r: RicercaISIN) -> some View {
        let oggi = Date()
        let nomePosizione = r.posizioni.compactMap { id in stato.dati.posizioni.first { $0.id == id }?.nome }.first
        let nome = (r.quota?.nome).flatMap { $0.isEmpty ? nil : $0 } ?? nomePosizione ?? TestiAppMercato.nessunaQuota(r.isin)
        let ultimo = r.quota.flatMap { MotoreMercato.valore($0.punti, al: oggi) }
        let daInizio = r.quota.flatMap { MotoreMercato.daInizioAnno($0, oggi: oggi) }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(nome)
                    .carattereApple(I.nome)
                    .foregroundColor(I.coloreNome)
                    .lineLimit(2)
                Spacer(minLength: I.spazio)
                Text(r.isin)
                    .carattereApple(I.codice)
                    .foregroundColor(I.coloreCodice)
                    .textSelection(.enabled)
            }
            HStack(alignment: .top, spacing: I.spazioCifre) {
                cifra(TestiAppMercato.quota, ultimo.map { Formati.euroDecimali($0.valore) } ?? TestiAppMercato.senzaValore)
                if let v = daInizio {
                    cifra(TestiAppMercato.daInizioAnno, TestiMercato.percentualeConSegno(v), colore: v >= 0 ? Tema.Apple.Colore.verde : Tema.Apple.Colore.rosso)
                }
                Button { elencoClienti = r.numeroClienti > 0 } label: {
                    cifra(TestiAppMercato.neiPortafogliEtichetta, TestiAppMercato.clienti(r.numeroClienti))
                }
                .buttonStyle(StileSemplice())
                .help(r.neiPortafogli)
                .popover(isPresented: $elencoClienti, arrowEdge: .bottom) { elenco(r) }
                Spacer(minLength: 0)
            }
            .padding(.top, I.sopraCifre)
            HStack(spacing: I.spazio) {
                ForEach(Canale.allCases.filter { r.clientiPerCanale[$0] != nil }) { k in
                    EtichettaCanaleApple(canale: k, compatta: true)
                }
                if let u = ultimo, let q = r.quota {
                    Text(TestiAppMercato.quotaDel(u.data) + " · " + TestiMercato.citazione(origine: q.origine, fonte: u.fonte ?? q.fonte, datoDiTerzi: nil))
                        .carattereApple(I.nota)
                        .foregroundColor(I.coloreNota)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                #if os(macOS)
                if r.quota == nil, !stato.solaLettura {
                    Button(TestiAppMercato.importaQuote) { stato.scegliFileMercato() }
                        .buttonStyle(.apple)
                }
                #endif
            }
            .padding(.top, I.sopraCifre)
        }
        .padding(I.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(I.superficie, raggio: I.raggio)
    }

    private func cifra(_ etichetta: String, _ valore: String, colore: Color = Tema.Apple.Mercato.ISIN.coloreCifra) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(etichetta)
                .carattereApple(I.etichetta)
                .foregroundColor(I.coloreEtichetta)
                .lineLimit(1)
            Text(valore)
                .carattereApple(I.cifra)
                .foregroundColor(colore)
                .lineLimit(1)
        }
    }

    /// I clienti con l'ISIN in portafoglio: clic, la loro posizione in Posizioni.
    private func elenco(_ r: RicercaISIN) -> some View {
        let posizioni = r.posizioni.compactMap { id in stato.dati.posizioni.first { $0.id == id } }
        return VStack(alignment: .leading, spacing: I.spazio) {
            ForEach(posizioni) { p in
                Button {
                    elencoClienti = false
                    stato.apriPosizione(p)
                } label: {
                    HStack(spacing: I.spazio) {
                        Text(stato.cliente(p.clienteId)?.nome ?? "")
                            .carattereApple(I.nome)
                            .foregroundColor(I.coloreNome)
                        Text(p.nome)
                            .carattereApple(I.etichetta)
                            .foregroundColor(I.coloreEtichetta)
                        EtichettaCanaleApple(canale: p.canale, compatta: true)
                    }
                }
                .buttonStyle(StileSemplice())
            }
        }
        .padding(I.padding)
    }
}

// MARK: - Dettaglio della tessera

/// Il dettaglio che nasce dalla tessera (§12.4, Dubbio 10): il nome, la fonte e il codice, il valore con la
/// variazione, la serie degli ultimi 12 mesi che si disegna, i limiti, il dato di terzi e quanti valori ci sono.
struct DettaglioSerieMercato: View {
    @Environment(StatoShell.self) var stato
    let id: String

    @Environment(\.statoDettaglioApple) private var dettaglio

    private typealias K = Tema.Apple.Mercato.Dettaglio

    var body: some View {
        let _ = ContaCorpi.segna()
        if let s = stato.dati.mercato.serie(id) {
            contenuto(s)
        }
    }

    private func contenuto(_ s: SerieMercato) -> some View {
        let oggi = Date()
        let t = MotoreMercato.tessera(s, oggi: oggi)
        let lunga = MotoreMercato.lineaLunga(s, oggi: oggi)
        let dec = t.decimali
        return VStack(alignment: .leading, spacing: K.spazio) {
            VStack(alignment: .leading, spacing: K.spazioTitolo) {
                Text(s.nome)
                    .carattereApple(K.titolo)
                    .foregroundColor(K.coloreTitolo)
                Text(TestiAppMercato.dettaglioSottotitolo(s))
                    .carattereApple(K.sottotitolo)
                    .foregroundColor(K.coloreSottotitolo)
                    .textSelection(.enabled)
            }
            HStack(alignment: .firstTextBaseline, spacing: K.spazio) {
                Text(t.valoreTesto)
                    .carattereApple(K.valore)
                    .foregroundColor(K.coloreTitolo)
                if let v = t.variazioneTesto {
                    Text(v)
                        .carattereApple(Tema.Apple.Mercato.Tessera.variazione)
                        .foregroundColor(ColoriMercato.cifra(t.tono))
                }
                if let d = t.dataTesto {
                    Text(d)
                        .carattereApple(K.sottotitolo)
                        .foregroundColor(K.coloreSottotitolo)
                }
            }
            Text(TestiAppMercato.ultimiMesi)
                .carattereApple(Tema.Apple.Mercato.Riquadro.etichetta)
                .foregroundColor(Tema.Apple.Mercato.Riquadro.coloreEtichetta)
            if let l = lunga {
                HStack(alignment: .top, spacing: K.spazio) {
                    TracciatoGrafico(punti: l.punti.map { CGPoint(x: $0.x, y: $0.y) }, colore: ColoriMercato.linea(t.tono),
                                     spessore: K.spessoreGrafico, area: true, puntoFinale: true)
                        .frame(height: K.altezzaGrafico)
                    VStack(alignment: .trailing) {
                        Text(MotoreMercato.testoValore(l.massimo, unita: s.unita, decimali: dec))
                        Spacer(minLength: 0)
                        Text(MotoreMercato.testoValore(l.minimo, unita: s.unita, decimali: dec))
                    }
                    .carattereApple(K.asse)
                    .foregroundColor(K.coloreAsse)
                    .frame(height: K.altezzaGrafico)
                }
                HStack {
                    Text(Formati.meseAnno.string(from: l.inizio))
                    Spacer(minLength: 0)
                    Text(TestiAppMercato.valoriInArchivio(s.punti.count))
                    Spacer(minLength: 0)
                    Text(Formati.meseAnno.string(from: l.fine))
                }
                .carattereApple(K.asse)
                .foregroundColor(K.coloreAsse)
            } else {
                FraseVuotaMercato(testo: TestiAppMercato.valoriInArchivio(s.punti.count))
                    .frame(height: K.altezzaGrafico)
            }
            Spacer(minLength: 0)
            HStack(spacing: K.spazioPiede) {
                Button(TestiAppMercato.chiudi) { dettaglio?.chiudi() }
                    .buttonStyle(.appleGrande)
                if let terzi = s.datoDiTerzi {
                    Text(TestiAppMercato.datoDiTerzi(terzi))
                        .carattereApple(K.sottotitolo)
                        .foregroundColor(K.coloreSottotitolo)
                }
            }
        }
    }
}
