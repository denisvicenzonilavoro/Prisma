#if os(iOS)
import SwiftUI

// Il simulatore dell'iPhone (13 novembre 2026, giro 5 dell'iPhone): «una cosa principale grande in alto» — quanto si
// incassa netto alla fine nello scenario atteso — poi i tre scenari (quelli del KID quando la scheda li ha, altrimenti
// ±2 punti), il grafico e le ipotesi da cambiare. Gli stessi motori del Mac (MotoreProiezione); niente si salva.
// Da Simulazioni (ipotesi libere o da un prodotto del catalogo) e da «Simula» nel dettaglio di una posizione.

private typealias E = Tema.Apple.Telefono.Elenco
private typealias S = Tema.Apple.Telefono.Simulatore

struct SimulatoreTelefono: View {
    @Environment(StatoShell.self) var stato
    /// La posizione da simulare (nil: ipotesi libere).
    var posizioneId: String?

    @State private var capitale = S.capitale
    @State private var mensile = S.mensile
    @State private var anni = S.anni
    @State private var rendimento = IpotesiCalcolo.rendimentoPredefinito
    @State private var costoIngresso: Double = 0
    @State private var costoAnnuo: Double = 0
    @State private var aliquota = IpotesiCalcolo.aliquotaPredefinita
    @State private var scartiKID: [Double]?
    @State private var prodottoId: String?
    @State private var avviato = false

    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.italiano)

    var body: some View {
        let _ = ContaCorpi.segna()
        let par = parametri
        let scenari = MotoreProiezione.scenari(par)
        let atteso = scenari.count > 1 ? scenari[1].esito : MotoreProiezione.calcola(par)
        FondoTelefono {
            // La cosa principale: il netto atteso alla fine
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(titolo).carattereApple(E.dettaglio).foregroundColor(E.coloreDettaglio)
                NumeroCheConta(atteso.netto, formato: .euro)
                    .carattereApple(E.cifra)
                    .foregroundColor(E.coloreNome)
                    .lineLimit(1)
                    .minimumScaleFactor(Tema.Apple.Telefono.Posizioni.riduzioneTotale)
                Text("netti tra \(par.anni) anni · versati \(Formati.euro(atteso.versato))")
                    .carattereApple(E.dettaglio).foregroundColor(E.coloreDettaglio)
            }
            .pannelloTelefono()
            .entrataCascata(0)

            SezioneTelefono(titolo: par.scartiKID != nil ? "Gli scenari del KID" : "Tre scenari")
            VStack(spacing: E.spazioRiga) {
                ForEach(Array(scenari.enumerated()), id: \.offset) { _, s in
                    HStack {
                        Circle().fill(colore(s.nome)).frame(width: E.spazioRiga, height: E.spazioRiga)
                        Text(s.nome).carattereApple(E.nome).foregroundColor(E.coloreNome)
                        Text("\(Formati.percentuale(s.rendimento)) lordo").carattereApple(E.dettaglio).foregroundColor(E.coloreDettaglio)
                        Spacer(minLength: 0)
                        Text(Formati.euro(s.esito.netto)).carattereApple(E.valore).foregroundColor(E.coloreNome)
                    }
                }
            }
            .schedaTelefono()
            .entrataCascata(1)

            GraficoProiezione(serie: scenari.enumerated().map { (i, s) -> GraficoProiezione.Serie in
                GraficoProiezione.Serie(id: s.nome, punti: s.esito.punti, colore: colore(s.nome), principale: i == 1)
            })
            .frame(height: S.altezzaGrafico)
            .schedaTelefono()
            .entrataCascata(2)

            SezioneTelefono(titolo: "Dove vanno i soldi")
            VStack(alignment: .leading, spacing: E.spazioRiga) {
                DatoTelefono("Versato", Formati.euro(atteso.versato))
                DatoTelefono("Costi", Formati.euro(atteso.costi))
                DatoTelefono("Imposte", Formati.euro(atteso.imposte))
                DatoTelefono("In euro di oggi", Formati.euro(atteso.reale))
            }
            .schedaTelefono()

            if posizioneId == nil { ipotesi }
            else {
                SezioneTelefono(titolo: "Durata")
                Stepper("\(anni) anni", value: $anni, in: 1...S.anniMassimi)
                    .schedaTelefono()
            }
            Text("Proiezione con i motori di Prisma: rendimenti lordi annui, costi e imposte della scheda; non è una promessa di rendimento.")
                .carattereApple(E.dettaglio).foregroundColor(E.coloreTerziario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .navigationTitle(posizioneId == nil ? "Simulazioni" : "Simula")
        .onAppear(perform: avvia)
    }

    // MARK: - Le ipotesi

    @ViewBuilder private var ipotesi: some View {
        SezioneTelefono(titolo: "Le ipotesi")
        VStack(alignment: .leading, spacing: E.spazioRiga) {
            Picker("Dal prodotto", selection: Binding(get: { prodottoId }, set: { scegliProdotto($0) })) {
                Text("Ipotesi libere").tag(String?.none)
                ForEach(stato.dati.prodotti.filter { $0.area.proiettabile }) { p in Text(p.nome).tag(Optional(p.id)) }
            }
            campo("Capitale iniziale", $capitale, unita: "€")
            campo("Versamento mensile", $mensile, unita: "€")
            Stepper("Durata: \(anni) anni", value: $anni, in: 1...S.anniMassimi)
            campo("Rendimento lordo", $rendimento, unita: "% l'anno")
            campo("Costo d'ingresso", $costoIngresso, unita: "%")
            campo("Costo annuo", $costoAnnuo, unita: "% l'anno")
            campo("Imposte sul guadagno", $aliquota, unita: "%")
        }
        .schedaTelefono()
    }

    private func campo(_ etichetta: String, _ valore: Binding<Double>, unita: String) -> some View {
        HStack {
            Text(etichetta).carattereApple(E.nome).foregroundColor(E.coloreNome)
            Spacer()
            TextField("0", value: valore, format: Self.numero)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: S.colonnaCifra)
            Text(unita).carattereApple(E.dettaglio).foregroundColor(E.coloreDettaglio)
        }
    }

    private func scegliProdotto(_ id: String?) {
        prodottoId = id
        guard let p = stato.dati.prodotti.first(where: { $0.id == id }) else {
            scartiKID = nil
            return
        }
        var q = ParametriProiezione(posizione: p.proposta(per: stato.clienteAttivoId))
        q.anni = anni
        rendimento = q.rendimento
        costoIngresso = q.costoIngresso
        costoAnnuo = q.costoAnnuo
        aliquota = q.aliquotaFiscale
        scartiKID = p.scartiScenariKID
        if let a = p.periodoConsigliato { anni = a }
    }

    // MARK: - I parametri

    private var posizione: Posizione? { posizioneId.flatMap { id in stato.posizioni.first { $0.id == id } } }

    private var titolo: String {
        if let p = posizione { return "\(p.nome) · scenario atteso" }
        if let id = prodottoId, let p = stato.dati.prodotti.first(where: { $0.id == id }) { return "\(p.nome) · scenario atteso" }
        return "Scenario atteso"
    }

    private var parametri: ParametriProiezione {
        if let p = posizione {
            var q = ParametriProiezione(posizione: p)
            q.anni = anni
            return q
        }
        var q = ParametriProiezione(capitaleIniziale: max(0, capitale), versamento: max(0, mensile), frequenza: .mensile,
                                    anni: anni, rendimento: rendimento, costoIngresso: costoIngresso, costoAnnuo: costoAnnuo,
                                    aliquotaFiscale: aliquota)
        q.scartiKID = scartiKID
        return q
    }

    private func avvia() {
        guard !avviato else { return }
        avviato = true
        if let p = posizione { anni = ParametriProiezione(posizione: p).anni }
    }

    private func colore(_ nome: String) -> Color {
        switch nome {
        case "Prudente": return S.colorePrudente
        case "Favorevole": return S.coloreFavorevole
        default: return S.coloreAtteso
        }
    }
}
#endif
