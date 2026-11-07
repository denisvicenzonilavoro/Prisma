import SwiftUI

// Analisi 360 › Protezione: la sintesi dell'area. In alto la cosa principale grande (lo scoperto se viene a
// mancare chi porta reddito, e quello dell'invalidità del cliente), subito sotto la barra che la spiega
// (fabbisogno, coperto, con le proposte), poi le coperture con il canale, da dove viene il fabbisogno (cascata),
// i rischi del nucleo come caselle colorate, le schede compatte persona per persona. Le spiegazioni lunghe, il
// fisco e il metodo si aprono a richiesta. Vive in un file proprio perché ogni area si possa rifinire senza
// toccare le altre. I calcoli sono quelli dei motori (MotoreAnalisi, MotoreProtezioneFamiglia): qui non cambiano.

private typealias KP = Tema.Colore.Analisi360Protezione
private typealias MP = Tema.Misura.Analisi360Protezione
private typealias FP = Tema.Testo.Analisi360Protezione

extension AppAnalisi360 {
    func sintesiProtezione(_ i: IpotesiProtezione) -> some View {
        let e = MotoreAnalisi.protezione(i, posizioni: posizioni)
        let c = stato.cliente(cliente)
        let f = MotoreProtezioneFamiglia.calcola(posizioni, cliente: c, analisi: i)
        let titolare = f.persone.first { $0.relazione == nil }
        return VStack(alignment: .leading, spacing: MP.spazioSezioni) {
            principaleProtezione(e, titolare: titolare)
            barraProtezione(e, proposte: f.capitaleVitaProposte)
            tessereProtezione(e, i, proposte: f.capitaleVitaProposte)
            copertureProtezione(avvisi: f.avvisi.map(\.testo))
            cascataProtezione(e, i)
            rischiProtezione(f.tutele)
            if !f.persone.isEmpty {
                personeProtezione(f.persone)
            }
            richiudibiliProtezione(c)
        }
    }

    // MARK: La cifra principale

    /// Lo scoperto caso morte del nucleo in grande; accanto, se c'è, lo scoperto dell'invalidità del cliente.
    private func principaleProtezione(_ e: MotoreAnalisi.EsitoProtezione, titolare: FabbisognoPersona?) -> some View {
        let quota = Int((min(e.capitaleVita / max(e.fabbisogno, 1), 1) * 100).rounded(.down))
        let notaMorte: String
        if e.fabbisogno <= 0 {
            notaMorte = "Nessun fabbisogno con queste ipotesi"
        } else if e.divario <= 0 {
            notaMorte = "La famiglia è protetta"
        } else if e.capitaleVita <= 0 {
            notaMorte = "Nessuna copertura caso morte in essere"
        } else {
            notaMorte = "La famiglia è protetta al \(quota)%"
        }
        return HStack(alignment: .top, spacing: MP.spazioCifre) {
            CifraPrincipaleProtezione(occhiello: "SCOPERTO SE VIENE A MANCARE", valore: e.divario, nota: notaMorte)
                .help("Il capitale che mancherebbe alla famiglia se venisse a mancare chi porta reddito: fabbisogno meno le coperture caso morte in essere.")
            if let p = titolare, p.fabbisognoInvalidita > 0 {
                CifraPrincipaleProtezione(occhiello: "SE \(primoNome(p.nome).uppercased()) NON PUÒ PIÙ LAVORARE",
                                          valore: p.divarioInvalidita,
                                          nota: "Reddito da sostituire fino alla pensione")
                    .help("Uno scenario diverso dal caso morte, da non sommare: il reddito che mancherebbe se \(p.nome) non potesse più lavorare, meno le coperture invalidità di cui è l'assicurato.")
            }
            Spacer(minLength: 0)
        }
    }

    private func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    // MARK: Il grafico che la spiega

    private func barraProtezione(_ e: MotoreAnalisi.EsitoProtezione, proposte: Double) -> some View {
        BarraCopertura(fabbisogno: e.fabbisogno, coperto: e.capitaleVita,
                       conProposte: proposte > 0 ? e.capitaleVita + proposte : nil,
                       colore: KP.area,
                       etichettaFabbisogno: "Fabbisogno caso morte",
                       etichettaCoperto: "Coperture caso morte",
                       etichettaProposte: "Con le proposte",
                       etichettaScoperto: "Scoperto")
    }

    /// Le cifre di contorno: la riserva per un'interruzione del reddito, i premi, lo scoperto con le proposte.
    private func tessereProtezione(_ e: MotoreAnalisi.EsitoProtezione, _ i: IpotesiProtezione, proposte: Double) -> some View {
        // Le stesse coperture di cui MotoreAnalisi somma i premi: in essere e non scadute
        let inEssere = contratti(.protezione).filter { $0.stato == .inEssere && !$0.scaduta }.count
        return FasciaKPI {
            TesseraCifraAnalisi(titolo: "Riserva che manca",
                                valore: Formati.euro(e.riservaMancante),
                                nota: "Ne servono \(Formati.euro(e.riservaNecessaria)), ce ne sono \(Formati.euro(i.riserva))",
                                tono: e.riservaMancante >= 1 ? .negativo : .positivo,
                                aiuto: "Se il reddito si interrompe per un periodo (invalidità o malattia lunga): \(Formati.euro(e.ammanco)) al mese × \(i.mesiRiserva) mesi. È uno scenario diverso dal caso morte: non si somma.")
            TesseraCifraAnalisi(titolo: "Premi annui",
                                valore: Formati.euro(e.premiAnnui),
                                nota: inEssere == 1 ? "1 copertura in essere" : "\(inEssere) coperture in essere")
            if proposte > 0 {
                TesseraCifraAnalisi(titolo: "Scoperto con le proposte",
                                    valore: Formati.euro(e.divarioConProposte),
                                    nota: "Se le proposte aperte venissero accettate",
                                    tono: e.divarioConProposte >= 1 ? .attenzione : .positivo,
                                    evidenziata: e.divarioConProposte < 1)
            }
        }
    }

    // MARK: Le coperture con il canale

    @ViewBuilder private func copertureProtezione(avvisi: [String]) -> some View {
        let elenco = contratti(.protezione).sorted { a, b in
            if (a.stato == .inEssere) != (b.stato == .inEssere) { return a.stato == .inEssere }
            return a.nome < b.nome
        }
        PannelloAnalisi(titolo: "Le coperture", nota: nil) { EmptyView() } contenuto: {
            VStack(alignment: .leading, spacing: 0) {
                if elenco.isEmpty {
                    Text("Nessuna copertura in essere o in proposta.")
                        .font(FP.dettaglio)
                        .foregroundColor(KP.dettaglio)
                }
                ForEach(Array(elenco.enumerated()), id: \.element.id) { n, p in
                    RigaCoperturaProtezione(posizione: p, primo: n == 0) { stato.apriPosizione(p) }
                }
                if !avvisi.isEmpty {
                    AvvisiAnalisi(testi: avvisi)
                        .padding(.top, MP.spazioRiga)
                }
            }
        }
    }

    // MARK: Da dove viene il fabbisogno

    private func cascataProtezione(_ e: MotoreAnalisi.EsitoProtezione, _ i: IpotesiProtezione) -> some View {
        PannelloAnalisi(titolo: "Da dove viene il fabbisogno", nota: nil) { EmptyView() } contenuto: {
            Cascata(voci: vociCascata(e, i))
        }
    }

    private func vociCascata(_ e: MotoreAnalisi.EsitoProtezione, _ i: IpotesiProtezione) -> [Cascata.Voce] {
        let sostegno = i.fabbisognoMensile * 12 * Double(i.anniSostegno)
        let anni = i.anniSostegno == 1 ? "1 anno" : "\(i.anniSostegno) anni"
        var voci: [Cascata.Voce] = []
        if i.debiti > 0 {
            voci.append(Cascata.Voce("Debiti da estinguere", i.debiti, tipo: .partenza, id: "debiti"))
            voci.append(Cascata.Voce("Spese immediate", i.speseImmediate, tipo: .aggiunta, id: "spese"))
        } else {
            voci.append(Cascata.Voce("Spese immediate", i.speseImmediate, tipo: .partenza, id: "spese"))
        }
        voci.append(Cascata.Voce("Sostegno: \(Formati.euro(i.fabbisognoMensile))/mese × \(anni)", sostegno,
                                 tipo: .aggiunta, id: "sostegno"))
        if i.capitaleDisponibile > 0 {
            voci.append(Cascata.Voce("Capitale ai superstiti", i.capitaleDisponibile, tipo: .sottrazione, id: "capitale"))
        }
        voci.append(Cascata.Voce("Fabbisogno caso morte", e.fabbisogno, tipo: .totale, id: "fabbisogno"))
        return voci
    }

    // MARK: I rischi del nucleo

    private func rischiProtezione(_ tutele: [TutelaRischio]) -> some View {
        let coperti = tutele.filter { $0.stato == .coperto }.count
        let proposta = tutele.filter { $0.stato == .inProposta }.count
        let scoperti = tutele.filter { $0.stato == .scoperto && $0.importante }.count
        let valutare = tutele.filter { $0.stato == .scoperto && !$0.importante }.count
        var parti: [String] = []
        if coperti > 0 { parti.append("\(coperti) \(coperti == 1 ? "coperto" : "coperti")") }
        if proposta > 0 { parti.append("\(proposta) in proposta") }
        if scoperti > 0 { parti.append("\(scoperti) \(scoperti == 1 ? "scoperto" : "scoperti")") }
        if valutare > 0 { parti.append("\(valutare) da valutare") }
        return PannelloAnalisi(titolo: "I rischi del nucleo", nota: parti.isEmpty ? nil : parti.joined(separator: " · ")) { EmptyView() } contenuto: {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: MP.casellaMinima), spacing: MP.spazioCaselle, alignment: .topLeading)],
                      alignment: .leading, spacing: MP.spazioCaselle) {
                ForEach(tutele) { t in
                    CasellaRischioProtezione(tutela: t)
                }
            }
        }
    }

    // MARK: Persona per persona

    private func personeProtezione(_ persone: [FabbisognoPersona]) -> some View {
        PannelloAnalisi(titolo: "Persona per persona",
                        nota: "Tre scenari distinti per chi porta reddito: non si sommano") { EmptyView() } contenuto: {
            VStack(alignment: .leading, spacing: MP.spazioPersone) {
                ForEach(persone) { p in
                    SchedaPersonaCompattaProtezione(persona: p)
                }
            }
        }
    }

    // MARK: Fisco e metodo, a richiesta

    private func richiudibiliProtezione(_ c: Cliente?) -> some View {
        VStack(alignment: .leading, spacing: MP.spazioRiga) {
            if let c {
                ApribileProtezione(titolo: "Il fisco delle coperture") {
                    PannelloFiscoCoperture(fisco: CacheMotoriAnalisi.fisco(cliente: c, posizioni: posizioni))
                }
            }
            ApribileProtezione(titolo: "Come è calcolato") {
                NotaMetodo(testo: MotoreAnalisi.metodo(.protezione))
            }
        }
    }
}

// MARK: - Pezzi della sintesi

/// Una cifra principale: occhiello in maiuscolo, cifra grande rossa se manca qualcosa (verde se no), nota breve.
private struct CifraPrincipaleProtezione: View {
    let occhiello: String
    let valore: Double
    let nota: String

    var body: some View {
        let tono: TonoCifraAnalisi = valore >= 1 ? .negativo : .positivo
        VStack(alignment: .leading, spacing: MP.spazioCifra) {
            Text(occhiello)
                .font(FP.occhiello)
                .tracking(FP.tracciatoOcchiello)
                .foregroundColor(KP.occhiello)
                .fixedSize(horizontal: false, vertical: true)
            Text(Formati.euro(valore))
                .font(FP.cifra)
                .foregroundColor(tono.colore)
                .lineLimit(1)
                .minimumScaleFactor(MP.scalaMinimaCifra)
            Text(nota)
                .font(FP.nota)
                .foregroundColor(KP.nota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Una copertura: simbolo dell'area, nome, rischio e capitale, «Proposta», etichetta del canale. Un clic la apre.
private struct RigaCoperturaProtezione: View {
    let posizione: Posizione
    let primo: Bool
    let apri: () -> Void

    var body: some View {
        Button(action: apri) {
            contenuto
                .padding(MP.rigaCopertura)
                .overlay(alignment: .top) {
                    if !primo {
                        Rectangle().fill(KP.filo).frame(height: Tema.Misura.filo)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .help("Apri la posizione")
    }

    private var contenuto: some View {
        let p = posizione
        let capitale = MotoreProtezioneFamiglia.capitaleAttuale(p, al: Date())
        var dettaglio = p.rischio?.nome ?? "Rischio non indicato"
        if capitale > 0 { dettaglio += " · \(Formati.euro(capitale))" }
        if p.premioAnnuo > 0 { dettaglio += " · \(Formati.euro(p.premioAnnuo)) l'anno" }
        return HStack(alignment: .center, spacing: MP.spazioRiga) {
            Image(systemName: "shield.fill")
                .foregroundColor(KP.area)
                .frame(width: MP.simbolo)
            VStack(alignment: .leading, spacing: MP.spazioTesti) {
                Text(p.nome)
                    .font(FP.nome)
                    .foregroundColor(KP.nome)
                    .fixedSize(horizontal: false, vertical: true)
                Text(dettaglio)
                    .font(FP.dettaglio)
                    .foregroundColor(KP.dettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: MP.spazioRiga)
            if p.stato == .proposta {
                Pillola(testo: "Proposta", tono: .attenzione)
            }
            EtichettaCanale(canale: p.canale)
        }
    }
}

/// Un rischio del nucleo: simbolo e nome su una casella del colore dello stato. Il perché sta nell'aiuto.
private struct CasellaRischioProtezione: View {
    let tutela: TutelaRischio

    private enum Aspetto { case coperto, proposta, scoperto, valutare }

    private var aspetto: Aspetto {
        switch tutela.stato {
        case .coperto: return .coperto
        case .inProposta: return .proposta
        case .scoperto: return tutela.importante ? .scoperto : .valutare
        }
    }

    private var simbolo: String {
        switch aspetto {
        case .coperto: return "checkmark.circle.fill"
        case .proposta: return "clock.fill"
        case .scoperto: return "exclamationmark.circle.fill"
        case .valutare: return "questionmark.circle"
        }
    }

    private var testo: Color {
        switch aspetto {
        case .coperto: return KP.copertoTesto
        case .proposta: return KP.propostaTesto
        case .scoperto: return KP.scopertoTesto
        case .valutare: return KP.valutareTesto
        }
    }

    private var fondo: Color {
        switch aspetto {
        case .coperto: return KP.copertoFondo
        case .proposta: return KP.propostaFondo
        case .scoperto: return KP.scopertoFondo
        case .valutare: return KP.valutareFondo
        }
    }

    private var bordo: Color {
        switch aspetto {
        case .coperto: return KP.copertoBordo
        case .proposta, .scoperto: return testo.opacity(KP.opacitaBordo)
        case .valutare: return KP.valutareBordo
        }
    }

    private var aiuto: String {
        let t = tutela
        var parti: [String]
        switch aspetto {
        case .coperto:
            parti = ["Coperto" + (t.capitale > 0 ? ": \(Formati.euro(t.capitale)) assicurati" : "")]
        case .proposta:
            parti = ["In proposta" + (t.capitaleProposte > 0 ? ": \(Formati.euro(t.capitaleProposte))" : "")]
        case .scoperto:
            parti = ["Scoperto: per questa famiglia è una tutela da avere"]
        case .valutare:
            parti = ["Scoperto, da valutare con il cliente"]
        }
        if !t.perche.isEmpty { parti.append(t.perche) }
        return parti.joined(separator: ". ")
    }

    var body: some View {
        let forma = FormaVetro.arrotondata(MP.raggioCasella)
        HStack(alignment: .firstTextBaseline, spacing: MP.spazioSimbolo) {
            Image(systemName: simbolo)
                .font(FP.simboloCasella)
            Text(tutela.rischio.nome)
                .font(FP.casella)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundColor(testo)
        .padding(MP.margineCasella)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { forma.fill(fondo) }
        .overlay { forma.strokeBorder(bordo, lineWidth: Tema.Misura.filo) }
        .help(aiuto)
        .accessibilityElement(children: .combine)
    }
}

/// Una persona che porta reddito: intestazione, tre tessere con lo scoperto (morte, invalidità, non
/// autosufficienza), gli avvisi, e il «come si leggono le cifre» a richiesta.
private struct SchedaPersonaCompattaProtezione: View {
    let persona: FabbisognoPersona

    var body: some View {
        VStack(alignment: .leading, spacing: MP.spazioPersona) {
            intestazione
            FasciaKPI {
                tessera("Se viene a mancare", serve: persona.fabbisognoMorte, coperto: persona.capitaleMorte,
                        scoperto: persona.divarioMorte, proposte: persona.capitaleMorteProposte,
                        conProposte: persona.divarioMorteConProposte)
                tessera("Se non può più lavorare", serve: persona.fabbisognoInvalidita, coperto: persona.capitaleInvalidita,
                        scoperto: persona.divarioInvalidita, proposte: persona.capitaleInvaliditaProposte,
                        conProposte: persona.divarioInvaliditaConProposte)
                tessera("Se non è più autosufficiente", serve: persona.fabbisognoLTC, coperto: persona.capitaleLTC,
                        scoperto: persona.divarioLTC, proposte: persona.capitaleLTCProposte,
                        conProposte: persona.divarioLTCConProposte)
            }
            if !persona.avvisi.isEmpty {
                AvvisiAnalisi(testi: persona.avvisi)
            }
            IpotesiApribili(titolo: "Come si leggono le cifre", righe: comeSiLegge)
        }
    }

    private var intestazione: some View {
        let p = persona
        var parti: [String] = [p.relazione?.nome ?? "Cliente"]
        if let eta = p.eta { parti.append("\(eta) anni") }
        parti.append("\(Formati.euro(p.redditoNetto)) netti l'anno" + (p.redditoStimato ? " (stimati)" : ""))
        return HStack(alignment: .firstTextBaseline, spacing: MP.spazioRiga) {
            Text(p.nome)
                .font(FP.persona)
                .foregroundColor(KP.persona)
                .fixedSize()
            Text(parti.joined(separator: " · "))
                .font(FP.personaDettaglio)
                .foregroundColor(KP.personaDettaglio)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: MP.spazioRiga)
            Pillola(testo: "\(Formati.percentuale((p.quotaReddito * 100).rounded())) del reddito", tono: .neutro)
                .fixedSize()
                .help("Quota del reddito di famiglia che porta \(p.nome)")
        }
    }

    private func tessera(_ titolo: String, serve: Double, coperto: Double, scoperto: Double,
                         proposte: Double, conProposte: Double) -> some View {
        var nota = "Serve \(Formati.euro(serve)) · coperto \(Formati.euro(coperto))"
        if proposte > 0 { nota += " · con le proposte \(Formati.euro(conProposte))" }
        return TesseraCifraAnalisi(titolo: titolo,
                                   valore: scoperto >= 1 ? Formati.euro(scoperto) : "Coperto",
                                   nota: nota,
                                   tono: scoperto >= 1 ? .negativo : .positivo,
                                   aiuto: scoperto >= 1 ? "Quanto mancherebbe alla famiglia in questo caso" : nil)
    }

    /// Da dove vengono le cifre di «Serve», con chi dipende dalla persona (lo stesso testo di prima, a richiesta).
    private var comeSiLegge: [String] {
        let p = persona
        let assistenza = IpotesiPersona()
        var righe: [String] = [
            "Viene a mancare: debiti a suo carico \(Formati.euro(p.debiti)) + spese immediate \(Formati.euro(p.speseImmediate)) + sostegno \(Formati.euro(p.sostegnoAnnuo)) l'anno per \(p.anniSostegno) \(p.anniSostegno == 1 ? "anno" : "anni") − capitale già disponibile \(Formati.euro(p.capitaleDisponibile)).",
            "Non può più lavorare: \(Formati.euro(max(0, p.redditoNetto - p.entrateSostitutive))) l'anno da sostituire per \(p.anniAllaPensione) \(p.anniAllaPensione == 1 ? "anno" : "anni"), fino alla pensione.",
            "Non autosufficienza: assistenza di \(Formati.euro(assistenza.spesaAssistenzaMensile)) al mese per \(assistenza.anniAssistenza) anni (ipotesi prudente).",
            "Contano solo le coperture di cui \(p.nome) è l'assicurato. I tre casi non si sommano tra loro né con il totale del nucleo.",
        ]
        if p.capitaleInfortuni > 0 {
            righe.append("Infortuni: \(Formati.euro(p.capitaleInfortuni)) assicurati, pagano solo se l'invalidità viene da un infortunio (non contati sopra).")
        }
        if !p.dipendenti.isEmpty {
            let elenco = p.dipendenti.map { d -> String in
                let eta = d.eta.map { " (\($0) anni)" } ?? ""
                let durata = d.aVita ? "per tutta la vita" : "per \(d.anni) \(d.anni == 1 ? "anno" : "anni")"
                return "\(d.nome)\(eta), \(durata)"
            }
            righe.append("Dipendono da \(p.nome): " + elenco.joined(separator: "; ") + ".")
        }
        if p.redditoStimato {
            righe.append("Il reddito è stimato dal fabbisogno: indicalo nel profilo.")
        }
        return righe
    }
}

/// Una parte che si apre a richiesta (fisco, metodo): freccia e titolo, il contenuto solo da aperta.
private struct ApribileProtezione<Contenuto: View>: View {
    let titolo: String
    @ViewBuilder let contenuto: () -> Contenuto
    @State private var aperta = false

    var body: some View {
        VStack(alignment: .leading, spacing: MP.spazioRiga) {
            Button {
                withAnimation(Tema.Moto.passaggio) { aperta.toggle() }
            } label: {
                HStack(spacing: MP.spazioApri) {
                    Image(systemName: aperta ? "chevron.down" : "chevron.right")
                        .font(FP.freccia)
                    Text(titolo)
                        .font(FP.apri)
                }
                .foregroundColor(KP.apri)
                .contentShape(Rectangle().inset(by: -Tema.Misura.Componenti.allargamentoClic))
            }
            .buttonStyle(.plain)
            .help(aperta ? "Nascondi" : "Mostra")
            if aperta {
                contenuto()
            }
        }
    }
}
