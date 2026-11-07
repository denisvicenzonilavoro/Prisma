import SwiftUI

// Analisi 360 › Previdenza: la sintesi dell'area. Una cosa grande in alto (il divario al mese, o «coperto»),
// subito sotto le barre che la spiegano (pensione pubblica + integrazione dai piani + divario fino al reddito
// desiderato), poi le tessere per decidere, la proiezione del montante e i piani collegati con il canale.
// La stima contributiva, il fisco dei versamenti e il metodo sono sezioni richiudibili (chiuse all'inizio).
// Vive in un file proprio perché ogni area si possa rifinire senza toccare le altre. Gettoni in
// DesignSystem/TemaAnalisi360Previdenza.swift.

private typealias MP = Tema.Misura.Previdenza360
private typealias KP = Tema.Colore.Previdenza360
private typealias FP = Tema.Testo.Previdenza360

extension AppAnalisi360 {
    func sintesiPrevidenza(_ i: IpotesiPrevidenza) -> some View {
        let e = MotoreAnalisi.previdenza(i)
        let pr = proposte(.previdenza)
        var conProposte = i
        conProposte.capitale += pr.capitale
        conProposte.versamentoMensile += pr.mensile
        let ec: MotoreAnalisi.EsitoPrevidenza? = pr.conteggio > 0 ? MotoreAnalisi.previdenza(conProposte) : nil
        return VStack(alignment: .leading, spacing: MP.spazioBlocchi) {
            testataPrevidenza(i, e)
            barrePrevidenza(i, e, ec, conteggio: pr.conteggio)
            tesserePrevidenza(i, e, ec, conteggio: pr.conteggio)
            rigaStimaPrevidenza(i)
            proiezionePrevidenza(i, e)
            pianiPrevidenza
            apribiliPrevidenza(i)
        }
    }

    /// La pensione pubblica stimata con il contributivo, accanto a quella inserita nelle ipotesi.
    func pensioneStimata(_ i: IpotesiPrevidenza) -> some View {
        let c = stato.cliente(cliente)
        let stima = c.flatMap { MotorePensionePubblica.stima(cliente: $0, previdenza: i) }
        let motivo = c.flatMap { MotorePensionePubblica.motivoAssente($0.profilo.lavoro, reddito: $0.profilo.redditoLordoAnnuo) }
        return PannelloPensioneStimata(stima: stima, motivo: motivo, ipotesi: i) { netta in
            usaPensioneStimata(netta)
        }
    }

    // MARK: - Testata: la cifra principale

    private func usaPensioneStimata(_ netta: Double) {
        var x = analisi.wrappedValue
        x.previdenza.pensionePubblica = netta
        analisi.wrappedValue = x
        stato.mostraAvviso("Pensione pubblica dell'analisi: \(Formati.euro(netta)) al mese, dalla stima contributiva")
    }

    /// L'ipotesi usata al posto di un dato ancora da completare nella scheda del cliente (nil se il dato c'è).
    private func ipotesiStimataPrevidenza(_ voce: String) -> String? {
        stato.completezzaCliente(cliente)?.daCompletare.first { $0.id == voce }?.ipotesi
    }

    private func testataPrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza) -> some View {
        let scoperto = e.divarioResiduo >= 0.5
        let anni = "\(e.anniAccumulo) \(e.anniAccumulo == 1 ? "anno" : "anni")"
        let occhiello = scoperto ? "DIVARIO DA COLMARE, AL MESE" : "REDDITO DESIDERATO, AL MESE"
        let arrivo = i.pensionePubblica + e.integrazione
        let nota = scoperto
            ? "Su \(Formati.euro(i.redditoDesiderato)) desiderati: pensione pubblica \(Formati.euro(i.pensionePubblica)) + piani in essere \(Formati.euro(e.integrazione))"
            : "Pensione pubblica e piani arrivano a \(Formati.euro(arrivo)) su \(Formati.euro(i.redditoDesiderato)) desiderati"
        return VStack(alignment: .leading, spacing: MP.spazioCifra) {
            Text(occhiello)
                .font(FP.occhiello)
                .tracking(MP.tracciatoOcchiello)
                .foregroundColor(KP.occhiello)
            HStack(alignment: .firstTextBaseline, spacing: MP.spazioUnita) {
                Text(scoperto ? Formati.euro(e.divarioResiduo) : "Coperto")
                    .font(FP.cifra)
                    .foregroundColor(scoperto ? KP.cifraDivario : KP.cifraCoperto)
                    .lineLimit(1)
                    .minimumScaleFactor(MP.scalaMinimaCifra)
                if scoperto {
                    Text("al mese")
                        .font(FP.unita)
                        .foregroundColor(KP.nota)
                        .fixedSize()
                }
            }
            Text(nota)
                .font(FP.nota)
                .foregroundColor(KP.nota)
                .fixedSize(horizontal: false, vertical: true)
            Text("Tra \(anni), a \(i.etaPensione) anni · integrazione per \(i.anniIntegrazione) anni, in euro di oggi")
                .font(FP.nota)
                .foregroundColor(KP.nota)
                .fixedSize(horizontal: false, vertical: true)
            stimatePrevidenza
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le ipotesi stimate (dati ancora da completare nella scheda del cliente) restano riconoscibili.
    @ViewBuilder private var stimatePrevidenza: some View {
        let reddito = ipotesiStimataPrevidenza("redditoDesiderato")
        let pensione = ipotesiStimataPrevidenza("pensionePubblica")
        if reddito != nil || pensione != nil {
            let quali: String = {
                if reddito != nil && pensione != nil { return "Reddito desiderato e pensione pubblica sono stimati" }
                return reddito != nil ? "Il reddito desiderato è stimato" : "La pensione pubblica è stimata"
            }()
            HStack(alignment: .center, spacing: MP.spazioPillola) {
                Pillola(testo: TestiCompletezza.stimato, tono: .attenzione)
                Text(quali + ": da verificare con il cliente")
                    .font(FP.nota)
                    .foregroundColor(KP.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, MP.spazioCifra)
            .help([reddito, pensione].compactMap { $0 }.joined(separator: "\n"))
        }
    }

    // MARK: - Barre: pensione pubblica + piani + divario fino al reddito desiderato

    private func segmentiPrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza) -> [BarreImpilate.Segmento] {
        [
            BarreImpilate.Segmento("Pensione pubblica", i.pensionePubblica, colore: KP.pensione, id: "pensione"),
            BarreImpilate.Segmento("Dai piani", e.integrazione, colore: KP.piani, id: "piani"),
            BarreImpilate.Segmento("Divario", e.divarioResiduo, colore: KP.divario, mancante: true, id: "divario"),
        ]
    }

    @ViewBuilder private func barrePrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza,
                                              _ ec: MotoreAnalisi.EsitoPrevidenza?, conteggio: Int) -> some View {
        if let ec {
            BarreImpilate(righe: [
                BarreImpilate.Riga("Oggi", segmenti: segmentiPrevidenza(i, e), id: "oggi"),
                BarreImpilate.Riga(conteggio == 1 ? "Con la proposta" : "Con le proposte",
                                   segmenti: segmentiPrevidenza(i, ec), id: "proposte"),
            ], traguardo: i.redditoDesiderato, etichettaTraguardo: "Reddito desiderato", mostraTotale: false)
        } else {
            BarreImpilate(segmenti: segmentiPrevidenza(i, e), traguardo: i.redditoDesiderato,
                          etichettaTraguardo: "Reddito desiderato", mostraTotale: false)
        }
    }

    // MARK: - Tessere: ciò che serve per decidere

    private func tesserePrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza,
                                   _ ec: MotoreAnalisi.EsitoPrevidenza?, conteggio: Int) -> some View {
        HStack(alignment: .top, spacing: MP.spazioTessere) {
            TesseraCifraAnalisi(titolo: "Montante dei piani alla pensione", valore: Formati.euro(e.montante),
                                nota: "\(Formati.euro(e.integrazione)) al mese per \(i.anniIntegrazione) anni",
                                aiuto: "Montante oggi \(Formati.euro(i.capitale)), versamento \(Formati.euro(i.versamentoMensile)) al mese, rendimento netto reale \(Formati.percentuale(i.rendimentoReale)).")
            TesseraCifraAnalisi(titolo: "Versamento per tutto il divario",
                                valore: e.versamentoTeorico.map { "\(Formati.euro($0))/mese" } ?? "—",
                                nota: e.versamentoTeorico == nil ? "nessun anno di accumulo" : "oggi \(Formati.euro(i.versamentoMensile)) al mese",
                                aiuto: "Il versamento mensile che porterebbe al capitale obiettivo di \(Formati.euro(e.capitaleObiettivo)), contando anche il montante già accumulato.")
            tesseraPropostePrevidenza(i, e, ec, conteggio: conteggio)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func tesseraPropostePrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza,
                                                        _ ec: MotoreAnalisi.EsitoPrevidenza?, conteggio: Int) -> some View {
        if let ec {
            let meno = e.divarioResiduo - ec.divarioResiduo
            TesseraCifraAnalisi(titolo: conteggio == 1 ? "Con la proposta aperta" : "Con le \(conteggio) proposte aperte",
                                valore: "\(Formati.euro(ec.divarioResiduo))/mese",
                                nota: meno >= 0.5 ? "di divario: \(Formati.euro(meno)) in meno" : "di divario",
                                tono: TonoCifraAnalisi.segno(meno),
                                evidenziata: meno >= 0.5,
                                aiuto: "Integrazione dai piani con le proposte: \(Formati.euro(ec.integrazione)) al mese.")
        } else {
            TesseraCifraAnalisi(titolo: "Capitale obiettivo", valore: Formati.euro(e.capitaleObiettivo),
                                nota: "per \(i.anniIntegrazione) anni di integrazione",
                                aiuto: "Il divario con la pensione pubblica (\(Formati.euro(e.divario)) al mese) per tutti i mesi di integrazione.")
        }
    }

    // MARK: - Stima contributiva: una riga, il dettaglio a richiesta

    @ViewBuilder private func rigaStimaPrevidenza(_ i: IpotesiPrevidenza) -> some View {
        let stima = stato.cliente(cliente).flatMap { MotorePensionePubblica.stima(cliente: $0, previdenza: i) }
        if let s = stima {
            let netta = s.nettaMensile.rounded()
            let scarto = netta - i.pensionePubblica
            if abs(scarto) >= 1 {
                HStack(alignment: .center, spacing: MP.spazioStima) {
                    VStack(alignment: .leading, spacing: MP.spazioCifra) {
                        Text("Stima contributiva: \(Formati.euro(netta)) al mese netti, \(Formati.euro(abs(scarto))) \(scarto > 0 ? "in più" : "in meno") di quella inserita")
                            .font(FP.testo)
                            .foregroundColor(KP.testo)
                            .fixedSize(horizontal: false, vertical: true)
                        if !s.avvisi.isEmpty {
                            Label(s.avvisi.count == 1 ? "Un avviso nel dettaglio della stima" : "\(s.avvisi.count) avvisi nel dettaglio della stima",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(FP.notaPiano)
                                .foregroundColor(KP.avviso)
                                .help(s.avvisi.joined(separator: "\n"))
                        }
                    }
                    Spacer(minLength: MP.spazioStima)
                    Button("Usa la stima") { usaPensioneStimata(netta) }
                        .buttonStyle(StileVetro(margine: MP.marginePulsante))
                        .fixedSize()
                        .help("Copia la pensione netta stimata nel campo «Pensione pubblica»: resta modificabile")
                }
                .padding(MP.margineStima)
                .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera))
            }
        }
    }

    // MARK: - Proiezione del montante

    @ViewBuilder private func proiezionePrevidenza(_ i: IpotesiPrevidenza, _ e: MotoreAnalisi.EsitoPrevidenza) -> some View {
        let serie = [GraficoProiezione.Serie(id: "montante", punti: e.punti, colore: KP.piani, principale: true)]
        if i.capitale < 0.5 && i.versamentoMensile < 0.5 {
            GraficoProiezione(serie: serie, vuoto: "Nessun piano in essere: il grafico compare con il primo versamento")
        } else {
            VStack(alignment: .leading, spacing: MP.spazioSezione) {
                Text("Come cresce il montante dei piani, in euro di oggi")
                    .font(FP.etichetta)
                    .foregroundColor(KP.etichetta)
                    .fixedSize(horizontal: false, vertical: true)
                GraficoProiezione(serie: serie, vuoto: "Nessun piano in essere: il grafico compare con il primo versamento")
                HStack(spacing: MP.spazioApribili) {
                    LegendaLinea(colore: KP.piani, testo: "Montante")
                    LegendaLinea(colore: KP.versato, testo: "Versato", tratteggio: true)
                }
            }
        }
    }

    // MARK: - I piani collegati, con il canale

    private var pianiPrevidenza: some View {
        let elenco = contratti(.previdenza)
        return VStack(alignment: .leading, spacing: MP.spazioSezione) {
            HStack(alignment: .firstTextBaseline, spacing: MP.spazioStima) {
                Text(elenco.isEmpty ? "I piani di previdenza" : "I piani di previdenza (\(elenco.count))")
                    .font(FP.titoloSezione)
                    .foregroundColor(KP.titoloSezione)
                Spacer(minLength: MP.spazioStima)
                // Il confronto del TFR futuro, in azienda o nel fondo: lo strumento TFR del rail
                Button {
                    stato.scegliStrumentoAnalisi(.tfr)
                } label: {
                    // La freccia in coda (con Label lo stile la metterebbe davanti)
                    HStack(spacing: Tema.Misura.Componenti.spazioSimboloPulsante) {
                        Text("TFR in azienda o nel fondo?")
                        Image(systemName: "arrow.right")
                            .font(Tema.Testo.Componenti.simboloPulsante)
                    }
                }
                .buttonStyle(StileCollegamento())
                .fixedSize()
            }
            if elenco.isEmpty {
                Text("Nessun piano di previdenza in Posizioni: aggiungilo lì per vederlo qui.")
                    .font(FP.notaPiano)
                    .foregroundColor(KP.notaPiano)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: MP.spazioPiani) {
                    ForEach(elenco) { p in
                        rigaPianoPrevidenza(p)
                    }
                }
            }
        }
    }

    private func rigaPianoPrevidenza(_ p: Posizione) -> some View {
        let proposta = p.stato == .proposta
        let valore = proposta ? p.versamentoIniziale : p.valore
        let premio = p.premioAnnuo / 12
        return Button { stato.apriPosizione(p) } label: {
            HStack(alignment: .center, spacing: MP.spazioPiano) {
                VStack(alignment: .leading, spacing: MP.spazioTestiPiano) {
                    Text(p.nome)
                        .font(FP.nomePiano)
                        .foregroundColor(KP.nomePiano)
                        .fixedSize(horizontal: false, vertical: true)
                    if !p.tipologia.isEmpty {
                        Text(p.tipologia)
                            .font(FP.notaPiano)
                            .foregroundColor(KP.notaPiano)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: MP.spazioPiano)
                if proposta {
                    Pillola(testo: "Proposta", tono: .attenzione)
                }
                EtichettaCanale(canale: p.canale, compatta: true)
                VStack(alignment: .trailing, spacing: MP.spazioTestiPiano) {
                    Text(Formati.euro(valore))
                        .font(FP.cifraPiano)
                        .foregroundColor(KP.nomePiano)
                        .lineLimit(1)
                        .fixedSize()
                    if premio >= 0.5 {
                        Text("\(Formati.euro(premio)) al mese")
                            .font(FP.notaPiano)
                            .foregroundColor(KP.notaPiano)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .frame(minWidth: MP.colonnaCifraPiano, alignment: .trailing)
                Image(systemName: "chevron.right")
                    .font(FP.freccia)
                    .foregroundColor(KP.notaPiano)
            }
            .padding(MP.marginePiano)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera))
        }
        .buttonStyle(StileSemplice())
        .help("Apri la posizione")
    }

    // MARK: - A richiesta: stima, fisco, metodo

    private func apribiliPrevidenza(_ i: IpotesiPrevidenza) -> some View {
        VStack(alignment: .leading, spacing: MP.spazioApribili) {
            SezioneApribilePrevidenza(titolo: "Come è stimata la pensione pubblica") {
                pensioneStimata(i)
            }
            SezioneApribilePrevidenza(titolo: "Quanto si deduce dei versamenti") {
                PannelloFiscoPrevidenza(deducibilita: DeducibilitaPrevidenza(piani: posizioni),
                                        reddito: stato.cliente(cliente)?.profilo.redditoLordoAnnuo)
            }
            SezioneApribilePrevidenza(titolo: "Come si calcola il divario") {
                NotaMetodo(testo: "Il divario usa la pensione pubblica inserita nelle ipotesi; la stima contributiva è un aiuto da verificare sull'estratto conto INPS. L'integrazione è il montante dei piani alla pensione diviso per i mesi di integrazione. Contributi del datore e TFR conferito non entrano in questa proiezione semplificata: li considera il prospetto della previdenza.")
            }
        }
    }
}

/// Una sezione chiusa all'inizio: il titolo con la freccia, il contenuto a un clic. Le spiegazioni lunghe
/// della previdenza (stima contributiva, fisco, metodo) stanno qui, fuori dalla vista principale.
private struct SezioneApribilePrevidenza<Contenuto: View>: View {
    let titolo: String
    @ViewBuilder let contenuto: () -> Contenuto
    @State private var aperta = false

    var body: some View {
        VStack(alignment: .leading, spacing: MP.spazioSezione) {
            Button {
                withAnimation(Tema.Moto.passaggio) { aperta.toggle() }
            } label: {
                HStack(spacing: MP.spazioFreccia) {
                    Image(systemName: "chevron.right")
                        .font(FP.freccia)
                        .rotationEffect(.degrees(aperta ? 90 : 0))
                        .frame(width: MP.freccia)
                    Text(titolo)
                        .font(FP.apri)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(KP.apri)
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
