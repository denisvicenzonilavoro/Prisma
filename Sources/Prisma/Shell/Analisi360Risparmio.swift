import SwiftUI

// Analisi 360 › Risparmio: la sintesi dell'area. Una cosa grande in alto (quanto manca all'obiettivo a scadenza,
// o «Raggiunto»), in colore semaforico; subito sotto la barra che la spiega (dove arriva il piano rispetto
// all'obiettivo rivalutato, e dove arriverebbe con le proposte aperte); poi le tessere per decidere, la
// proiezione del piano e i piani collegati con il canale. «Dove va il denaro» e il metodo sono sezioni
// richiudibili (chiuse all'inizio). I calcoli sono quelli di MotoreAnalisi.risparmio: qui si dispongono soltanto.
// Vive in un file proprio perché ogni area si possa rifinire senza toccare le altre. Gettoni in
// DesignSystem/TemaAnalisi360Risparmio.swift.

private typealias MR = Tema.Misura.Risparmio360
private typealias KR = Tema.Colore.Risparmio360
private typealias FR = Tema.Testo.Risparmio360

extension AppAnalisi360 {
    func sintesiRisparmio(_ i: IpotesiRisparmio) -> some View {
        let e = MotoreAnalisi.risparmio(i)
        let pr = proposte(.risparmio)
        var conProposte = i
        conProposte.capitale += pr.capitale
        conProposte.versamentoMensile += pr.mensile
        let ec: MotoreAnalisi.EsitoRisparmio? = pr.conteggio > 0 ? MotoreAnalisi.risparmio(conProposte) : nil
        return VStack(alignment: .leading, spacing: MR.spazioBlocchi) {
            testataRisparmio(i, e)
            barraRisparmio(e, ec, conteggio: pr.conteggio)
            tessereRisparmio(i, e, ec, conteggio: pr.conteggio)
            proiezioneRisparmio(i, e)
            pianiRisparmio
            apribiliRisparmio(i, e)
        }
    }

    // MARK: - Testata: la cifra principale

    /// Il tono della cifra grande: raggiunto, a metà strada o oltre, sotto la metà (come la quota della barra).
    private func coloreCifraRisparmio(_ e: MotoreAnalisi.EsitoRisparmio) -> Color {
        if e.mancante < 0.5 { return KR.cifraRaggiunto }
        return e.copertura >= 50 ? KR.cifraAttenzione : KR.cifraLontano
    }

    private func anniRisparmio(_ n: Int) -> String {
        "\(n) \(n == 1 ? "anno" : "anni")"
    }

    private func testataRisparmio(_ i: IpotesiRisparmio, _ e: MotoreAnalisi.EsitoRisparmio) -> some View {
        let manca = e.mancante >= 0.5
        let quota = Formati.percentuale(e.copertura.rounded(.down))
        let occhiello = manca ? "MANCANTE ALL'OBIETTIVO, A SCADENZA" : "OBIETTIVO A SCADENZA"
        let nota = manca
            ? "Il piano arriva a \(Formati.euro(e.esito.netto)) su \(Formati.euro(e.obiettivoNominale)): il \(quota) dell'obiettivo"
            : "Il piano arriva a \(Formati.euro(e.esito.netto)) su \(Formati.euro(e.obiettivoNominale)) necessari"
        return VStack(alignment: .leading, spacing: MR.spazioCifra) {
            Text(occhiello)
                .font(FR.occhiello)
                .tracking(MR.tracciatoOcchiello)
                .foregroundColor(KR.occhiello)
            HStack(alignment: .firstTextBaseline, spacing: MR.spazioUnita) {
                Text(manca ? Formati.euro(e.mancante) : "Raggiunto")
                    .font(FR.cifra)
                    .foregroundColor(coloreCifraRisparmio(e))
                    .lineLimit(1)
                    .minimumScaleFactor(MR.scalaMinimaCifra)
                Text("tra \(anniRisparmio(i.anni))")
                    .font(FR.unita)
                    .foregroundColor(KR.nota)
                    .fixedSize()
            }
            Text(nota)
                .font(FR.nota)
                .foregroundColor(KR.nota)
                .fixedSize(horizontal: false, vertical: true)
            Text("Obiettivo di \(Formati.euro(i.obiettivo)) in euro di oggi, rivalutato con l'inflazione al \(Formati.percentuale(i.inflazione))")
                .font(FR.nota)
                .foregroundColor(KR.nota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Barra: dove arriva il piano rispetto all'obiettivo

    private func barraRisparmio(_ e: MotoreAnalisi.EsitoRisparmio, _ ec: MotoreAnalisi.EsitoRisparmio?,
                                conteggio: Int) -> some View {
        VStack(alignment: .leading, spacing: MR.spazioSezione) {
            Text("Verso l'obiettivo a scadenza")
                .font(FR.etichetta)
                .foregroundColor(KR.etichetta)
                .fixedSize(horizontal: false, vertical: true)
            BarraCopertura(fabbisogno: e.obiettivoNominale, coperto: e.esito.netto,
                           conProposte: ec.map { $0.esito.netto },
                           colore: KR.piano,
                           etichettaFabbisogno: "Obiettivo a scadenza",
                           etichettaCoperto: "Con il piano attuale",
                           etichettaProposte: conteggio == 1 ? "Con la proposta" : "Con le proposte",
                           etichettaScoperto: "Mancante")
        }
    }

    // MARK: - Tessere: ciò che serve per decidere

    private func tessereRisparmio(_ i: IpotesiRisparmio, _ e: MotoreAnalisi.EsitoRisparmio,
                                  _ ec: MotoreAnalisi.EsitoRisparmio?, conteggio: Int) -> some View {
        HStack(alignment: .top, spacing: MR.spazioTessere) {
            tesseraVersamentoRisparmio(i, e)
            tesseraPropostaRisparmio(e, ec, conteggio: conteggio)
            TesseraCifraAnalisi(titolo: "Il piano a scadenza", valore: Formati.euro(e.esito.netto),
                                nota: "versati \(Formati.euro(e.esito.versato)), al netto di costi e imposte",
                                aiuto: "Guadagno netto \(Formati.euro(e.esito.guadagnoNetto)) · in euro di oggi \(Formati.euro(e.esito.reale)).")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tesseraVersamentoRisparmio(_ i: IpotesiRisparmio, _ e: MotoreAnalisi.EsitoRisparmio) -> some View {
        let teorico = e.versamentoTeorico
        let differenza = max(0, (teorico ?? 0) - i.versamentoMensile)
        let nota: String = {
            guard teorico != nil else { return "nessun anno di accumulo" }
            if differenza >= 0.5 {
                return "oggi \(Formati.euro(i.versamentoMensile)) al mese: \(Formati.euro(differenza)) in più"
            }
            return "oggi \(Formati.euro(i.versamentoMensile)) al mese: basta così"
        }()
        return TesseraCifraAnalisi(titolo: "Versamento per l'obiettivo",
                                   valore: teorico.map { "\(Formati.euro($0))/mese" } ?? "—",
                                   nota: nota,
                                   tono: teorico == nil ? .neutro : (differenza >= 0.5 ? .attenzione : .positivo),
                                   aiuto: "Il versamento mensile costante, in euro nominali, che con le ipotesi inserite raggiunge l'obiettivo a scadenza. Non è una garanzia di risultato.")
    }

    @ViewBuilder private func tesseraPropostaRisparmio(_ e: MotoreAnalisi.EsitoRisparmio,
                                                       _ ec: MotoreAnalisi.EsitoRisparmio?, conteggio: Int) -> some View {
        if let ec {
            let meno = e.mancante - ec.mancante
            TesseraCifraAnalisi(titolo: conteggio == 1 ? "Con la proposta aperta" : "Con le \(conteggio) proposte aperte",
                                valore: ec.mancante >= 0.5 ? Formati.euro(ec.mancante) : "Raggiunto",
                                nota: ec.mancante >= 0.5
                                    ? (meno >= 0.5 ? "mancanti: \(Formati.euro(meno)) in meno" : "mancanti")
                                    : "l'obiettivo è coperto",
                                tono: TonoCifraAnalisi.segno(meno),
                                evidenziata: meno >= 0.5,
                                aiuto: "Il piano con le proposte arriva a \(Formati.euro(ec.esito.netto)) su \(Formati.euro(ec.obiettivoNominale)).")
        } else {
            TesseraCifraAnalisi(titolo: "Obiettivo a scadenza", valore: Formati.euro(e.obiettivoNominale),
                                nota: "con l'inflazione ipotizzata",
                                aiuto: "L'obiettivo in euro di oggi rivalutato all'inflazione fino alla scadenza.")
        }
    }

    // MARK: - Proiezione del piano

    @ViewBuilder private func proiezioneRisparmio(_ i: IpotesiRisparmio, _ e: MotoreAnalisi.EsitoRisparmio) -> some View {
        let serie = [GraficoProiezione.Serie(id: "piano", punti: e.esito.punti, colore: KR.piano, principale: true)]
        let vuoto = "Nessun capitale né versamento: il grafico compare con il primo versamento"
        if i.capitale < 0.5 && i.versamentoMensile < 0.5 {
            GraficoProiezione(serie: serie, vuoto: vuoto)
        } else {
            VStack(alignment: .leading, spacing: MR.spazioSezione) {
                Text("Come cresce il piano fino alla scadenza")
                    .font(FR.etichetta)
                    .foregroundColor(KR.etichetta)
                    .fixedSize(horizontal: false, vertical: true)
                GraficoProiezione(serie: serie, vuoto: vuoto)
                HStack(spacing: MR.spazioLegenda) {
                    LegendaLinea(colore: KR.piano, testo: "Valore del piano")
                    LegendaLinea(colore: KR.versato, testo: "Versato", tratteggio: true)
                }
            }
        }
    }

    // MARK: - I piani collegati, con il canale

    private var pianiRisparmio: some View {
        let elenco = contratti(.risparmio)
        return VStack(alignment: .leading, spacing: MR.spazioSezione) {
            Text(elenco.isEmpty ? "I piani di risparmio" : "I piani di risparmio (\(elenco.count))")
                .font(FR.titoloSezione)
                .foregroundColor(KR.titoloSezione)
            if elenco.isEmpty {
                Text("Nessun piano di risparmio in Posizioni: aggiungilo lì per vederlo qui.")
                    .font(FR.notaPiano)
                    .foregroundColor(KR.notaPiano)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: MR.spazioPiani) {
                    ForEach(elenco) { p in
                        rigaPianoRisparmio(p)
                    }
                }
            }
        }
    }

    private func rigaPianoRisparmio(_ p: Posizione) -> some View {
        let proposta = p.stato == .proposta
        let valore = proposta ? p.versamentoIniziale : p.valore
        let premio = p.premioAnnuo / 12
        return Button { stato.apriPosizione(p) } label: {
            HStack(alignment: .center, spacing: MR.spazioPiano) {
                VStack(alignment: .leading, spacing: MR.spazioTestiPiano) {
                    Text(p.nome)
                        .font(FR.nomePiano)
                        .foregroundColor(KR.nomePiano)
                        .fixedSize(horizontal: false, vertical: true)
                    if !p.tipologia.isEmpty {
                        Text(p.tipologia)
                            .font(FR.notaPiano)
                            .foregroundColor(KR.notaPiano)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: MR.spazioPiano)
                if proposta {
                    Pillola(testo: "Proposta", tono: .attenzione)
                }
                EtichettaCanale(canale: p.canale, compatta: true)
                cifrePianoRisparmio(valore: valore, premio: premio)
                Image(systemName: "chevron.right")
                    .font(FR.freccia)
                    .foregroundColor(KR.notaPiano)
            }
            .padding(MR.marginePiano)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera))
        }
        .buttonStyle(StileSemplice())
        .help("Apri la posizione")
    }

    private func cifrePianoRisparmio(valore: Double, premio: Double) -> some View {
        VStack(alignment: .trailing, spacing: MR.spazioTestiPiano) {
            Text(Formati.euro(valore))
                .font(FR.cifraPiano)
                .foregroundColor(KR.nomePiano)
                .lineLimit(1)
                .fixedSize()
            if premio >= 0.5 {
                Text("\(Formati.euro(premio)) al mese")
                    .font(FR.notaPiano)
                    .foregroundColor(KR.notaPiano)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .frame(minWidth: MR.colonnaCifraPiano, alignment: .trailing)
    }

    // MARK: - A richiesta: dove va il denaro, metodo

    /// Versato + rendimento − costi − imposte = netto a scadenza, con le cifre dell'esito del motore.
    private func vociDenaroRisparmio(_ e: MotoreAnalisi.EsitoRisparmio) -> [Cascata.Voce] {
        let x = e.esito
        let rendimento = x.lordo + x.costi - x.versato
        var voci = [Cascata.Voce("Versato in tutto", x.versato, tipo: .partenza, id: "versato")]
        if abs(rendimento) >= 0.5 {
            voci.append(Cascata.Voce("Rendimento", abs(rendimento), tipo: rendimento >= 0 ? .aggiunta : .sottrazione,
                                     id: "rendimento"))
        }
        if x.costi >= 0.5 {
            voci.append(Cascata.Voce("Costi", x.costi, tipo: .sottrazione, id: "costi"))
        }
        if x.imposte >= 0.5 {
            voci.append(Cascata.Voce("Imposte", x.imposte, tipo: .sottrazione, id: "imposte"))
        }
        voci.append(Cascata.Voce("Netto a scadenza", x.netto, tipo: .totale, id: "netto"))
        return voci
    }

    private func apribiliRisparmio(_ i: IpotesiRisparmio, _ e: MotoreAnalisi.EsitoRisparmio) -> some View {
        VStack(alignment: .leading, spacing: MR.spazioApribili) {
            SezioneApribileRisparmio(titolo: "Dove va il denaro, fino alla scadenza") {
                Cascata(voci: vociDenaroRisparmio(e))
            }
            SezioneApribileRisparmio(titolo: "Come si calcola") {
                NotaMetodo(testo: "Capitale iniziale \(Formati.euro(i.capitale)) e \(Formati.euro(i.versamentoMensile)) al mese per \(anniRisparmio(i.anni)), rendimento annuo \(Formati.percentuale(i.rendimento)), costo annuo \(Formati.percentuale(i.costoAnnuo)), imposta sulla plusvalenza \(Formati.percentuale(i.aliquota)). L'obiettivo è rivalutato all'inflazione fino alla scadenza; il versamento teorico è costante e mensile, senza garanzia di risultato. Il metodo completo è nella scheda «Metodo».")
            }
        }
    }
}

/// Una sezione chiusa all'inizio: il titolo con la freccia, il contenuto a un clic. Le spiegazioni lunghe del
/// risparmio (dove va il denaro, metodo) stanno qui, fuori dalla vista principale.
private struct SezioneApribileRisparmio<Contenuto: View>: View {
    let titolo: String
    @ViewBuilder let contenuto: () -> Contenuto
    @State private var aperta = false

    var body: some View {
        VStack(alignment: .leading, spacing: MR.spazioSezione) {
            Button {
                withAnimation(Tema.Moto.passaggio) { aperta.toggle() }
            } label: {
                HStack(spacing: MR.spazioFreccia) {
                    Image(systemName: "chevron.right")
                        .font(FR.freccia)
                        .rotationEffect(.degrees(aperta ? 90 : 0))
                        .frame(width: MR.freccia)
                    Text(titolo)
                        .font(FR.apri)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(KR.apri)
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
