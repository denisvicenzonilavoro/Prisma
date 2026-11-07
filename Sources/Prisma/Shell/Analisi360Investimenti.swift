import SwiftUI

// Analisi 360 › Investimenti: la sintesi dell'area. Una cosa grande in alto (il capitale atteso, netto, a fine
// orizzonte) con accanto il rischio rispetto al profilo (scala SRI 1-7 con il limite del profilo segnato), subito
// sotto il grafico dei tre scenari, poi le tessere per decidere, la prova di tenuta come barre «oggi / dopo il
// calo», la cascata dei costi (lordo − costi − imposte = netto) e le posizioni collegate con il canale.
// Le spiegazioni lunghe (scenari, costi, rischio) sono sezioni richiudibili, chiuse all'inizio.
// Vive in un file proprio perché ogni area si possa rifinire senza toccare le altre. Gettoni in
// DesignSystem/TemaAnalisi360Investimenti.swift. I calcoli sono quelli di MotoreAnalisi e MotoreProiezione.

private typealias MI = Tema.Misura.Investimenti360
private typealias KI = Tema.Colore.Investimenti360
private typealias FI = Tema.Testo.Investimenti360

/// Il rischio delle posizioni di investimento rispetto al profilo del cliente.
private struct RischioInvestimenti360 {
    /// SRI medio ponderato sul valore delle posizioni in essere (nil se non ce ne sono).
    let sri: Double?
    /// Lo stesso contando le proposte aperte come se fossero in essere (nil senza proposte).
    let sriConProposte: Double?
    /// SRI massimo del profilo del cliente (nil senza propensione).
    let massimo: Int?
    let propensione: String?
    /// Almeno una posizione senza SRI indicato: il valore è in parte stimato.
    let stimato: Bool

    /// Il valore da segnare sulla scala: quello in essere o, senza posizioni in essere, quello delle proposte.
    var segnato: Double? { sri ?? sriConProposte }

    var oltre: Bool {
        guard let s = segnato, let m = massimo else { return false }
        return s > Double(m)
    }
}

extension AppAnalisi360 {
    func sintesiInvestimenti(_ i: IpotesiInvestimento) -> some View {
        let e = MotoreAnalisi.investimenti(i)
        return VStack(alignment: .leading, spacing: MI.spazioBlocchi) {
            testataInvestimenti(i, e)
            scenariInvestimenti(i, e)
            tessereInvestimenti(i, e)
            tenutaInvestimenti(i, e)
            costiInvestimenti(i, e)
            posizioniInvestimenti
            apribiliInvestimenti(i, e)
        }
    }

    // MARK: - Testata: la cifra principale e il rischio rispetto al profilo

    private func testataInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        Affiancati(soglia: SoglieAffiancati.pannello, spazio: MI.spazioTestata) {
            cifraInvestimenti(i, e)
            riquadroRischioInvestimenti(rischioInvestimenti())
        }
    }

    private func cifraInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let n = i.anni
        let netto = (e.rendimentoNetto * 100).rounded() / 100
        let riga1: String = "Partendo da \(Formati.euro(i.capitale))"
            + (i.versamentoMensile >= 0.5 ? " e \(Formati.euro(i.versamentoMensile)) al mese" : "")
            + " · \(Formati.euro(e.esito.reale)) in euro di oggi"
        let riga2: String = "Rendimento \(Formati.percentuale(i.rendimento)) lordo, \(Formati.percentuale(netto)) dopo i costi annui · imposte al \(Formati.percentuale(i.aliquota))"
        return VStack(alignment: .leading, spacing: MI.spazioCifra) {
            Text("CAPITALE ATTESO TRA \(n) \(n == 1 ? "ANNO" : "ANNI"), NETTO")
                .font(FI.occhiello)
                .tracking(MI.tracciatoOcchiello)
                .foregroundColor(KI.occhiello)
                .fixedSize(horizontal: false, vertical: true)
            Text(Formati.euro(e.esito.netto))
                .font(FI.cifra)
                .foregroundColor(KI.cifra)
                .lineLimit(1)
                .minimumScaleFactor(MI.scalaMinimaCifra)
            Text(riga1)
                .font(FI.nota)
                .foregroundColor(KI.nota)
                .fixedSize(horizontal: false, vertical: true)
            Text(riga2)
                .font(FI.nota)
                .foregroundColor(KI.nota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// SRI medio ponderato sul valore, come nella coerenza con il profilo (MotoreCoerenza.sriStimato).
    private func rischioInvestimenti() -> RischioInvestimenti360 {
        let elenco = contratti(.investimenti)
        let inEssere = elenco.filter { $0.stato == .inEssere && $0.valore > 0 }
        let aperte = elenco.filter { propostaAperta($0) }.map(MotoreCoerenza.comeInEssere).filter { $0.valore > 0 }
        func media(_ v: [Posizione]) -> Double? {
            let totale = v.reduce(0.0) { $0 + $1.valore }
            guard totale > 0 else { return nil }
            let somma = v.reduce(0.0) { $0 + $1.valore * Double(MotoreCoerenza.sriStimato($1)) }
            return somma / totale
        }
        let propensione = stato.cliente(cliente)?.profilo.propensione
        let stimato = (inEssere + aperte).contains { $0.sri == nil && !$0.multiramoDivisa }
        return RischioInvestimenti360(
            sri: media(inEssere),
            sriConProposte: aperte.isEmpty ? nil : media(inEssere + aperte),
            massimo: propensione.map(MotoreCoerenza.sriMassimo),
            propensione: propensione?.nome.lowercased(),
            stimato: stimato
        )
    }

    private func riquadroRischioInvestimenti(_ r: RischioInvestimenti360) -> some View {
        VStack(alignment: .leading, spacing: MI.spazioRischio) {
            HStack(alignment: .firstTextBaseline, spacing: MI.spazioPillola) {
                Text("Rischio rispetto al profilo")
                    .font(FI.titoloRischio)
                    .foregroundColor(KI.titoloSezione)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                pillolaRischioInvestimenti(r)
            }
            ScalaRischioProfilo360(sri: r.segnato, massimo: r.massimo)
                .padding(.vertical, MI.sporgenzaLimite)
            ForEach(righeRischioInvestimenti(r), id: \.self) { riga in
                Text(riga)
                    .font(FI.notaRischio)
                    .foregroundColor(KI.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MI.margineRischio)
        .frame(width: MI.larghezzaRischio, alignment: .leading)
        .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera))
        .help("SRI medio delle posizioni di investimento, pesato sul valore (senza SRI indicato si stima dall'area). Fasce del profilo: prudente fino a 2, moderata fino a 3, dinamica fino a 5, aggressiva fino a 7.")
    }

    @ViewBuilder private func pillolaRischioInvestimenti(_ r: RischioInvestimenti360) -> some View {
        if r.segnato == nil {
            EmptyView()
        } else if r.massimo == nil {
            Pillola(testo: "Profilo da indicare", tono: .neutro)
        } else if r.oltre {
            Pillola(testo: "Oltre il profilo", tono: .attenzione)
        } else {
            Pillola(testo: "Nel profilo", tono: .ok)
        }
    }

    private func righeRischioInvestimenti(_ r: RischioInvestimenti360) -> [String] {
        var righe: [String] = []
        if let s = r.sri {
            righe.append("SRI medio \(MotoreCoerenza.numero(s)) su 7" + (r.stimato ? ", in parte stimato" : ""))
        } else if let s = r.sriConProposte {
            righe.append("Solo proposte: SRI medio \(MotoreCoerenza.numero(s)) su 7")
        } else {
            righe.append("Nessuna posizione di investimento con un valore")
        }
        if let m = r.massimo, let p = r.propensione {
            righe.append("Profilo \(p): fino a \(m)")
        } else {
            righe.append("Propensione al rischio da indicare nella scheda del cliente")
        }
        if r.sri != nil, let c = r.sriConProposte {
            righe.append("Con le proposte: \(MotoreCoerenza.numero(c)) su 7")
        }
        return righe
    }

    // MARK: - Il grafico dei tre scenari

    private func scenariInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let prudente = e.scenari.first
        let favorevole = e.scenari.dropFirst(2).first
        var serie: [GraficoProiezione.Serie] = []
        if let p = prudente { serie.append(.init(id: "prudente", punti: p.esito.punti, colore: KI.prudente)) }
        if let f = favorevole { serie.append(.init(id: "favorevole", punti: f.esito.punti, colore: KI.favorevole)) }
        serie.append(.init(id: "atteso", punti: e.esito.punti, colore: KI.atteso, principale: true))
        return VStack(alignment: .leading, spacing: MI.spazioSezione) {
            Text("Come può crescere, prima delle imposte")
                .font(FI.etichetta)
                .foregroundColor(KI.etichetta)
                .fixedSize(horizontal: false, vertical: true)
            GraficoProiezione(serie: serie, vuoto: "Nessun capitale né versamento: il grafico compare con il primo importo")
            DisposizioneAcapoRicerca(spazio: MI.spazioLegenda) {
                LegendaLinea(colore: KI.atteso, testo: "Atteso \(Formati.percentuale(i.rendimento)) · \(Formati.euro(e.esito.netto)) netti")
                if let p = prudente {
                    LegendaLinea(colore: KI.prudente, testo: "Prudente \(Formati.percentuale(p.rendimento)) · \(Formati.euro(p.esito.netto))")
                }
                if let f = favorevole {
                    LegendaLinea(colore: KI.favorevole, testo: "Favorevole \(Formati.percentuale(f.rendimento)) · \(Formati.euro(f.esito.netto))")
                }
                LegendaLinea(colore: KI.versato, testo: "Versato", tratteggio: true)
            }
        }
    }

    // MARK: - Tessere per decidere

    private func tessereInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let guadagno = e.esito.guadagnoNetto
        let anni = "\(i.anni) \(i.anni == 1 ? "anno" : "anni")"
        return Affiancati(soglia: SoglieAffiancati.pannello, spazio: MI.spazioTessere) {
            TesseraCifraAnalisi(titolo: "Versato", valore: Formati.euro(e.esito.versato),
                                nota: i.versamentoMensile >= 0.5 ? "capitale e versamenti in \(anni)" : "il capitale di partenza")
            TesseraCifraAnalisi(titolo: "Guadagno netto", valore: CifreDoc.euroSegno(guadagno),
                                nota: "dopo costi e imposte",
                                tono: .segno(guadagno))
            TesseraCifraAnalisi(titolo: "In euro di oggi", valore: Formati.euro(e.esito.reale),
                                nota: "con l'inflazione al \(Formati.percentuale(i.inflazione))")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Prova di tenuta: oggi / dopo il calo

    @ViewBuilder private func tenutaInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let calo = min(max(i.calo, 0), 100)
        if i.capitale >= 0.5 && calo > 0 {
            VStack(alignment: .leading, spacing: MI.spazioSezione) {
                Text("Prova di tenuta: se domani i mercati scendessero del \(Formati.percentuale(calo))")
                    .font(FI.titoloSezione)
                    .foregroundColor(KI.titoloSezione)
                    .fixedSize(horizontal: false, vertical: true)
                BarreConfronto(
                    voci: [
                        .init("Capitale oggi", i.capitale, colore: KI.oggi),
                        .init("Subito dopo il calo", e.dopoCalo, colore: KI.dopoCalo),
                    ],
                    aiutoDifferenza: "La perdita subito dopo il calo, in euro e in percentuale del capitale",
                    formatoDifferenza: { d in "\(CifreDoc.euroSegno(d)) · \(CifreDoc.meno)\(Formati.percentuale(calo))" }
                )
                Text("Una prova separata dalla proiezione: serve a capire se il cliente reggerebbe la discesa senza disinvestire.")
                    .font(FI.notaRischio)
                    .foregroundColor(KI.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Quanto tolgono i costi: lordo − costi − imposte = netto

    /// Lo stesso calcolo senza costi d'ingresso né annui: il lordo che il mercato darebbe da solo.
    private func lordoSenzaCostiInvestimenti(_ i: IpotesiInvestimento) -> Double {
        var senza = i.parametri
        senza.costoIngresso = 0
        senza.costoAnnuo = 0
        return MotoreProiezione.calcola(senza).lordo
    }

    @ViewBuilder private func costiInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let lordoSenzaCosti = lordoSenzaCostiInvestimenti(i)
        let costi = max(0, lordoSenzaCosti - e.esito.lordo)
        let imposte = max(0, e.esito.imposte)
        if lordoSenzaCosti >= 0.5 && (costi >= 0.5 || imposte >= 0.5) {
            VStack(alignment: .leading, spacing: MI.spazioSezione) {
                Text("Quanto tolgono costi e imposte, tra \(i.anni) \(i.anni == 1 ? "anno" : "anni")")
                    .font(FI.titoloSezione)
                    .foregroundColor(KI.titoloSezione)
                    .fixedSize(horizontal: false, vertical: true)
                Cascata(voci: vociCostiInvestimenti(lordo: lordoSenzaCosti, costi: costi, imposte: imposte, netto: e.esito.netto))
                    .help("I costi comprendono i rendimenti che non maturano sulle somme pagate. Al netto delle imposte, che su un guadagno più basso sono minori, tolgono \(Formati.euro(e.impattoCosti)) al capitale finale.")
            }
        }
    }

    private func vociCostiInvestimenti(lordo: Double, costi: Double, imposte: Double, netto: Double) -> [Cascata.Voce] {
        var voci: [Cascata.Voce] = [.init("Lordo, senza costi", lordo, tipo: .partenza)]
        if costi >= 0.5 { voci.append(.init("Costi, con i rendimenti persi", costi, tipo: .sottrazione)) }
        if imposte >= 0.5 { voci.append(.init("Imposte sul guadagno", imposte, tipo: .sottrazione)) }
        voci.append(.init("Netto", netto, tipo: .totale))
        return voci
    }

    // MARK: - Le posizioni collegate, con il canale

    private var posizioniInvestimenti: some View {
        let elenco = contratti(.investimenti)
        return VStack(alignment: .leading, spacing: MI.spazioSezione) {
            Text(elenco.isEmpty ? "Le posizioni di investimento" : "Le posizioni di investimento (\(elenco.count))")
                .font(FI.titoloSezione)
                .foregroundColor(KI.titoloSezione)
            if elenco.isEmpty {
                Text("Nessuna posizione di investimento in Posizioni: aggiungila lì per vederla qui.")
                    .font(FI.notaPosizione)
                    .foregroundColor(KI.notaPosizione)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: MI.spazioPosizioni) {
                    ForEach(elenco) { p in
                        rigaPosizioneInvestimenti(p)
                    }
                }
            }
        }
    }

    private func rigaPosizioneInvestimenti(_ p: Posizione) -> some View {
        let proposta = p.stato == .proposta
        let valore = proposta ? p.versamentoIniziale : p.valore
        let voci: [String?] = [p.tipologia.isEmpty ? nil : p.tipologia, p.sri.map { s -> String in "SRI \(s)" }]
        let dettagli = voci.compactMap { $0 }
        return Button { stato.apriPosizione(p) } label: {
            HStack(alignment: .center, spacing: MI.spazioPosizione) {
                VStack(alignment: .leading, spacing: MI.spazioTestiPosizione) {
                    Text(p.nome)
                        .font(FI.nomePosizione)
                        .foregroundColor(KI.nomePosizione)
                        .fixedSize(horizontal: false, vertical: true)
                    if !dettagli.isEmpty {
                        Text(dettagli.joined(separator: " · "))
                            .font(FI.notaPosizione)
                            .foregroundColor(KI.notaPosizione)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: MI.spazioPosizione)
                if proposta {
                    Pillola(testo: "Proposta", tono: .attenzione)
                }
                EtichettaCanale(canale: p.canale, compatta: true)
                Text(Formati.euro(valore))
                    .font(FI.cifraPosizione)
                    .foregroundColor(KI.nomePosizione)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(minWidth: MI.colonnaCifraPosizione, alignment: .trailing)
                Image(systemName: "chevron.right")
                    .font(FI.freccia)
                    .foregroundColor(KI.notaPosizione)
            }
            .padding(MI.marginePosizione)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera))
        }
        .buttonStyle(StileSemplice())
        .help("Apri la posizione")
    }

    // MARK: - A richiesta: scenari, costi, rischio

    private func apribiliInvestimenti(_ i: IpotesiInvestimento, _ e: MotoreAnalisi.EsitoInvestimento) -> some View {
        let ampiezza = Formati.numeroFormatter.string(from: NSNumber(value: IpotesiCalcolo.ampiezzaScenari)) ?? "2"
        return VStack(alignment: .leading, spacing: MI.spazioApribili) {
            SezioneApribileInvestimenti(titolo: "Come si leggono i tre scenari") {
                NotaMetodo(testo: "Lo scenario atteso usa il rendimento lordo delle ipotesi; prudente e favorevole lo spostano di \(ampiezza) punti in meno e in più. Le linee sono il valore prima delle imposte, anno per anno; le cifre della legenda sono nette, a fine orizzonte. Non sono previsioni: mostrano quanto conta il rendimento.")
            }
            SezioneApribileInvestimenti(titolo: "Come si contano costi e imposte") {
                NotaMetodo(testo: "Il lordo senza costi è lo stesso calcolo con costo d'ingresso e costo annuo a zero. I costi sono la differenza con il lordo effettivo, rendimenti non maturati compresi. L'imposta si paga alla fine sulla sola plusvalenza. Al netto delle imposte, i costi tolgono \(Formati.euro(e.impattoCosti)) al capitale finale.")
            }
            SezioneApribileInvestimenti(titolo: "Come si misura il rischio") {
                NotaMetodo(testo: "L'SRI (1-7) è quello del KID delle posizioni, pesato sul valore; senza SRI indicato si stima dall'area. Il limite del profilo segue le fasce usate di solito nell'adeguatezza: prudente fino a 2, moderata fino a 3, dinamica fino a 5, aggressiva fino a 7. La prova di tenuta applica il calo al solo capitale di oggi.")
            }
        }
    }
}

// MARK: - Scala del rischio con il limite del profilo

/// La scala SRI da 1 a 7 come nel KID: la casella del portafoglio piena, le caselle oltre il profilo del cliente
/// tinte d'arancio e una lineetta verticale dove finisce il profilo.
private struct ScalaRischioProfilo360: View {
    let sri: Double?
    let massimo: Int?

    var body: some View {
        let scelta = sri.map { Int($0.rounded()) }
        HStack(spacing: MI.spazioCaselle) {
            ForEach(1...7, id: \.self) { i in
                casella(i, scelta: scelta)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etichettaAccessibile(scelta))
    }

    private func casella(_ i: Int, scelta: Int?) -> some View {
        let oltre = massimo.map { i > $0 } ?? false
        let attiva = i == scelta
        let forma = RoundedRectangle(cornerRadius: Tema.Raggio.Dossier.casellaRischio, style: .continuous)
        let fondo: Color = attiva ? (oltre ? KI.sceltaOltre : KI.scelta) : (oltre ? KI.casellaOltre : KI.casella)
        let bordo: Color = attiva ? fondo : (oltre ? KI.casellaOltreBordo : KI.casellaBordo)
        return Text("\(i)")
            .font(FI.casella)
            .foregroundColor(attiva ? KI.testoScelta : KI.casellaTesto)
            .frame(width: MI.casellaLarga, height: MI.casellaAlta)
            .background(forma.fill(fondo))
            .overlay(forma.strokeBorder(bordo, lineWidth: Tema.Misura.filo))
            .overlay(alignment: .trailing) {
                if let m = massimo, i == m, m < 7 {
                    Rectangle()
                        .fill(KI.limiteProfilo)
                        .frame(width: MI.segnoLimite, height: MI.casellaAlta + 2 * MI.sporgenzaLimite)
                        .offset(x: (MI.spazioCaselle + MI.segnoLimite) / 2)
                        .allowsHitTesting(false)
                }
            }
    }

    private func etichettaAccessibile(_ scelta: Int?) -> String {
        let s = scelta.map { "Rischio \($0) su 7" } ?? "Rischio non indicato"
        return s + (massimo.map { ", profilo fino a \($0)" } ?? "")
    }
}

// MARK: - Sezione richiudibile

/// Una sezione chiusa all'inizio: il titolo con la freccia, il contenuto a un clic.
private struct SezioneApribileInvestimenti<Contenuto: View>: View {
    let titolo: String
    @ViewBuilder let contenuto: () -> Contenuto
    @State private var aperta = false

    var body: some View {
        VStack(alignment: .leading, spacing: MI.spazioSezione) {
            Button {
                withAnimation(Tema.Moto.passaggio) { aperta.toggle() }
            } label: {
                HStack(spacing: MI.spazioFreccia) {
                    Image(systemName: "chevron.right")
                        .font(FI.freccia)
                        .rotationEffect(.degrees(aperta ? 90 : 0))
                        .frame(width: MI.freccia)
                    Text(titolo)
                        .font(FI.apri)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(KI.apri)
                .contentShape(Rectangle())
            }
            .buttonStyle(StileSemplice())
            .help(aperta ? "Nascondi" : "Mostra")
            if aperta {
                contenuto()
            }
        }
    }
}
