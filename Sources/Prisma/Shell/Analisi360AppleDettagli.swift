import SwiftUI

// Analisi 360 › i dettagli che nascono dalle card Investimenti (900×480) e Risparmio e liquidità (900×440)
// nel tema Apple (Design/template-apple-specifica.md §4.3.4, §4.3.5, riferimenti analisi-agenda/A17-A22).
// - Investimenti: «Come lavorano i suoi risparmi»: la barra di composizione che si riempie (azionario,
//   obbligazionario, gestione separata, liquidità, dalle posizioni in essere con MotoreResistenza.composizione),
//   quattro tile con la quota che si conta e gli euro di ciascun canale, poi coerenza con il profilo, profilo di
//   rischio con l'SRI medio e costo medio l'anno (MotoreCosti, dalle posizioni: non l'1,4% fisso del template).
// - Risparmio e liquidità: «Quanti mesi può stare tranquillo/a senza entrate» (accordato al genere dal codice
//   fiscale), i blocchi dei mesi con la soglia delle ipotesi, mesi di spese da parte (con la virgola), spese mensili
//   e liquidità sui conti dalle ipotesi e dalle posizioni (non i 2.300 € fissi del template).
// - Sotto i risultati le ipotesi, sempre scritte; nel piede «Salva come proposta» sul canale scelto (le proposte
//   di Prisma per l'area, MotoreSintesi.calcolaProposte), «Chiedi a Vera di spiegarlo»; in alto «Apri l'analisi
//   completa ›» porta al pannello di sempre.
// Le cifre vengono da MotoreAree360 (in cache, CacheAree360). Valori in DesignSystem/Apple/Tema.Apple+Aree360.swift.

// MARK: - Investimenti

struct DettaglioInvestimentiApple: View {
    @Environment(StatoShell.self) var stato
    @EnvironmentObject var cache: CacheAree360
    let cliente: Cliente
    @State private var canale: Canale

    init(cliente: Cliente) {
        self.cliente = cliente
        _canale = State(initialValue: canaleProposta360(cliente))
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let d = Tema.Apple.Aree360.Dettaglio.self
        let c = Tema.Apple.Aree360.Composizione.self
        let k = cache.aree(stato, cliente: cliente.id).composizione
        return VStack(alignment: .leading, spacing: 0) {
            TestataDettaglioArea360(area: .investimenti, nome: cliente.nome, titolo: "Come lavorano i suoi risparmi")
            if k.vuota {
                Text("Nessuna posizione finanziaria in essere: aggiungile in Posizioni per vedere come lavorano i risparmi.")
                    .carattereApple(d.vuoto)
                    .foregroundColor(d.coloreVuoto)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, d.vuotoSopra)
            } else {
                BarraPienaSegmenti.composizione(pezziBarra(k), indice: c.indiceBarra)
                    .padding(.top, c.barraSopra)
                    .padding(.bottom, c.barraSotto)
                HStack(alignment: .top, spacing: c.spazioTile) {
                    ForEach(Array(k.pezzi.enumerated()), id: \.element.id) { i, p in
                        tile(p, indice: i)
                    }
                }
                cifre(k)
                    .padding(.top, d.cifreSopra)
            }
            Spacer(minLength: 0)
            IpotesiDettaglioArea360(testo: ipotesi(k))
            PiedeDettaglioArea360(area: .investimenti, canale: $canale)
                .padding(.top, d.piedeSopra)
        }
    }

    private func pezziBarra(_ k: ComposizioneInvestimenti360) -> [PezzoBarraPiena] {
        let c = Tema.Apple.Aree360.Composizione.self
        return k.pezzi.map { PezzoBarraPiena(id: $0.id, peso: $0.quota, colore: c.colore($0.classe)) }
    }

    /// Una tile: pallino e nome della classe, la quota che si conta e gli euro per canale (nel colore del canale).
    private func tile(_ p: ComposizioneInvestimenti360.Pezzo, indice: Int) -> some View {
        let d = Tema.Apple.Aree360.Dettaglio.self
        let c = Tema.Apple.Aree360.Composizione.self
        let canali = Canale.allCases.filter { (p.perCanale[$0] ?? 0) >= 0.5 }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: c.spazioPallino) {
                Circle()
                    .fill(c.colore(p.classe))
                    .frame(width: c.pallino, height: c.pallino)
                Text(p.classe.nome)
                    .carattereApple(d.etichettaCifra)
                    .foregroundColor(d.coloreEtichettaCifra)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            NumeroCheConta(p.quota, formato: .percentuale, indice: indice)
                .carattereApple(c.quota)
                .foregroundColor(d.coloreCifra)
                .lineLimit(1)
                .padding(.top, c.quotaSopra)
            VStack(alignment: .leading, spacing: c.spazioCanali) {
                if canali.isEmpty {
                    Text("Nessuna posizione")
                        .carattereApple(c.canale)
                        .foregroundColor(c.coloreNessuno)
                }
                ForEach(canali) { k in
                    Text("\(k.nomeBreve) \(Formati.euro(p.perCanale[k] ?? 0))")
                        .carattereApple(c.canale)
                        .foregroundColor(coloreCanale360(k))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.top, c.canaleSopra)
        }
        .padding(c.paddingTile)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .superficieApple(c.superficieTile)
    }

    /// Coerenza con il profilo, profilo di rischio, SRI medio e costo medio l'anno.
    private func cifre(_ k: ComposizioneInvestimenti360) -> some View {
        let d = Tema.Apple.Aree360.Dettaglio.self
        let costo = Self.costoMedio(stato.posizioniCliente(cliente.id))
        let profilo = k.propensione?.nome ?? "Da rilevare"
        let sri = k.sriMedio.map { "\(TestiAree360.decimale($0)) su 7" }
        let titoloSri = k.sriMassimo.map { "SRI medio · massimo \($0)" } ?? "SRI medio"
        return HStack(alignment: .top, spacing: d.spazioCifre) {
            CifraDettaglioArea360(titolo: "Coerenza con il profilo", valore: k.entroProfilo.map(MotoreAree360.quotaEntroProfilo), formato: .percentuale, indice: 4,
                                  aiuto: "Quota del capitale di investimento con un SRI entro il massimo del profilo")
            CifraDettaglioArea360(titolo: "Profilo di rischio", testo: profilo)
            CifraDettaglioArea360(titolo: titoloSri, testo: sri ?? "—",
                                  aiuto: "SRI medio delle posizioni di investimento, pesato sul valore")
            CifraDettaglioArea360(titolo: "Costo medio l'anno",
                                  testo: costo.map { Formati.percentuale(($0 * 100).rounded() / 100) } ?? "—",
                                  aiuto: "Costo annuo pesato sul valore delle posizioni con i costi indicati")
            Spacer(minLength: 0)
        }
    }

    /// Il costo annuo medio pesato sul valore: lo stesso `AnalisiCosti.costoMedio` di `MotoreCosti.calcola` (posizioni
    /// finanziarie in essere con valore e con i costi indicati), senza le proiezioni e le alternative del catalogo che
    /// l'analisi completa del dossier calcola per ogni posizione: qui serve solo la media, mentre il dettaglio si apre.
    static func costoMedio(_ posizioni: [Posizione]) -> Double? {
        let voci = posizioni.filter { p in
            p.stato == .inEssere && p.area.proiettabile && p.valore > 0 && (p.costoComplessivo != nil || p.costoIngresso != nil)
        }
        let valore = voci.reduce(0) { $0 + $1.valore }
        return valore > 0 ? voci.reduce(0) { $0 + ($1.costoComplessivo ?? 0) * $1.valore } / valore : nil
    }

    private func ipotesi(_ k: ComposizioneInvestimenti360) -> String {
        var t = "Posizioni finanziarie in essere per \(Formati.euro(k.totale))"
        let canali = Canale.allCases.compactMap { c -> String? in
            guard let v = k.perCanale[c], v >= 0.5 else { return nil }
            return "\(c.nomeBreve) \(Formati.euro(v))"
        }
        if !canali.isEmpty { t += " (" + canali.joined(separator: ", ") + ")" }
        t += ": quote indicate nelle posizioni"
        t += k.stimata ? " o, dove mancano, stimate dalla tipologia e dall'SRI." : "."
        t += " Coerenza: capitale di investimento con SRI entro il massimo del profilo (prudente 2, moderata 3, dinamica 5, aggressiva 7)."
        t += " Costo medio pesato sul valore delle posizioni con i costi indicati."
        return t
    }
}

// MARK: - Risparmio e liquidità

struct DettaglioLiquiditaApple: View {
    @Environment(StatoShell.self) var stato
    @EnvironmentObject var cache: CacheAree360
    let cliente: Cliente
    @State private var canale: Canale

    init(cliente: Cliente) {
        self.cliente = cliente
        _canale = State(initialValue: canaleProposta360(cliente))
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let d = Tema.Apple.Aree360.Dettaglio.self
        let l = cache.aree(stato, cliente: cliente.id).liquidita
        return VStack(alignment: .leading, spacing: 0) {
            TestataDettaglioArea360(area: .risparmio, nome: cliente.nome, titolo: TestiAree360.titoloLiquidita(cliente))
            if let mesi = l.mesi {
                mesiDaParte(mesi, l)
            } else {
                Text("Indica il fabbisogno mensile nelle ipotesi di protezione: da lì Prisma conta i mesi di spese da parte.")
                    .carattereApple(d.vuoto)
                    .foregroundColor(d.coloreVuoto)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, d.vuotoSopra)
            }
            cifre(l)
                .padding(.top, d.cifreSopra)
            Spacer(minLength: 0)
            IpotesiDettaglioArea360(testo: ipotesi(l))
            PiedeDettaglioArea360(area: .risparmio, canale: $canale)
                .padding(.top, d.piedeSopra)
        }
    }

    /// 12 blocchi (o tanti quanti i mesi della soglia, fino a 24) e la riga «1 mese · soglia · 12 mesi».
    private func mesiDaParte(_ mesi: Double, _ l: Liquidita360) -> some View {
        let m = Tema.Apple.Aree360.Mesi.self
        let blocchi = min(m.blocchiMassimi, max(m.blocchi, l.soglia))
        return VStack(alignment: .leading, spacing: 0) {
            BlocchiMesi(mesi: mesi, blocchi: blocchi)
                .padding(.top, m.sopra)
                .padding(.bottom, m.sotto)
            HStack(spacing: 0) {
                Text("1 mese")
                    .carattereApple(m.etichetta)
                    .foregroundColor(m.coloreEtichetta)
                Spacer(minLength: 0)
                Text("soglia delle ipotesi: \(l.soglia) \(l.soglia == 1 ? "mese" : "mesi")")
                    .carattereApple(m.soglia)
                    .foregroundColor(m.coloreSoglia)
                Spacer(minLength: 0)
                Text("\(blocchi) mesi")
                    .carattereApple(m.etichetta)
                    .foregroundColor(m.coloreEtichetta)
            }
            .lineLimit(1)
        }
    }

    /// Mesi di spese da parte, spese mensili e liquidità sui conti, con i canali dei conti a destra.
    private func cifre(_ l: Liquidita360) -> some View {
        let d = Tema.Apple.Aree360.Dettaglio.self
        let canali = Canale.allCases.filter { (l.perCanale[$0] ?? 0) >= 0.5 }
        return HStack(alignment: .bottom, spacing: d.spazioCifre) {
            CifraDettaglioArea360(titolo: "Mesi di spese da parte", valore: l.mesi, formato: .mesi, indice: 0)
            CifraDettaglioArea360(titolo: "Spese mensili", valore: l.speseMensili, formato: .euro, indice: 1)
            CifraDettaglioArea360(titolo: "Liquidità sui conti", valore: l.liquidita, formato: .euro, indice: 2)
            Spacer(minLength: 0)
            HStack(spacing: Tema.Apple.Misura.Spazio.etichettaCanale) {
                ForEach(canali) { c in
                    EtichettaCanaleApple(canale: c, compatta: true)
                }
            }
        }
    }

    private func ipotesi(_ l: Liquidita360) -> String {
        var t = "Mesi = liquidità sui conti in essere diviso il fabbisogno mensile delle ipotesi di protezione (\(Formati.euro(l.speseMensili)) al mese)"
        t += "; soglia = i mesi di riserva delle ipotesi (\(l.soglia)), riserva di \(Formati.euro(l.riservaNecessaria))."
        if l.inScadenza >= 0.5 {
            t += " Capitali in scadenza entro \(l.mesiFinestraScadenze) mesi: \(Formati.euro(l.inScadenza)) netti, non contano nei mesi."
        }
        if l.eccedenza >= 0.5 { t += " Oltre la riserva, tra conti e scadenze: \(Formati.euro(l.eccedenza))." }
        return t
    }
}

// MARK: - Pezzi comuni dei due dettagli

/// Il canale con cui nasce la proposta: Alleanza se il cliente ce l'ha (o non ne ha nessuno), altrimenti il suo.
private func canaleProposta360(_ c: Cliente) -> Canale {
    c.canali.contains(.alleanza) || c.canali.isEmpty ? .alleanza : c.canali[0]
}

/// Il colore del testo di un canale (blu Alleanza, cuoio indipendente).
private func coloreCanale360(_ c: Canale) -> Color {
    c == .alleanza ? Tema.Apple.Colore.canaleAlleanza : Tema.Apple.Colore.canaleIndipendente
}

/// `.lbl` «AREA · Nome Cognome» nel colore dell'area, titolo 28 bold e, a destra, «Apri l'analisi completa ›».
private struct TestataDettaglioArea360: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.statoDettaglioApple) private var dettaglio
    let area: AreaAnalisi
    let nome: String
    let titolo: String

    var body: some View {
        let _ = ContaCorpi.segna()
        let d = Tema.Apple.Aree360.Dettaglio.self
        let margine = max(0, d.margineChiudi - Tema.Apple.Misura.Padding.dettaglio.trailing)
        return HStack(alignment: .top, spacing: d.spazioTestata) {
            VStack(alignment: .leading, spacing: d.spazioTitolo) {
                Text("\(TestiAree360.nomeArea(area)) · \(nome)")
                    .carattereApple(d.etichetta)
                    .foregroundColor(Tema.Apple.Aree360.colore(area))
                    .lineLimit(1)
                Text(titolo)
                    .carattereApple(d.titolo)
                    .foregroundColor(d.coloreTitolo)
                    .lineLimit(1)
                    .minimumScaleFactor(d.riduzioneTitolo)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            Button(action: completa) {
                Text("Apri l'analisi completa ›")
            }
            .buttonStyle(.appleSobrio)
            .fixedSize()
            .help("Il pannello di sempre dell'area, con le ipotesi da correggere")
        }
        .padding(.trailing, margine)
    }

    /// Chiude subito il dettaglio e apre il pannello completo dell'area.
    private func completa() {
        dettaglio?.chiudi(subito: true)
        stato.areaAnalisi = area
    }
}

/// Una cifra `.k`/`.v`: un numero che si conta oppure un testo.
private struct CifraDettaglioArea360: View {
    let titolo: String
    var valore: Double?
    var formato: FormatoCifra = .euro
    var indice: Int = 0
    var testo: String?
    var aiuto: String?

    init(titolo: String, valore: Double?, formato: FormatoCifra, indice: Int, aiuto: String? = nil) {
        self.titolo = titolo
        self.valore = valore
        self.formato = formato
        self.indice = indice
        self.aiuto = aiuto
    }

    init(titolo: String, testo: String, aiuto: String? = nil) {
        self.titolo = titolo
        self.testo = testo
        self.aiuto = aiuto
    }

    var body: some View {
        let d = Tema.Apple.Aree360.Dettaglio.self
        return VStack(alignment: .leading, spacing: d.spazioEtichettaCifra) {
            Text(titolo)
                .carattereApple(d.etichettaCifra)
                .foregroundColor(d.coloreEtichettaCifra)
                .lineLimit(1)
            Group {
                if let v = valore {
                    NumeroCheConta(v, formato: formato, indice: indice)
                } else {
                    Text(testo ?? "—")
                }
            }
            .carattereApple(d.cifra)
            .foregroundColor(d.coloreCifra)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .fixedSize(horizontal: true, vertical: false)
        .help(aiuto ?? "")
    }
}

/// Le ipotesi del calcolo, sempre scritte sotto i risultati.
private struct IpotesiDettaglioArea360: View {
    let testo: String

    var body: some View {
        let d = Tema.Apple.Aree360.Dettaglio.self
        return Text(testo)
            .carattereApple(d.ipotesi)
            .foregroundColor(d.coloreIpotesi)
            .lineLimit(d.righeIpotesi)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, d.ipotesiSopra)
    }
}

/// «Salva come proposta» (sul canale scelto, sempre riconoscibile), «Chiedi a Vera di spiegarlo».
private struct PiedeDettaglioArea360: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.statoDettaglioApple) private var dettaglio
    let area: AreaAnalisi
    @Binding var canale: Canale

    var body: some View {
        let _ = ContaCorpi.segna()
        let d = Tema.Apple.Aree360.Dettaglio.self
        return HStack(alignment: .center, spacing: d.spazioPulsanti) {
            Button(action: salva) {
                Text("Salva come proposta")
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(stato.solaLettura)
            .help("Le proposte che le analisi di Prisma suggeriscono per l'area diventano una bozza in Posizioni")
            Button(action: chiediVera) {
                Text("Chiedi a Vera di spiegarlo")
            }
            .buttonStyle(.appleGrande)
            Spacer(minLength: 0)
            CanaleSimulatoreApple(canale: $canale)
        }
    }

    /// La proposta si salva, il dettaglio torna sulla card e poi compare l'avviso; senza proposta, solo l'avviso.
    private func salva() {
        let s = stato
        let esito = s.salvaPropostaArea360(area, canale: canale)
        if esito.salvata, let d = dettaglio {
            d.chiudi(poi: { s.mostraAvviso(esito.testo) })
        } else {
            s.mostraAvviso(esito.testo)
        }
    }

    /// Chiude subito il dettaglio, apre Vera e le manda la domanda sull'area dopo 0,7 s.
    private func chiediVera() {
        dettaglio?.chiudi(subito: true)
        stato.chiediVeraArea360(area)
    }
}
