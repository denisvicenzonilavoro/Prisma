import SwiftUI

// «Ragiona a passi» sotto la risposta di Vera (Design/template-vera.html, «20 · Ragiona a passi»): la scheda «Il piano
// di Vera» con i passi (il pallino si riempie e diventa verde con la spunta, uno alla volta), le tre colonne delle
// divisioni con le barre protezione/obiettivi e «Vera consiglia» sulla scelta (anello rubino), la regola e da dove viene
// il piano. L'interruttore «Mostra il ragionamento» nasconde il piano e la regola: restano le divisioni e la spiegazione.
// Movimento: i passi si accendono a cascata, poi entrano le colonne e le barre si riempiono; con «Riduci movimento» e
// nelle istantanee tutto è già fermo nello stato finale. Un piano rivisto più tardi (riaprendo la conversazione) non
// si rianima.

private typealias F = Tema.Apple.FaseTreVera
private typealias R = Tema.Apple.RagionaPassi

/// La scheda del ragionamento a passi sotto la risposta di Vera.
struct PianoPassiVeraVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    let piano: PianoPassi
    /// L'id del messaggio di Vera (per «Rifai i calcoli» nella stessa conversazione).
    var messaggio: String? = nil

    @State private var acceso = false

    /// Già nello stato finale: istantanee, «Riduci movimento», oppure un piano rivisto più tardi.
    private var subito: Bool {
        fermo || Date().timeIntervalSince(piano.creatoIl) > R.finestraAnimazione || piano.creatoIl > Date().addingTimeInterval(R.finestraAnimazione)
    }

    private var visto: Bool { acceso || subito }

    var body: some View {
        let _ = ContaCorpi.segna()
        if stato.visibileAlCliente(piano.richiesta.clienteId) {
            let mostra = stato.dati.impostazioni.vera.passi.mostraRagionamento
            VStack(alignment: .leading, spacing: R.spazio) {
                HStack(spacing: R.spazioPiccolo) {
                    Spacer(minLength: 0)
                    Text("Mostra il ragionamento").carattereApple(R.nota).foregroundColor(F.coloreDettaglio)
                    Toggle("", isOn: Bindable(stato.dati).impostazioni.vera.passi.mostraRagionamento)
                        .toggleStyle(.switch).labelsHidden().controlSize(.small)
                        .accessibilityLabel(Text("Mostra il ragionamento"))
                }
                if mostra {
                    SchedaPianoPassi(passi: piano.passi, conQwen: piano.conQwen, visto: visto, animazione: animazionePasso)
                        .transition(.opacity)
                }
                if !piano.divisioni.isEmpty {
                    ColonneDivisioniPassi(piano: piano, visto: visto, animazione: animazioneColonna)
                }
                if mostra {
                    Text("La regola: \(PassiVera.regola)")
                        .carattereApple(R.nota).foregroundColor(F.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                }
                piede
            }
            .padding(.top, F.sopraScheda)
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(R.durataColonna), calmo: calmo, istantanea: fermo), value: mostra)
            .onAppear { if !subito { acceso = true } }
            .accessibilityElement(children: .contain)
        }
    }

    /// L'animazione del passo `i`: uno dopo l'altro (niente con le istantanee, dissolvenza breve con «Riduci movimento»).
    private func animazionePasso(_ i: Int) -> Animation? {
        guard !subito else { return nil }
        return Tema.Apple.Moto.animazione(Tema.Apple.Moto.molla(R.durataPasso), calmo: calmo)
            .ritardoPrisma(Tema.Apple.Moto.ritardo(R.ritardoPrimo + Double(i) * R.ritardoPasso, calmo: calmo))
    }

    /// L'animazione della colonna `j`: dopo l'ultimo passo, ogni colonna un poco dopo la precedente.
    private func animazioneColonna(_ j: Int) -> Animation? {
        guard !subito else { return nil }
        let dopoPassi = stato.dati.impostazioni.vera.passi.mostraRagionamento ? R.ritardoPrimo + Double(piano.passi.count) * R.ritardoPasso : 0
        return Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(R.durataColonna), calmo: calmo)
            .ritardoPrisma(Tema.Apple.Moto.ritardo(dopoPassi + Double(j) * R.ritardoColonna, calmo: calmo))
    }

    private var piede: some View {
        HStack(spacing: R.spazioPiccolo) {
            Text(origine).carattereApple(R.nota).foregroundColor(F.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: R.spazioPiccolo)
            if stato.cliente(piano.richiesta.clienteId) != nil {
                Button("Apri gli obiettivi") { stato.apriObiettiviPassi(piano) }
                    .buttonStyle(.apple).fixedSize()
                if !stato.solaLettura {
                    Button("Rifai i calcoli") { stato.rifaiPassi(piano, chiave: stato.chiaveConversazione) }
                        .buttonStyle(.apple).fixedSize()
                        .disabled(stato.veraInCorso)
                        .help("La stessa richiesta con i dati di adesso")
                }
            }
        }
    }

    private var origine: String {
        var parti = [piano.conQwen ? "Piano proposto da Qwen e controllato da Prisma" : "Piano delle regole di Prisma",
                     "cifre del simulatore di Prisma"]
        if piano.spiegazioneConQwen { parti.append("spiegazione di Qwen con le cifre di Prisma") }
        return parti.joined(separator: " · ")
    }
}

// MARK: - Il piano

/// «Il piano di Vera»: i passi con il pallino (vuoto da fare, verde con la spunta quando è fatto) e l'esito di Prisma.
struct SchedaPianoPassi: View {
    let passi: [PassoPiano]
    let conQwen: Bool
    /// Il piano è stato eseguito (anche nella vista: i pallini si accendono).
    let visto: Bool
    let animazione: (Int) -> Animation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: R.spazioPiccolo) {
                SferaVera(misura: R.sfera, viva: false)
                Text("Il piano di Vera").carattereApple(R.titoloScheda).lineLimit(1)
                Spacer(minLength: 0)
                PillolaFaseTre(testo: passi.count == 1 ? "1 passo" : "\(passi.count) passi", colore: F.neutro)
            }
            .padding(.bottom, R.sottoTitolo)
            ForEach(Array(passi.enumerated()), id: \.element.id) { i, p in
                riga(p, ultima: i == passi.count - 1)
                    .animation(animazione(i), value: visto)
            }
        }
        .padding(R.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    private func riga(_ p: PassoPiano, ultima: Bool) -> some View {
        let fatto = visto && p.stato != .daFare
        return HStack(alignment: .top, spacing: R.spazioRiga) {
            PallinoPassoVera(fatto: fatto, saltato: p.stato == .saltato)
            VStack(alignment: .leading, spacing: R.sottoTitoloPasso) {
                Text(p.titolo).carattereApple(R.titoloPasso).fixedSize(horizontal: false, vertical: true)
                if fatto && !p.esito.isEmpty {
                    Text(p.esito).carattereApple(R.esitoPasso).foregroundColor(F.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
                Text(p.strumento.motore).carattereApple(R.motorePasso).foregroundColor(Tema.Apple.passiConsiglia)
            }
            Spacer(minLength: 0)
        }
        .padding(R.paddingPasso)
        .opacity(fatto ? 1 : R.opacitaDaFare)
        .overlay(alignment: .bottom) {
            if !ultima { Rectangle().fill(Tema.Apple.Colore.separatore).frame(height: R.filo) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(fatto ? "fatto" : "da fare"))
    }
}

/// Il pallino del passo: il cerchio del binario da fare, verde pieno con la spunta quando è fatto.
private struct PallinoPassoVera: View {
    let fatto: Bool
    var saltato = false

    var body: some View {
        ZStack {
            Circle().strokeBorder(Tema.Apple.passiBinario, lineWidth: R.bordoPallino)
            Circle().fill(saltato ? F.neutro : Tema.Apple.passiFatto)
                .scaleEffect(fatto ? R.scalaPallinoFatto : R.scalaPallinoVuoto)
                .opacity(fatto ? 1 : 0)
            Image(systemName: saltato ? "minus" : "checkmark")
                .font(R.spunta.font)
                .foregroundColor(.white)
                .opacity(fatto ? 1 : 0)
        }
        .frame(width: R.pallino, height: R.pallino)
        .padding(.top, R.sopraPallino)
        .accessibilityHidden(true)
    }
}

// MARK: - Le divisioni

/// Le tre colonne delle divisioni: le barre di ogni voce sul budget, «Vera consiglia» sulla scelta, cosa succede alla
/// protezione e quando arrivano gli obiettivi (i testi del motore, con le cifre di Prisma).
struct ColonneDivisioniPassi: View {
    let piano: PianoPassi
    let visto: Bool
    let animazione: (Int) -> Animation?

    var body: some View {
        HStack(alignment: .top, spacing: R.spazioColonne) {
            ForEach(Array(piano.divisioni.enumerated()), id: \.element.id) { j, d in
                ColonnaDivisionePassi(divisione: d, richiesta: piano.richiesta, consigliata: d.tipo == piano.consigliata,
                                      regge: piano.regge, visto: visto)
                    .animation(animazione(j), value: visto)
            }
        }
    }
}

struct ColonnaDivisionePassi: View {
    let divisione: DivisioneBudget
    let richiesta: RichiestaPassi
    let consigliata: Bool
    /// La consigliata regge su tutti gli obiettivi (false: è la meno scoperta).
    let regge: Bool
    let visto: Bool

    var body: some View {
        let d = divisione
        VStack(alignment: .leading, spacing: R.spazioColonna) {
            HStack(alignment: .firstTextBaseline, spacing: R.spazioPiccolo) {
                Text(d.titolo).carattereApple(R.titoloColonna).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if consigliata {
                    PillolaFaseTre(testo: regge ? "Vera consiglia" : "La meno scoperta", colore: Tema.Apple.passiConsiglia)
                }
            }
            if richiesta.protezione {
                barra(etichetta: richiesta.protetta == "la famiglia" ? "Protezione della famiglia" : "Protezione per \(richiesta.protetta)",
                      valore: d.protezioneMensile, colore: Tema.Apple.passiProtezione)
            }
            ForEach(Array(d.quote.enumerated()), id: \.element.obiettivoId) { k, q in
                barra(etichetta: q.titolo, valore: q.mensile, colore: Self.coloreObiettivo(k))
            }
            VStack(alignment: .leading, spacing: R.spazioEsiti) {
                if let p = PassiVera.testoProtezione(d, richiesta) {
                    Text(Self.maiuscola(p)).carattereApple(R.esitoForte).fixedSize(horizontal: false, vertical: true)
                }
                ForEach(d.quote, id: \.obiettivoId) { q in
                    HStack(alignment: .firstTextBaseline, spacing: R.spazioPiccolo) {
                        Circle().fill(q.inTempo ? Tema.Apple.passiFatto : Tema.Apple.passiVincolo)
                            .frame(width: R.puntoEsito, height: R.puntoEsito)
                        Text(PassiVera.testoObiettivo(q)).carattereApple(R.esito).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, R.sopraEsiti)
        }
        .padding(R.paddingColonna)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
        .overlay {
            if consigliata {
                RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                    .strokeBorder(Tema.Apple.passiConsiglia, lineWidth: R.anelloConsigliata)
            }
        }
        .opacity(visto ? 1 : R.opacitaColonnaPrima)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(consigliata ? .isSelected : [])
    }

    /// La barra di una voce: la parte del budget mensile (o del capitale una tantum), con la cifra a destra.
    private func barra(etichetta: String, valore: Double, colore: Color) -> some View {
        let parte = richiesta.totale > 0 ? max(0, min(1, valore / richiesta.totale)) : 0
        return VStack(alignment: .leading, spacing: R.sottoEtichetta) {
            Text(etichetta).carattereApple(R.etichettaBarra).foregroundColor(F.coloreDettaglio).lineLimit(1)
            HStack(spacing: R.spazioPiccolo) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous).fill(Tema.Apple.passiBinario)
                        Capsule(style: .continuous).fill(colore)
                            .frame(width: g.size.width * (visto ? parte : 0))
                    }
                }
                .frame(height: R.altezzaBarra)
                Text(CifreDoc.euro(valore)).carattereApple(R.cifraBarra)
                    .lineLimit(1).fixedSize()
                    .frame(minWidth: R.larghezzaCifra, alignment: .trailing)
            }
        }
    }

    /// Il colore del k-esimo obiettivo (al massimo tre nella richiesta).
    static func coloreObiettivo(_ k: Int) -> Color {
        switch k {
        case 0: return Tema.Apple.passiObiettivo
        case 1: return Tema.Apple.passiObiettivoDue
        default: return Tema.Apple.passiObiettivoTre
        }
    }

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
}

// MARK: - Impostazioni › Vera

/// Le due righe di «Ragiona a passi» in Impostazioni › Vera (per chi non usa le righe della pagina).
struct InterruttoriPassiVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        VStack(alignment: .leading, spacing: R.spazioPiccolo) {
            Toggle("Ragiona a passi", isOn: Bindable(stato.dati).impostazioni.vera.passi.attivo)
                .toggleStyle(.switch)
            Toggle("Mostra il ragionamento", isOn: Bindable(stato.dati).impostazioni.vera.passi.mostraRagionamento)
                .toggleStyle(.switch)
                .disabled(!stato.dati.impostazioni.vera.passi.attivo)
        }
    }
}
