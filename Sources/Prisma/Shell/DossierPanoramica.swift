import SwiftUI

/// Scheda «Panoramica» del dossier nel tema Apple (Design/template-apple-specifica.md §4.2.2, PC C02, C06, C07, C23):
///
///   ┌──────── Dati per l'analisi ─────── 84% ┐┌──── Da ricordare ─────────┐
///   │  ◯ 120/13     ○ Data di nascita  [Completa] ││ Ha un mutuo fino al 2041…  │
///   │  completi     ○ Reddito annuo    [Completa] │└───────────────────────────┘
///   │               ○ …                           │┌──── Prossimo incontro ────┐
///   │                                             ││ Domani, 10:00 · titolo ›   │
///   └─────────────────────────────────────────────┘└───────────────────────────┘
///   (sotto, il resto della panoramica di Prisma: riesame annuale, In regola, il dossier collegato)
///
/// - La percentuale e le voci vengono da `MotoreCompletezza` (in cache: `stato.completezzaCliente`); «Completa» apre
///   il posto del dato (`stato.apriCompletamento`, come in ComponentiCompletezza.swift), la croce lo segna «non
///   pertinente». Strumento del consulente: in modalità cliente la card non c'è.
/// - «Da ricordare» è la nota del cliente; il prossimo incontro viene dall'agenda e la card apre l'Agenda sul giorno.
/// - I blocchi entrano con `.entrataDossier(i)`, la percentuale si conta, l'anello parte a 0,15 s.
struct PanoramicaDossierApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Clienti.Panoramica.self
        let completezza = stato.inModoCliente ? nil : stato.completezzaCliente(cliente.id)
        let prossimo = stato.prossimiAppuntamenti.first { $0.clienteId == cliente.id }
        return VStack(alignment: .leading, spacing: p.sopraSeguito) {
            griglia(completezza: completezza, prossimo: prossimo)
            PanoramicaCliente(cliente: cliente, conQuadro: false)
                .corniceSchedaDossier()
                .entrataDossier(3, sfocatura: false)
        }
    }

    @ViewBuilder private func griglia(completezza: CompletezzaCliente?, prossimo: Appuntamento?) -> some View {
        let p = Tema.Apple.Clienti.Panoramica.self
        let laterali = VStack(alignment: .leading, spacing: p.spazio) {
            // Vera, fase 4: «Il sussurro» (VisteSussurroVera.swift); senza voci, in modalità cliente o spento non c'è
            SussurroDossierVista(cliente: cliente)
                .entrataDossier(1)
            // Vera, fase 2: «Il cliente in 30 secondi» con un tocco (VisteFaseDueVera.swift); non in modalità cliente
            TrentaSecondiDossierVista(cliente: cliente)
                .entrataDossier(1)
            DaRicordareApple(cliente: cliente)
                .entrataDossier(1)
            ProssimoIncontroApple(cliente: cliente, appuntamento: prossimo)
                .entrataDossier(2)
        }
        if let k = completezza {
            ColonneProporzionaliDossier(proporzione: p.proporzione, spazio: p.spazio, larghezzaMinima: p.larghezzaDueColonne) {
                DatiAnalisiApple(cliente: cliente, completezza: k)
                    .entrataDossier(0)
                laterali
            }
        } else {
            laterali
        }
    }
}

// MARK: - Due colonne 1,25fr 1fr

/// Due colonne nella proporzione data (`1,25fr 1fr`), alte quanto la più alta: le card dentro si allungano.
/// Sotto `larghezzaMinima` le colonne vanno una sotto l'altra, ognuna alta quanto le serve.
struct ColonneProporzionaliDossier: Layout {
    var proporzione: CGFloat
    var spazio: CGFloat
    var larghezzaMinima: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezza = proposal.width ?? larghezzaMinima
        guard subviews.count == 2 else {
            let h = subviews.reduce(CGFloat(0)) { $0 + $1.sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height }
            return CGSize(width: larghezza, height: h)
        }
        if larghezza < larghezzaMinima {
            let a = subviews[0].sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height
            let b = subviews[1].sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height
            return CGSize(width: larghezza, height: a + spazio + b)
        }
        let (sinistra, destra) = colonne(larghezza)
        return CGSize(width: larghezza, height: altezzaRiga(subviews, sinistra: sinistra, destra: destra))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let larghezza = bounds.width
        guard subviews.count == 2 else {
            var y = bounds.minY
            for s in subviews {
                let h = s.sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height
                s.place(at: CGPoint(x: bounds.minX, y: y), proposal: ProposedViewSize(width: larghezza, height: h))
                y += h
            }
            return
        }
        if larghezza < larghezzaMinima {
            let a = subviews[0].sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height
            let b = subviews[1].sizeThatFits(ProposedViewSize(width: larghezza, height: nil)).height
            subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), proposal: ProposedViewSize(width: larghezza, height: a))
            subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + a + spazio),
                              proposal: ProposedViewSize(width: larghezza, height: b))
            return
        }
        let (sinistra, destra) = colonne(larghezza)
        let h = altezzaRiga(subviews, sinistra: sinistra, destra: destra)
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), proposal: ProposedViewSize(width: sinistra, height: h))
        subviews[1].place(at: CGPoint(x: bounds.minX + sinistra + spazio, y: bounds.minY),
                          proposal: ProposedViewSize(width: destra, height: h))
    }

    /// Le larghezze delle due colonne.
    private func colonne(_ larghezza: CGFloat) -> (CGFloat, CGFloat) {
        let utile = max(0, larghezza - spazio)
        let sinistra = utile * proporzione / (proporzione + 1)
        return (sinistra, utile - sinistra)
    }

    private func altezzaRiga(_ subviews: Subviews, sinistra: CGFloat, destra: CGFloat) -> CGFloat {
        let a = subviews[0].sizeThatFits(ProposedViewSize(width: sinistra, height: nil)).height
        let b = subviews[1].sizeThatFits(ProposedViewSize(width: destra, height: nil)).height
        return max(a, b)
    }
}

// MARK: - Dati per l'analisi

/// «Dati per l'analisi»: la percentuale 22 (verde da 85, altrimenti arancio), l'anello 120/13 con «completi» e le
/// voci da completare come righe `.prep`, ognuna con «Completa» e la croce «non pertinente»; sotto, «Mostra tutte»
/// e le voci segnate non pertinenti con «Ripristina».
struct DatiAnalisiApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    let completezza: CompletezzaCliente
    @State private var tutte = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Clienti.Panoramica.self
        let k = completezza
        let completo = k.percentuale >= p.sogliaVerde
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: p.spazioTitolo) {
                Text(TestiCompletezza.occhiello)
                    .carattereApple(p.titolo)
                    .foregroundColor(p.coloreTitolo)
                Spacer(minLength: p.spazioTitolo)
                NumeroCheConta(Double(k.percentuale), formato: .percentuale)
                    .carattereApple(p.percentuale)
                    .foregroundColor(completo ? p.testoCompleto : p.testoParziale)
                    .help(TestiCompletezza.metodo)
            }
            HStack(alignment: .top, spacing: p.spazioAnello) {
                Anello(frazione: k.quota, colore: completo ? p.anelloCompleto : p.anelloParziale,
                       misura: p.anello, spessore: p.spessoreAnello,
                       ritardo: Tema.Apple.Clienti.Moto.ritardoAnelli) {
                    Text("completi")
                        .carattereApple(p.centroAnello)
                        .foregroundColor(p.coloreCentro)
                }
                elenco(k)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, p.sopraCorpo)
            Spacer(minLength: 0)
        }
        .padding(p.paddingDati)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(p.superficie)
    }

    @ViewBuilder private func elenco(_ k: CompletezzaCliente) -> some View {
        let p = Tema.Apple.Clienti.Panoramica.self
        VStack(alignment: .leading, spacing: 0) {
            if k.daCompletare.isEmpty {
                Text(TestiCompletezza.tuttoCompleto)
                    .carattereApple(p.tuttoCompleto)
                    .foregroundColor(p.coloreVoce)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, p.paddingVoce)
            } else {
                ForEach(mostrate(k)) { v in
                    VoceDaCompletareApple(voce: v,
                                          completa: { stato.apriCompletamento(v, cliente: cliente.id) },
                                          escludi: { escludi(v) },
                                          solaLettura: stato.solaLettura)
                }
            }
            piede(k)
        }
    }

    private func mostrate(_ k: CompletezzaCliente) -> [VoceCompletezza] {
        tutte ? k.daCompletare : Array(k.daCompletare.prefix(MotoreCompletezza.massimoPanoramica))
    }

    private func escludi(_ v: VoceCompletezza) {
        stato.segnaDatoNonPertinente(v.id, cliente: cliente.id)
        stato.mostraAvviso(TestiCompletezza.avvisoEsclusa(v.titolo, nome: cliente.nome))
    }

    @ViewBuilder private func piede(_ k: CompletezzaCliente) -> some View {
        let p = Tema.Apple.Clienti.Panoramica.self
        let molte = k.daCompletare.count > MotoreCompletezza.massimoPanoramica
        if molte || !k.escluse.isEmpty {
            HStack(spacing: p.spazioTitolo) {
                if molte {
                    Button(tutte ? TestiCompletezza.mostraMeno : TestiCompletezza.mostraTutte(k.daCompletare.count)) {
                        tutte.toggle()
                    }
                    .buttonStyle(.appleSobrio)
                }
                Spacer(minLength: 0)
                if !k.escluse.isEmpty {
                    Text(TestiCompletezza.escluse(k.escluse.count))
                        .carattereApple(p.piede)
                        .foregroundColor(p.colorePiede)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Button(TestiCompletezza.ripristina) { stato.ripristinaDatiNonPertinenti(cliente.id) }
                        .buttonStyle(.appleSobrio)
                        .help(TestiCompletezza.aiutoRipristina)
                        .disabled(stato.solaLettura)
                }
            }
            .padding(.top, p.sopraPiede)
        }
    }
}

/// Una voce da completare come riga `.prep`: il pallino vuoto, il titolo (l'ipotesi usata al passaggio del
/// puntatore), il canale della posizione se c'è, «Completa» e la croce «non pertinente»; un filo sotto.
struct VoceDaCompletareApple: View {
    let voce: VoceCompletezza
    let completa: () -> Void
    let escludi: () -> Void
    let solaLettura: Bool

    var body: some View {
        let p = Tema.Apple.Clienti.Panoramica.self
        return HStack(alignment: .center, spacing: p.spazioVoce) {
            Circle()
                .strokeBorder(p.colorePallino, lineWidth: p.bordoPallino)
                .frame(width: p.pallino, height: p.pallino)
                .help(voce.stato.nome)
            // Il titolo prende tutta la larghezza per le sue due righe; il canale va sotto
            VStack(alignment: .leading, spacing: p.sottoTitoloVoce) {
                Text(voce.titolo)
                    .carattereApple(p.voce)
                    .foregroundColor(p.coloreVoce)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(voce.ipotesi.isEmpty ? voce.perche : voce.ipotesi)
                if let canale = voce.canale {
                    EtichettaCanaleApple(canale: canale, compatta: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            Button(TestiCompletezza.completa, action: completa)
                .buttonStyle(.apple)
                .fixedSize()
                .help(TestiCompletezza.aiutoCompleta)
            Button(action: escludi) {
                Image(systemName: "xmark")
                    .font(p.croce.font)
                    .foregroundColor(p.coloreCroce)
                    .frame(width: p.latoCroce, height: p.latoCroce)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StileSemplice())
            .disabled(solaLettura)
            .help(TestiCompletezza.aiutoNonPertinente)
            .accessibilityLabel(TestiCompletezza.aiutoNonPertinente)
        }
        .padding(.vertical, p.paddingVoce)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(p.filo)
                .frame(height: Tema.Apple.Misura.bordo)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Da ricordare

/// «Da ricordare»: la nota del cliente 15 con interlinea 1,5. Senza nota, una riga che porta alla scheda Note.
struct DaRicordareApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Clienti.Panoramica.self
        let nota = cliente.nota.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: p.sottoTitolo) {
            Text("Da ricordare")
                .carattereApple(p.titolo)
                .foregroundColor(p.coloreTitolo)
            if nota.isEmpty {
                Text("Niente da ricordare, per ora.")
                    .carattereApple(p.nota)
                    .foregroundColor(p.notaVuota)
                Button("Scrivi una nota ›") { stato.schedaCliente = .note }
                    .buttonStyle(.appleSobrio)
                    .disabled(stato.solaLettura)
            } else {
                Text(nota)
                    .carattereApple(p.nota)
                    .foregroundColor(p.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(p.paddingLaterali)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(p.superficie)
    }
}

// MARK: - Prossimo incontro

/// «Prossimo incontro»: data 21 bold, titolo 14 e «Apri in Agenda ›»; tutta la card apre l'Agenda sul giorno
/// dell'incontro e si inclina di 5° sotto il puntatore. Senza incontri in programma apre l'Agenda del cliente.
struct ProssimoIncontroApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    let appuntamento: Appuntamento?

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Clienti.Panoramica.self
        return Button(action: apri) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Prossimo incontro")
                    .carattereApple(p.titolo)
                    .foregroundColor(p.coloreTitolo)
                Text(appuntamento.map(Self.quando) ?? "Nessun incontro in programma")
                    .carattereApple(p.dataIncontro)
                    .foregroundColor(p.coloreData)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, p.sopraData)
                if let a = appuntamento {
                    Text(a.titolo)
                        .carattereApple(p.titoloIncontro)
                        .foregroundColor(p.coloreTitoloIncontro)
                        .lineLimit(2)
                }
                Text(appuntamento == nil ? "Fissa un incontro in Agenda ›" : "Apri in Agenda ›")
                    .carattereApple(p.collegamento)
                    .foregroundColor(p.coloreCollegamento)
                    .padding(.top, p.sopraCollegamento)
                Spacer(minLength: 0)
            }
            .padding(p.paddingLaterali)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .superficieApple(p.superficie)
            .contentShape(RoundedRectangle(cornerRadius: p.raggio, style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .inclinazione(massimo: p.inclinazioneIncontro, raggio: p.raggio)
        .accessibilityHint("Apre l'Agenda")
    }

    /// «Oggi, 09:30», «Domani, 10:00» o «Gio 12 nov, 10:00».
    static func quando(_ a: Appuntamento) -> String {
        let cal = Calendar.current
        let giorno: String
        if cal.isDateInToday(a.inizio) {
            giorno = "Oggi"
        } else if cal.isDateInTomorrow(a.inizio) {
            giorno = "Domani"
        } else {
            let testo = Formati.barraData.string(from: a.inizio)
            giorno = testo.prefix(1).uppercased() + testo.dropFirst()
        }
        return giorno + ", " + Formati.ora.string(from: a.inizio)
    }

    private func apri() {
        if let a = appuntamento {
            stato.mostraInAgenda(a)
        } else {
            stato.clienteAttivoId = cliente.id
            stato.filtroClienteAgenda = cliente.id
            stato.apri(.agenda)
        }
    }
}
